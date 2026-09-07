#!/usr/bin/env python3
"""Deliver new Pipi Labu review visuals to Jon as a deduplicated Gmail digest.

The canonical visual manifest lives on the Windows Pipi Labu checkout. This
sender is designed to run on bison-1: it refreshes that manifest over the
private SSH lane, copies only exact content-addressed attachments, sends via
the encrypted-vault-backed company Gmail identity, and acknowledges only
hashes Gmail accepted. An interrupted send is quarantined as uncertain rather
than retried, preventing duplicate mail after ambiguous failures.
"""

from __future__ import annotations

import argparse
import base64
import datetime as dt
from email.message import EmailMessage
from email.policy import SMTP
import hashlib
import json
import mimetypes
import os
from pathlib import Path, PurePosixPath
import subprocess
import tempfile
from typing import Any
import urllib.error
import urllib.parse
import urllib.request
from zoneinfo import ZoneInfo


RECIPIENT = "jawn.walworth@gmail.com"
SENDER = "leo@buffalowebproducts.com"
WINDOWS_HOST = os.getenv("PIPILABU_VISUAL_WINDOWS_HOST", "bison-desktop")
WINDOWS_REPO = os.getenv(
    "PIPILABU_VISUAL_WINDOWS_REPO",
    "C:/Users/fricc/Documents/Codex/2026-08-07/pipilabu",
)
STATE_ROOT = Path(
    os.getenv("PIPILABU_VISUAL_STATE", Path.home() / ".hermes" / "pipilabu-visual-digest")
)
SECRET_HELPER = os.getenv("PIPILABU_SECRET_HELPER", "/home/leo/bin/chief-secret-get")
LOCAL_TIMEZONE = ZoneInfo("America/New_York")
MAX_PACKET_BYTES = 17 * 1024 * 1024
MAX_PACKET_ATTACHMENTS = 16


class DigestError(RuntimeError):
    pass


def now_utc() -> dt.datetime:
    return dt.datetime.now(dt.timezone.utc)


def read_json(path: Path, default: dict[str, Any]) -> dict[str, Any]:
    if not path.exists():
        return default
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise DigestError("digest_state_invalid") from exc
    if not isinstance(value, dict):
        raise DigestError("digest_state_invalid")
    return value


def write_json(path: Path, value: dict[str, Any]) -> None:
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
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass


def blank_state() -> dict[str, Any]:
    return {
        "schemaVersion": 2,
        "deliveries": [],
        "sentHashes": [],
        "uncertain": [],
        "pendingAcks": [],
    }


def migrate_state(state: dict[str, Any]) -> dict[str, Any]:
    """Preserve the original 44-hash ledger while adding sender-only fields."""
    state["schemaVersion"] = 2
    state.setdefault("deliveries", [])
    state.setdefault("sentHashes", [])
    state.setdefault("uncertain", [])
    state.setdefault("pendingAcks", [])
    return state


def safe_run(command: list[str], timeout: int = 90) -> str:
    result = subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
        timeout=timeout,
        env={"PATH": "/usr/local/bin:/usr/bin:/bin", "HOME": str(Path.home())},
    )
    if result.returncode != 0:
        raise DigestError("desktop_visual_lane_unavailable")
    return result.stdout


def remote_manifest() -> dict[str, Any]:
    script = f"{WINDOWS_REPO}/scripts/build-jon-visual-manifest.py"
    output = safe_run(
        [
            "/usr/bin/ssh",
            "-o",
            "BatchMode=yes",
            "-o",
            "ConnectTimeout=15",
            WINDOWS_HOST,
            "py",
            "-3",
            script,
            "--repo",
            WINDOWS_REPO,
            "--stdout-json",
        ],
        timeout=180,
    )
    try:
        value = json.loads(output.strip())
    except json.JSONDecodeError as exc:
        raise DigestError("desktop_manifest_invalid") from exc
    if not isinstance(value, dict) or value.get("recipient") != RECIPIENT:
        raise DigestError("desktop_manifest_invalid")
    return value


