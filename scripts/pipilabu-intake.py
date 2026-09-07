#!/usr/bin/env python3
"""Capture authenticated Pipi Labu requests into a private local ledger.

This is deliberately an intake boundary, not an execution dispatcher.  An
upstream adapter (Gmail or Buzz) must provide a small authenticated envelope.
Accepted bodies are stored privately under ``.local/intake/requests`` and the
append-only ledger contains metadata only.  Nothing in this module replies,
starts Codex, mutates Studio, or chooses a workspace from message content.
"""

from __future__ import annotations

import argparse
import contextlib
import hashlib
import json
import os
from pathlib import Path
import re
import tempfile
import unicodedata
from typing import Any


SCHEMA_VERSION = 1
PROJECT = "pipilabu"
MAX_BODY_CHARS = 12_000
REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_STATE_ROOT = REPO_ROOT / ".local" / "intake"

ALLOWED_EMAIL_SENDERS = {"jawn.walworth@gmail.com": "Jon Walworth"}
ALLOWED_EMAIL_RECIPIENTS = {"leo@buffalowebproducts.com"}

# Public identity, not a credential.  Jon's Buzz key is intentionally absent
# until it is verified against his live Buzz profile by an operator.
ALLOWED_BUZZ_AUTHORS = {
    "a58527c51af44f3454658967667004ff96491531e5c762634677db3314ed729b": "Leo Duarte",
}

PREFIX_RE = re.compile(r"^\s*(?:@codex\s*[:,;-]?\s*)?\[PIPILABU\]\s*", re.IGNORECASE)
BUZZ_SAFE_PREFIX_RE = re.compile(r"^\s*\[PIPILABU\]\s*", re.IGNORECASE)
FORWARDED_RE = re.compile(r"(^|\n)\s*(?:-{2,}\s*)?(?:forwarded message|begin forwarded message)\b", re.IGNORECASE)
CREDENTIAL_RE = re.compile(
    r"(?:-----BEGIN [A-Z ]+PRIVATE KEY-----|\b(?:password|passwd|secret|token|api[_ -]?key|private[_ -]?key)\s*[:=]\s*\S+|\b(?:sk|rk)-[A-Za-z0-9_-]{12,}\b)",
    re.IGNORECASE,
)


def _canonical_text(value: Any) -> str:
    text = unicodedata.normalize("NFKC", str(value or ""))
    text = text.replace("\u200b", "").replace("\ufeff", "")
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    return text


def normalize_request(value: Any) -> str:
    text = PREFIX_RE.sub("", _canonical_text(value), count=1)
    return " ".join(text.split()).casefold()


def sha256_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def _email_address(value: Any) -> str:
    text = str(value or "").strip().casefold()
    match = re.search(r"<([^<>]+)>", text)
    return (match.group(1) if match else text).strip()


def _nonempty_string(envelope: dict[str, Any], key: str) -> str:
    value = envelope.get(key)
    return value.strip() if isinstance(value, str) else ""


def validate_envelope(envelope: dict[str, Any]) -> tuple[list[str], dict[str, str]]:
    reasons: list[str] = []
    source = _nonempty_string(envelope, "source").casefold()
    source_id = _nonempty_string(envelope, "sourceId")
    project = _nonempty_string(envelope, "project").casefold()
    body = _canonical_text(envelope.get("body"))
    subject = _canonical_text(envelope.get("subject")).strip()

    if envelope.get("schemaVersion") != SCHEMA_VERSION:
        reasons.append("invalid_schema")
    if source not in {"gmail", "buzz"}:
        reasons.append("unknown_source")
    if not source_id or len(source_id) > 512:
        reasons.append("invalid_source_id")
    if project != PROJECT:
        reasons.append("unknown_project")
    if not body.strip():
        reasons.append("empty_body")
    if len(body) > MAX_BODY_CHARS:
        reasons.append("body_too_large")
    if bool(envelope.get("hasAttachments")):
        reasons.append("attachments_quarantined")
    if bool(envelope.get("forwarded")) or FORWARDED_RE.search(body):
        reasons.append("forwarded_content_quarantined")
    if CREDENTIAL_RE.search(body):
        reasons.append("credential_like_content")

    identity = ""
    actor = ""
    if source == "gmail":
        sender = _email_address(envelope.get("sender"))
        recipient = _email_address(envelope.get("recipient"))
        auth = envelope.get("authentication") if isinstance(envelope.get("authentication"), dict) else {}
        if sender not in ALLOWED_EMAIL_SENDERS:
            reasons.append("sender_not_allowed")
        if recipient not in ALLOWED_EMAIL_RECIPIENTS:
            reasons.append("recipient_not_allowed")
        if not subject.upper().startswith("[PIPILABU]"):
            reasons.append("subject_prefix_missing")
        if any(str(auth.get(key, "")).casefold() != "pass" for key in ("spf", "dkim", "dmarc")):
            reasons.append("email_authentication_failed")
        if str(envelope.get("contentType") or "").split(";", 1)[0].strip().casefold() != "text/plain":
            reasons.append("plain_text_required")
        identity = sender
        actor = ALLOWED_EMAIL_SENDERS.get(sender, "unknown")
    elif source == "buzz":
        author_key = _nonempty_string(envelope, "authorPublicKey").casefold()
        if author_key not in ALLOWED_BUZZ_AUTHORS:
            reasons.append("buzz_author_not_allowed")
        if envelope.get("signatureVerified") is not True:
            reasons.append("buzz_signature_unverified")
        if envelope.get("directMention") is not True:
            reasons.append("direct_mention_required")
        if not BUZZ_SAFE_PREFIX_RE.match(body):
            reasons.append("body_prefix_missing")
        if re.match(r"^\s*@codex\b", body, re.IGNORECASE):
            reasons.append("shared_dispatch_conflict")
        identity = author_key
        actor = ALLOWED_BUZZ_AUTHORS.get(author_key, "unknown")

    return sorted(set(reasons)), {
        "source": source,
        "source_id": source_id,
        "identity": identity,
        "actor": actor,
        "subject": subject,
        "body": body,
    }


