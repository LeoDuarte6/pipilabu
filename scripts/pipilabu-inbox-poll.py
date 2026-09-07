#!/usr/bin/env python3
"""Read-only Gmail + Buzz adapter for the Pipi Labu capture ledger.

Designed for bison-1. Credentials are resolved by name through the existing
encrypted-vault helper and are never logged or inherited by child agents.
This adapter captures requests only; it does not acknowledge, reply, or start
an agent.
"""

from __future__ import annotations

import argparse
import base64
from email.utils import getaddresses
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
from typing import Any
import urllib.error
import urllib.parse
import urllib.request


SCRIPT_DIR = Path(__file__).resolve().parent
CORE_PATH = Path(os.getenv("PIPILABU_INTAKE_CORE", SCRIPT_DIR / "pipilabu-intake.py"))
STATE_ROOT = Path(os.getenv("PIPILABU_INTAKE_STATE", Path.home() / ".hermes" / "pipilabu-intake"))
BUZZ_INBOX = Path(os.getenv("PIPILABU_BUZZ_INBOX", "/home/leo/data/techandbusiness/buzz-inbox/codex.json"))
SECRET_HELPER = os.getenv("PIPILABU_SECRET_HELPER", "/home/leo/bin/chief-secret-get")
GMAIL_QUERY = 'from:jawn.walworth@gmail.com subject:[PIPILABU] -in:spam -in:trash'
CODEX_PUBLIC_KEY = "32e12099cb0db0050fdd951a39288f543e10435894f9f996ea561b7779efa538"
PIPI_PREFIX_RE = re.compile(r"^\s*\[PIPILABU\]", re.IGNORECASE)
CODEX_MENTION_RE = re.compile(r"(?:^|[\s([<{])@codex\b", re.IGNORECASE)


def load_core():
    spec = importlib.util.spec_from_file_location("pipilabu_intake", CORE_PATH)
    if not spec or not spec.loader:
        raise RuntimeError("intake_core_unavailable")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def secret(name: str) -> str:
    result = subprocess.run(
        [SECRET_HELPER, name],
        check=False,
        capture_output=True,
        text=True,
        timeout=20,
        env={"PATH": "/usr/local/bin:/usr/bin:/bin", "HOME": str(Path.home())},
    )
    if result.returncode != 0 or not result.stdout:
        raise RuntimeError(f"secret_unavailable:{name}")
    return result.stdout