def valid_record(record: Any) -> dict[str, Any]:
    if not isinstance(record, dict):
        raise DigestError("manifest_record_invalid")
    relative = str(record.get("path") or "")
    digest = str(record.get("sha256") or "")
    size = record.get("bytes")
    parts = PurePosixPath(relative).parts
    if (
        not relative
        or PurePosixPath(relative).is_absolute()
        or ".." in parts
        or not relative.startswith(("assets/concepts/", "assets/candidates/", "assets/models/"))
        or len(digest) != 64
        or any(character not in "0123456789abcdef" for character in digest)
        or not isinstance(size, int)
        or size < 0
    ):
        raise DigestError("manifest_record_invalid")
    return record


def candidate_records(manifest: dict[str, Any], state: dict[str, Any]) -> list[dict[str, Any]]:
    sent = {value for value in state.get("sentHashes", []) if isinstance(value, str)}
    uncertain = {
        digest
        for item in state.get("uncertain", [])
        if isinstance(item, dict)
        for digest in item.get("artifactHashes", [])
        if isinstance(digest, str)
    }
    records = [valid_record(record) for record in manifest.get("unsentArtifacts", [])]
    by_hash: dict[str, dict[str, Any]] = {}
    for record in records:
        digest = str(record["sha256"])
        if digest not in sent and digest not in uncertain:
            by_hash.setdefault(digest, record)
    return sorted(by_hash.values(), key=lambda item: (str(item["path"]), str(item["sha256"])))


def partition_records(
    records: list[dict[str, Any]],
    max_bytes: int = MAX_PACKET_BYTES,
    max_attachments: int = MAX_PACKET_ATTACHMENTS,
) -> list[list[dict[str, Any]]]:
    packets: list[list[dict[str, Any]]] = []
    current: list[dict[str, Any]] = []
    current_bytes = 0
    for record in records:
        size = int(record["bytes"])
        if size > max_bytes:
            raise DigestError("visual_attachment_too_large")
        if current and (current_bytes + size > max_bytes or len(current) >= max_attachments):
            packets.append(current)
            current = []
            current_bytes = 0
        current.append(record)
        current_bytes += size
    if current:
        packets.append(current)
    return packets


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def copy_record(record: dict[str, Any], destination: Path) -> Path:
    relative = str(record["path"])
    windows_scp_path = "/" + WINDOWS_REPO.replace("\\", "/") + "/" + relative
    local = destination / str(record["sha256"])[:16] / Path(relative).name
    local.parent.mkdir(parents=True, exist_ok=True)
    safe_run(["/usr/bin/scp", "-q", f"{WINDOWS_HOST}:{windows_scp_path}", str(local)], timeout=180)
    if local.stat().st_size != int(record["bytes"]) or file_sha256(local) != str(record["sha256"]):
        raise DigestError("visual_attachment_changed_during_copy")
    return local


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
        raise DigestError(f"secret_unavailable:{name}")
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
        raise DigestError("gmail_token_refresh_failed") from exc
    token = payload.get("access_token")
    if not isinstance(token, str) or not token:
        raise DigestError("gmail_token_missing")
    return token


