#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import tempfile
import unittest


MODULE_PATH = Path(__file__).with_name("pipilabu-intake.py")
SPEC = importlib.util.spec_from_file_location("pipilabu_intake", MODULE_PATH)
assert SPEC and SPEC.loader
INTAKE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(INTAKE)


def email_envelope(**overrides):
    value = {
        "schemaVersion": 1,
        "source": "gmail",
        "sourceId": "gmail-message-1",
        "project": "pipilabu",
        "sender": "Jon Walworth <jawn.walworth@gmail.com>",
        "recipient": "leo@buffalowebproducts.com",
        "subject": "[PIPILABU] Apple feedback",
        "authentication": {"spf": "pass", "dkim": "pass", "dmarc": "pass"},
        "contentType": "text/plain; charset=UTF-8",
        "hasAttachments": False,
        "forwarded": False,
        "body": "Make the customer hold the apple for one extra beat.",
    }
    value.update(overrides)
    return value


class IntakeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name) / "intake"

    def tearDown(self):
        self.temp.cleanup()

    def test_captures_authenticated_plain_text_email_privately(self):
        result = INTAKE.capture(email_envelope(), self.root)
        self.assertEqual(result["status"], "captured")
        body_path = self.root / result["record"]["request_path"]
        self.assertIn("hold the apple", body_path.read_text())
        ledger = (self.root / "ledger.jsonl").read_text()
        self.assertNotIn("hold the apple", ledger)
        self.assertFalse(result["record"]["execution_authorized"])
        self.assertFalse(result["record"]["external_reply_authorized"])

    def test_same_source_id_is_idempotent(self):
        first = INTAKE.capture(email_envelope(), self.root)
        second = INTAKE.capture(email_envelope(), self.root)
        self.assertEqual(first["status"], "captured")
        self.assertEqual(second["status"], "already_recorded")
        self.assertEqual(len((self.root / "ledger.jsonl").read_text().splitlines()), 1)

    def test_normalized_duplicate_is_not_copied_twice(self):
        INTAKE.capture(email_envelope(), self.root)
        second = INTAKE.capture(email_envelope(
            sourceId="gmail-message-2",
            body="  Make the customer HOLD the apple for one extra beat.  ",
        ), self.root)
        self.assertEqual(second["status"], "duplicate")
        self.assertIsNotNone(second["record"]["duplicate_of"])

    def test_quarantines_attachments_and_does_not_persist_body(self):
        result = INTAKE.capture(email_envelope(
            sourceId="gmail-message-secret",
            hasAttachments=True,
            body="password=do-not-store-this-value",
        ), self.root)
        self.assertEqual(result["status"], "quarantined")
        self.assertIn("attachments_quarantined", result["record"]["reasons"])
        combined = "\n".join(path.read_text(errors="replace") for path in self.root.rglob("*.*"))
        self.assertNotIn("do-not-store-this-value", combined)

    def test_accepts_verified_direct_buzz_request_from_enrolled_identity(self):
        author = next(iter(INTAKE.ALLOWED_BUZZ_AUTHORS))
        result = INTAKE.capture({
            "schemaVersion": 1,
            "source": "buzz",
            "sourceId": "buzz-event-1",
            "project": "pipilabu",
            "authorPublicKey": author,
            "signatureVerified": True,
            "directMention": True,
            "body": "[PIPILABU] Make a collision audit ticket.",
            "hasAttachments": False,
            "forwarded": False,
        }, self.root)
        self.assertEqual(result["status"], "captured")

    def test_quarantines_unknown_buzz_identity(self):
        result = INTAKE.capture({
            "schemaVersion": 1,
            "source": "buzz",
            "sourceId": "buzz-event-unknown",
            "project": "pipilabu",
            "authorPublicKey": "0" * 64,
            "signatureVerified": True,
            "directMention": True,
            "body": "@Codex [PIPILABU] Do something.",
        }, self.root)
        self.assertEqual(result["status"], "quarantined")
        self.assertIn("buzz_author_not_allowed", result["record"]["reasons"])

    def test_quarantines_shared_codex_mention_to_avoid_tnb_dispatch_conflict(self):
        author = next(iter(INTAKE.ALLOWED_BUZZ_AUTHORS))
        result = INTAKE.capture({
            "schemaVersion": 1,
            "source": "buzz",
            "sourceId": "buzz-cross-dispatch",
            "project": "pipilabu",
            "authorPublicKey": author,
            "signatureVerified": True,
            "directMention": True,
            "body": "@Codex [PIPILABU] This must not enter the T&B dispatcher.",
        }, self.root)
        self.assertEqual(result["status"], "quarantined")
        self.assertIn("shared_dispatch_conflict", result["record"]["reasons"])


if __name__ == "__main__":
    unittest.main()