def gmail_access_token() -> str:
    fields = {
        "client_id": secret("HERMES_GOOGLE_CLIENT_ID"),
        "client_secret": secret("HERMES_GOOGLE_CLIENT_SECRET"),
        "refresh_token": secret("HERMES_GOOGLE_REFRESH_TOKEN"),
        "grant_type": "refresh_token",
    }
    request = urllib.request.Request(
        "https://oauth2.googleapis.com/token",
        data=urllib.parse.urlencode(fields).encode("ascii"),
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            payload = json.loads(response.read())
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
        raise RuntimeError("gmail_token_refresh_failed") from exc
    token = payload.get("access_token")
    if not isinstance(token, str) or not token:
        raise RuntimeError("gmail_token_missing")
    return token


def gmail_get(path: str, token: str, params: dict[str, Any] | None = None) -> dict[str, Any]:
    query = urllib.parse.urlencode(params or {}, doseq=True)
    url = f"https://gmail.googleapis.com/gmail/v1/users/me/{path}"
    if query:
        url = f"{url}?{query}"
    request = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            value = json.loads(response.read())
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
        raise RuntimeError("gmail_api_failed") from exc
    return value if isinstance(value, dict) else {}


def decode_part(data: Any) -> str:
    if not isinstance(data, str) or not data:
        return ""
    padding = "=" * (-len(data) % 4)
    try:
        return base64.urlsafe_b64decode(data + padding).decode("utf-8", errors="replace")
    except (ValueError, UnicodeError):
        return ""


def message_content(payload: dict[str, Any]) -> tuple[str, str, bool]:
    plain: list[str] = []
    html: list[str] = []
    attachments = False

    def walk(part: dict[str, Any]) -> None:
        nonlocal attachments
        filename = str(part.get("filename") or "")
        body = part.get("body") if isinstance(part.get("body"), dict) else {}
        if filename or body.get("attachmentId"):
            attachments = True
        mime = str(part.get("mimeType") or "").casefold()
        decoded = decode_part(body.get("data"))
        if mime == "text/plain" and decoded:
            plain.append(decoded)
        elif mime == "text/html" and decoded:
            html.append(decoded)
        for child in part.get("parts") or []:
            if isinstance(child, dict):
                walk(child)

    walk(payload)
    if plain:
        return "\n".join(plain), "text/plain", attachments
    return "\n".join(html), "text/html", attachments


def headers_map(payload: dict[str, Any]) -> dict[str, list[str]]:
    result: dict[str, list[str]] = {}
    for header in payload.get("headers") or []:
        if not isinstance(header, dict):
            continue
        name = str(header.get("name") or "").casefold()
        if name:
            result.setdefault(name, []).append(str(header.get("value") or ""))
    return result


def auth_result(headers: dict[str, list[str]], mechanism: str) -> str:
    combined = "\n".join(headers.get("authentication-results", []) + headers.get("arc-authentication-results", []))
    return "pass" if re.search(rf"\b{re.escape(mechanism)}\s*=\s*pass\b", combined, re.IGNORECASE) else "fail"


def poll_gmail(core) -> list[dict[str, Any]]:
    token = gmail_access_token()
    listing = gmail_get("messages", token, {"q": GMAIL_QUERY, "maxResults": 50})
    outcomes: list[dict[str, Any]] = []
    for metadata in listing.get("messages") or []:
        message_id = str(metadata.get("id") or "")
        if not message_id:
            continue
        message = gmail_get(f"messages/{urllib.parse.quote(message_id)}", token, {"format": "full"})
        payload = message.get("payload") if isinstance(message.get("payload"), dict) else {}
        headers = headers_map(payload)
        body, content_type, has_attachments = message_content(payload)
        recipients = [address.casefold() for _, address in getaddresses(headers.get("to", []))]
        recipient = "leo@buffalowebproducts.com" if "leo@buffalowebproducts.com" in recipients else (recipients[0] if recipients else "")
        outcome = core.capture({
            "schemaVersion": 1,
            "source": "gmail",
            "sourceId": message_id,
            "project": "pipilabu",
            "sender": (headers.get("from") or [""])[0],
            "recipient": recipient,
            "subject": (headers.get("subject") or [""])[0],
            "authentication": {
                "spf": auth_result(headers, "spf"),
                "dkim": auth_result(headers, "dkim"),
                "dmarc": auth_result(headers, "dmarc"),
            },
            "contentType": content_type,
            "hasAttachments": has_attachments,
            "forwarded": False,
            "body": body,
        }, STATE_ROOT)
        outcomes.append({"source": "gmail", "status": outcome["status"]})
    return outcomes


def is_direct_codex_event(event: dict[str, Any]) -> bool:
    tags = event.get("tags") if isinstance(event.get("tags"), list) else []
    tagged = any(
        isinstance(tag, list) and len(tag) >= 2 and tag[0] == "p" and tag[1] == CODEX_PUBLIC_KEY
        for tag in tags
    )
    return tagged or bool(CODEX_MENTION_RE.search(str(event.get("content") or "")))


def poll_buzz(core) -> list[dict[str, Any]]:
    try:
        inbox = json.loads(BUZZ_INBOX.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError, OSError) as exc:
        raise RuntimeError("buzz_inbox_unavailable") from exc
    outcomes: list[dict[str, Any]] = []
    seen: set[str] = set()
    for bucket in ("attention", "unread"):
        for event in inbox.get(bucket) or []:
            if not isinstance(event, dict):
                continue
            event_id = str(event.get("id") or "")
            body = str(event.get("content") or "")
            if not event_id or event_id in seen or not PIPI_PREFIX_RE.match(body):
                continue
            seen.add(event_id)
            outcome = core.capture({
                "schemaVersion": 1,
                "source": "buzz",
                "sourceId": event_id,
                "project": "pipilabu",
                "authorPublicKey": str(event.get("author_pubkey") or event.get("pubkey") or ""),
                # The upstream Buzz CLI/poller is the signed-event boundary.
                "signatureVerified": True,
                # The exact project prefix is the Pipi-specific direct route.
                # Deliberately do not require @Codex: that mention belongs to
                # the existing T&B dispatcher and would create a cross-repo
                # execution conflict.
                "directMention": True,
                "hasAttachments": False,
                "forwarded": False,
                "body": body,
            }, STATE_ROOT)
            outcomes.append({"source": "buzz", "status": outcome["status"]})
    return outcomes


def write_health(value: dict[str, Any]) -> None:
    STATE_ROOT.mkdir(parents=True, exist_ok=True, mode=0o700)
    os.chmod(STATE_ROOT, 0o700)
    path = STATE_ROOT / "poll-health.json"
    fd, temporary = tempfile.mkstemp(prefix=".poll-health.", dir=STATE_ROOT)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(value, handle, indent=2, sort_keys=True)
            handle.write("\n")
        os.chmod(temporary, 0o600)
        os.replace(temporary, path)
        os.chmod(path, 0o600)
    finally:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", choices=("all", "gmail", "buzz"), default="all")
    args = parser.parse_args()
    core = load_core()
    outcomes: list[dict[str, Any]] = []
    errors: list[str] = []
    if args.source in {"all", "gmail"}:
        try:
            outcomes.extend(poll_gmail(core))
        except Exception as exc:  # the health record is intentionally sanitized
            errors.append(str(exc) if str(exc).startswith(("gmail_", "secret_")) else type(exc).__name__)
    if args.source in {"all", "buzz"}:
        try:
            outcomes.extend(poll_buzz(core))
        except Exception as exc:
            errors.append(str(exc) if str(exc).startswith("buzz_") else type(exc).__name__)
    counts: dict[str, int] = {}
    for outcome in outcomes:
        key = f"{outcome['source']}:{outcome['status']}"
        counts[key] = counts.get(key, 0) + 1
    health = {"schema_version": 1, "status": "healthy" if not errors else "degraded", "counts": counts, "errors": errors}
    write_health(health)
    print(json.dumps(health, separators=(",", ":"), sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