def _read_json(path: Path, fallback: dict[str, Any]) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return dict(fallback)
    return value if isinstance(value, dict) else dict(fallback)


def _write_json_atomic(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    os.chmod(path.parent, 0o700)
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(value, handle, indent=2, sort_keys=True)
            handle.write("\n")
        os.chmod(temporary, 0o600)
        os.replace(temporary, path)
        os.chmod(path, 0o600)
    finally:
        with contextlib.suppress(FileNotFoundError):
            os.unlink(temporary)


def _append_private_jsonl(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    os.chmod(path.parent, 0o700)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(value, separators=(",", ":"), sort_keys=True) + "\n")
    os.chmod(path, 0o600)


def capture(envelope: dict[str, Any], state_root: Path = DEFAULT_STATE_ROOT) -> dict[str, Any]:
    state_root = state_root.resolve()
    state_root.mkdir(parents=True, exist_ok=True, mode=0o700)
    os.chmod(state_root, 0o700)
    state_path = state_root / "state.json"
    ledger_path = state_root / "ledger.jsonl"
    request_root = state_root / "requests"
    quarantine_root = state_root / "quarantine"

    state = _read_json(state_path, {
        "schema_version": SCHEMA_VERSION,
        "events": {},
        "fingerprints": {},
    })
    if state.get("schema_version") != SCHEMA_VERSION:
        raise RuntimeError("unsupported intake state schema")
    state.setdefault("events", {})
    state.setdefault("fingerprints", {})

    reasons, fields = validate_envelope(envelope)
    event_key = f"{fields['source']}:{fields['source_id']}"
    if event_key in state["events"]:
        previous = state["events"][event_key]
        return {"status": "already_recorded", "event_key": event_key, "record": previous}

    normalized = normalize_request(fields["body"])
    fingerprint = sha256_text(f"{fields['identity']}\n{PROJECT}\n{normalized}")
    body_hash = sha256_text(fields["body"])
    duplicate_of = state["fingerprints"].get(fingerprint)
    status = "quarantined" if reasons else ("duplicate" if duplicate_of else "captured")

    body_path: Path | None = None
    if status == "captured":
        request_root.mkdir(parents=True, exist_ok=True, mode=0o700)
        os.chmod(request_root, 0o700)
        body_path = request_root / f"{fingerprint}.txt"
        if not body_path.exists():
            body_path.write_text(fields["body"].strip() + "\n", encoding="utf-8")
            os.chmod(body_path, 0o600)
    elif status == "quarantined":
        quarantine_root.mkdir(parents=True, exist_ok=True, mode=0o700)
        os.chmod(quarantine_root, 0o700)
        # Quarantine metadata only. Credential-like or forwarded content never
        # gets copied from the transport envelope into local persistent state.
        body_path = quarantine_root / f"{sha256_text(event_key)}.json"
        _write_json_atomic(body_path, {
            "schema_version": SCHEMA_VERSION,
            "event_key": event_key,
            "source": fields["source"],
            "body_sha256": body_hash,
            "reasons": reasons,
        })

    record = {
        "schema_version": SCHEMA_VERSION,
        "event_key": event_key,
        "status": status,
        "source": fields["source"],
        "source_id_sha256": sha256_text(fields["source_id"]),
        "actor": fields["actor"],
        "project": PROJECT,
        "subject": fields["subject"][:240],
        "fingerprint": fingerprint,
        "body_sha256": body_hash,
        "body_chars": len(fields["body"]),
        "duplicate_of": duplicate_of,
        "reasons": reasons,
        "request_path": str(body_path.relative_to(state_root)) if body_path else None,
        "execution_authorized": False,
        "external_reply_authorized": False,
    }
    state["events"][event_key] = record
    if status == "captured":
        state["fingerprints"][fingerprint] = event_key
    _write_json_atomic(state_path, state)
    _append_private_jsonl(ledger_path, record)
    return {"status": status, "event_key": event_key, "record": record}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", default="-", help="authenticated JSON envelope or '-' for stdin")
    parser.add_argument("--state-root", type=Path, default=DEFAULT_STATE_ROOT)
    args = parser.parse_args()
    raw = __import__("sys").stdin.read() if args.input == "-" else Path(args.input).read_text(encoding="utf-8")
    envelope = json.loads(raw)
    if not isinstance(envelope, dict):
        raise SystemExit("input must be one JSON object")
    print(json.dumps(capture(envelope, args.state_root), separators=(",", ":"), sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
