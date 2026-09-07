#!/usr/bin/env python3
"""Build the private, content-addressed Jon visual-review manifest.

This script discovers reviewable images only. It never sends email or promotes art.
"""

from __future__ import annotations

import argparse
from contextlib import contextmanager
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import time


IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".svg", ".webp", ".gif"}
EXCLUDED_NAME_PARTS = {
    ".colormap.",
    ".normal.",
    ".roughness.",
    ".metalness.",
    "debug",
    "thumbnail",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def eligible(path: Path, repo: Path) -> bool:
    if path.suffix.lower() not in IMAGE_SUFFIXES:
        return False
    relative = path.relative_to(repo).as_posix().lower()
    if any(part in path.parts for part in {".git", ".local", "__pycache__", "verification"}):
        return False
    if any(token in path.name.lower() for token in EXCLUDED_NAME_PARTS):
        return False
    return relative.startswith("assets/concepts/") or relative.startswith("assets/candidates/") or relative.startswith("assets/models/")


def discover(repo: Path) -> list[dict[str, object]]:
    records: list[dict[str, object]] = []
    assets = repo / "assets"
    if not assets.exists():
        return records
    for path in sorted(assets.rglob("*")):
        if not path.is_file() or not eligible(path, repo):
            continue
        stat = path.stat()
        records.append(
            {
                "path": path.relative_to(repo).as_posix(),
                "sha256": sha256(path),
                "bytes": stat.st_size,
                "modifiedUtc": dt.datetime.fromtimestamp(stat.st_mtime, dt.timezone.utc).isoformat(),
            }
        )
    return records


def read_json(path: Path, default: dict[str, object]) -> dict[str, object]:
    if not path.exists():
        return default
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return default
    return value if isinstance(value, dict) else default


def write_json(path: Path, value: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    temporary.replace(path)


@contextmanager
def exclusive_lock(path: Path, timeout_seconds: float = 10.0):
    """Serialize manifest/state updates without leaving a stale lock file."""
    path.parent.mkdir(parents=True, exist_ok=True)
    handle = path.open("a+b")
    handle.seek(0, os.SEEK_END)
    if handle.tell() == 0:
        handle.write(b"0")
        handle.flush()
    deadline = time.monotonic() + timeout_seconds
    while True:
        try:
            if os.name == "nt":
                import msvcrt

                handle.seek(0)
                msvcrt.locking(handle.fileno(), msvcrt.LK_NBLCK, 1)
            else:
                import fcntl

                fcntl.flock(handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            break
        except OSError:
            if time.monotonic() >= deadline:
                handle.close()
                raise RuntimeError("visual_manifest_lock_timeout")
            time.sleep(0.1)
    try:
        yield
    finally:
        if os.name == "nt":
            import msvcrt

            handle.seek(0)
            msvcrt.locking(handle.fileno(), msvcrt.LK_UNLCK, 1)
        else:
            import fcntl

            fcntl.flock(handle.fileno(), fcntl.LOCK_UN)
        handle.close()


def update_state_for_delivery(
    state: dict[str, object],
    artifacts: list[dict[str, object]],
    requested_hashes: set[str],
    label: str,
    subject: str,
) -> tuple[dict[str, object], list[str]]:
    """Mark an exact delivered hash set; reject hashes outside the live manifest."""
    artifact_hashes = {str(record["sha256"]) for record in artifacts}
    unknown = sorted(requested_hashes - artifact_hashes)
    if unknown:
        raise ValueError("delivery_hash_not_in_manifest")
    sent_hashes = {value for value in state.get("sentHashes", []) if isinstance(value, str)}
    newly_sent = sorted(requested_hashes - sent_hashes)
    if not newly_sent:
        return state, []
    deliveries = [value for value in state.get("deliveries", []) if isinstance(value, dict)]
    deliveries.append(
        {
            "label": label,
            "subject": subject,
            "deliveredUtc": dt.datetime.now(dt.timezone.utc).isoformat(),
            "recipient": "jawn.walworth@gmail.com",
            "artifactHashes": newly_sent,
        }
    )
    return {
        "schemaVersion": max(2, int(state.get("schemaVersion", 1))),
        "deliveries": deliveries,
        "sentHashes": sorted(sent_hashes | requested_hashes),
    }, newly_sent


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", default=".")
    parser.add_argument("--output", default=".local/jon-visual-digest/current-manifest.json")
    parser.add_argument("--state", default=".local/jon-visual-digest/state.json")
    parser.add_argument("--mark-sent", action="store_true")
    parser.add_argument("--mark-hash", action="append", default=[])
    parser.add_argument("--delivery-label")
    parser.add_argument("--delivery-subject")
    parser.add_argument("--stdout-json", action="store_true")
    args = parser.parse_args()

    repo = Path(args.repo).resolve()
    output = (repo / args.output).resolve()
    state_path = (repo / args.state).resolve()
    if args.mark_sent and args.mark_hash:
        parser.error("--mark-sent and --mark-hash are mutually exclusive")
    if (args.mark_sent or args.mark_hash) and not args.delivery_label:
        parser.error("--delivery-label is required when marking delivery")
    if (args.mark_sent or args.mark_hash) and not args.delivery_subject:
        parser.error("--delivery-subject is required when marking delivery")

    lock_path = state_path.with_suffix(state_path.suffix + ".lock")
    with exclusive_lock(lock_path):
        state = read_json(state_path, {"schemaVersion": 2, "deliveries": [], "sentHashes": []})
        sent_hashes = {value for value in state.get("sentHashes", []) if isinstance(value, str)}
        artifacts = discover(repo)
        unsent = [record for record in artifacts if record["sha256"] not in sent_hashes]
        requested_hashes = (
            {str(record["sha256"]) for record in unsent}
            if args.mark_sent
            else {str(value) for value in args.mark_hash}
        )
        marked: list[str] = []
        if requested_hashes:
            state, marked = update_state_for_delivery(
                state,
                artifacts,
                requested_hashes,
                args.delivery_label,
                args.delivery_subject,
            )
            if marked:
                write_json(state_path, state)
                sent_hashes.update(marked)
                unsent = [record for record in artifacts if record["sha256"] not in sent_hashes]
        manifest = {
            "schemaVersion": 2,
            "recipient": "jawn.walworth@gmail.com",
            "generatedUtc": dt.datetime.now(dt.timezone.utc).isoformat(),
            "artifactCount": len(artifacts),
            "unsentCount": len(unsent),
            "artifacts": artifacts,
            "unsentArtifacts": unsent,
        }
        write_json(output, manifest)

    if args.stdout_json:
        print(json.dumps(manifest, separators=(",", ":"), sort_keys=True))
    else:
        print(
            f"JON_VISUAL_MANIFEST_OK artifacts={len(artifacts)} unsent={len(unsent)} "
            f"marked={len(marked)}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