def gmail_json(
    path: str,
    token: str,
    payload: dict[str, Any] | None = None,
    params: dict[str, Any] | None = None,
) -> dict[str, Any]:
    query = urllib.parse.urlencode(params or {}, doseq=True)
    url = f"https://gmail.googleapis.com/gmail/v1/users/me/{path}"
    if query:
        url = f"{url}?{query}"
    request = urllib.request.Request(
        url,
        data=None if payload is None else json.dumps(payload, separators=(",", ":")).encode("utf-8"),
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        method="GET" if payload is None else "POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            value = json.loads(response.read())
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
        raise DigestError("gmail_api_ambiguous_failure") from exc
    if not isinstance(value, dict):
        raise DigestError("gmail_api_invalid_response")
    return value


def packet_identity(records: list[dict[str, Any]], subject: str) -> str:
    material = subject + "\n" + "\n".join(str(record["sha256"]) for record in records)
    return hashlib.sha256(material.encode("utf-8")).hexdigest()[:24]


def build_message(
    records: list[dict[str, Any]], attachments: list[Path], subject: str, packet_id: str
) -> EmailMessage:
    message = EmailMessage(policy=SMTP)
    message["To"] = RECIPIENT
    message["From"] = SENDER
    message["Subject"] = subject
    message["Message-ID"] = f"<pipi-{packet_id}@buffalowebproducts.com>"
    message["X-Pipi-Labu-Digest"] = packet_id
    filenames = "\n".join(f"- {record['path']}" for record in records)
    message.set_content(
        "Jon — attached are the new Pipi Labu visuals ready for your review.\n\n"
        "These are actual review files and are content-hash deduplicated; earlier delivered "
        "visuals are not included again.\n\n"
        f"Files:\n{filenames}\n"
    )
    for record, path in zip(records, attachments, strict=True):
        mime, _ = mimetypes.guess_type(path.name)
        maintype, subtype = (mime or "application/octet-stream").split("/", 1)
        message.add_attachment(path.read_bytes(), maintype=maintype, subtype=subtype, filename=path.name)
    return message


def send_message(message: EmailMessage, token: str) -> None:
    raw = base64.urlsafe_b64encode(message.as_bytes()).decode("ascii")
    response = gmail_json("messages/send", token, {"raw": raw})
    if not isinstance(response.get("id"), str):
        raise DigestError("gmail_send_not_confirmed")


def remote_ack(hashes: list[str], label: str, subject: str) -> None:
    script = f"{WINDOWS_REPO}/scripts/build-jon-visual-manifest.py"
    command = [
        "/usr/bin/ssh",
        "-o",
        "BatchMode=yes",
        "-o",
        "ConnectTimeout=15",
        WINDOWS_HOST,
        "py",
        "-3",
        script,
        "--repo",
        WINDOWS_REPO,
        "--delivery-label",
        label,
        "--delivery-subject",
        subject,
    ]
    for digest in hashes:
        command.extend(["--mark-hash", digest])
    safe_run(command, timeout=180)


def quarantine_abandoned_inflight(state: dict[str, Any]) -> bool:
    inflight = state.pop("inFlight", None)
    if not isinstance(inflight, dict):
        return False
    uncertain = [item for item in state.get("uncertain", []) if isinstance(item, dict)]
    uncertain.append({**inflight, "quarantinedUtc": now_utc().isoformat()})
    state["uncertain"] = uncertain
    return True


def record_success(
    state: dict[str, Any], records: list[dict[str, Any]], subject: str, packet_id: str, local_date: str
) -> None:
    hashes = [str(record["sha256"]) for record in records]
    sent = {value for value in state.get("sentHashes", []) if isinstance(value, str)}
    sent.update(hashes)
    deliveries = [item for item in state.get("deliveries", []) if isinstance(item, dict)]
    deliveries.append(
        {
            "packetId": packet_id,
            "recipient": RECIPIENT,
            "subject": subject,
            "deliveredUtc": now_utc().isoformat(),
            "artifactHashes": hashes,
        }
    )
    state["schemaVersion"] = 2
    state["sentHashes"] = sorted(sent)
    state["deliveries"] = deliveries
    state["lastDigestLocalDate"] = local_date
    state.pop("inFlight", None)


def retry_pending_acks(state: dict[str, Any]) -> None:
    remaining: list[dict[str, Any]] = []
    for item in state.get("pendingAcks", []):
        if not isinstance(item, dict):
            continue
        try:
            remote_ack(
                [str(value) for value in item.get("artifactHashes", [])],
                str(item.get("label") or "Pipi Labu visual digest"),
                str(item.get("subject") or "Pipi Labu visual digest"),
            )
        except DigestError:
            remaining.append(item)
    state["pendingAcks"] = remaining


def status_line(status: str, **fields: Any) -> str:
    safe = {"status": status, **fields}
    return json.dumps(safe, separators=(",", ":"), sort_keys=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--live", action="store_true", help="perform the authorized Gmail delivery")
    parser.add_argument("--verify-gmail", action="store_true", help="verify the sender and prior attachment lane without sending")
    parser.add_argument("--ignore-daily-gate", action="store_true")
    parser.add_argument("--state", default=str(STATE_ROOT / "state.json"))
    args = parser.parse_args()
    state_path = Path(args.state)
    state = migrate_state(read_json(state_path, blank_state()))
    if quarantine_abandoned_inflight(state):
        write_json(state_path, state)
        print(status_line("blocked_uncertain_delivery", uncertain=len(state.get("uncertain", []))))
        return 2
    if state.get("uncertain"):
        print(status_line("blocked_uncertain_delivery", uncertain=len(state.get("uncertain", []))))
        return 2

    if args.live:
        retry_pending_acks(state)
        write_json(state_path, state)
    manifest = remote_manifest()
    records = candidate_records(manifest, state)
    packets = partition_records(records)
    local_date = now_utc().astimezone(LOCAL_TIMEZONE).date().isoformat()
    if args.verify_gmail:
        token = gmail_access_token()
        profile = gmail_json("profile", token)
        if str(profile.get("emailAddress") or "").casefold() != SENDER.casefold():
            raise DigestError("gmail_sender_identity_mismatch")
        prior = gmail_json(
            "messages",
            token,
            params={
                "q": f"in:sent to:{RECIPIENT} has:attachment newer_than:7d",
                "maxResults": 20,
            },
        )
        prior_count = len(prior.get("messages", [])) if isinstance(prior.get("messages"), list) else 0
        print(status_line("gmail_identity_ok", sender=SENDER, priorAttachmentMessages=prior_count))
        if not args.live:
            return 0
    if not records:
        print(status_line("no_new_visuals", artifacts=manifest.get("artifactCount", 0), unsent=0))
        return 0
    if not args.ignore_daily_gate and state.get("lastDigestLocalDate") == local_date:
        print(status_line("deferred_daily_digest", unsent=len(records), packets=len(packets)))
        return 0
    if not args.live:
        print(status_line("dry_run", unsent=len(records), packets=len(packets)))
        return 0

    token = gmail_access_token()
    profile = gmail_json("profile", token)
    if str(profile.get("emailAddress") or "").casefold() != SENDER.casefold():
        raise DigestError("gmail_sender_identity_mismatch")

    delivered = 0
    for index, packet in enumerate(packets, start=1):
        subject = f"Pipi Labu visual digest {local_date} ({index}/{len(packets)})"
        packet_id = packet_identity(packet, subject)
        label = f"automated visual digest {local_date} packet {index}/{len(packets)}"
        with tempfile.TemporaryDirectory(prefix="pipilabu-visual-") as directory:
            attachments = [copy_record(record, Path(directory)) for record in packet]
            message = build_message(packet, attachments, subject, packet_id)
            state["inFlight"] = {
                "packetId": packet_id,
                "recipient": RECIPIENT,
                "subject": subject,
                "startedUtc": now_utc().isoformat(),
                "artifactHashes": [str(record["sha256"]) for record in packet],
            }
            write_json(state_path, state)
            send_message(message, token)
        record_success(state, packet, subject, packet_id, local_date)
        try:
            remote_ack([str(record["sha256"]) for record in packet], label, subject)
        except DigestError:
            pending = [item for item in state.get("pendingAcks", []) if isinstance(item, dict)]
            pending.append(
                {
                    "label": label,
                    "subject": subject,
                    "artifactHashes": [str(record["sha256"]) for record in packet],
                }
            )
            state["pendingAcks"] = pending
        write_json(state_path, state)
        delivered += len(packet)

    print(status_line("delivered", recipient=RECIPIENT, attachments=delivered, packets=len(packets)))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except DigestError as exc:
        print(status_line("error", reason=str(exc)))
        raise SystemExit(1)
