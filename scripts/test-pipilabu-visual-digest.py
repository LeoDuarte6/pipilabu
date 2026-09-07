import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("pipilabu-visual-digest.py")
SPEC = importlib.util.spec_from_file_location("pipilabu_visual_digest", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(MODULE)


def record(path: str, digest: str, size: int) -> dict:
    return {"path": path, "sha256": digest, "bytes": size, "modifiedUtc": "2026-08-08T00:00:00Z"}


class PipiLabuVisualDigestTests(unittest.TestCase):
    def test_candidates_exclude_sent_and_uncertain_hashes(self):
        first, second, third = "1" * 64, "2" * 64, "3" * 64
        manifest = {
            "unsentArtifacts": [
                record("assets/concepts/one.png", first, 1),
                record("assets/candidates/two.png", second, 1),
                record("assets/models/three.png", third, 1),
            ]
        }
        state = {
            "sentHashes": [first],
            "uncertain": [{"artifactHashes": [second]}],
        }
        self.assertEqual(
            [item["sha256"] for item in MODULE.candidate_records(manifest, state)],
            [third],
        )

    def test_packet_partition_is_bounded_and_deterministic(self):
        records = [
            record(f"assets/concepts/{index}.png", f"{index:x}" * 64, 6)
            for index in range(1, 5)
        ]
        packets = MODULE.partition_records(records, max_bytes=12, max_attachments=2)
        self.assertEqual([len(packet) for packet in packets], [2, 2])

    def test_oversized_visual_fails_before_delivery(self):
        with self.assertRaisesRegex(MODULE.DigestError, "visual_attachment_too_large"):
            MODULE.partition_records(
                [record("assets/concepts/huge.png", "a" * 64, 11)], max_bytes=10
            )

    def test_message_has_real_attachments_and_deterministic_id(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "ui.png"
            path.write_bytes(b"png")
            records = [record("assets/concepts/ui.png", "a" * 64, 3)]
            subject = "Pipi Labu visual digest 2026-08-08 (1/1)"
            packet_id = MODULE.packet_identity(records, subject)
            message = MODULE.build_message(records, [path], subject, packet_id)
            attachments = list(message.iter_attachments())
            self.assertEqual(len(attachments), 1)
            self.assertEqual(attachments[0].get_filename(), "ui.png")
            self.assertEqual(message["To"], MODULE.RECIPIENT)
            self.assertIn(packet_id, message["Message-ID"])

    def test_abandoned_inflight_becomes_uncertain(self):
        state = MODULE.blank_state()
        state["inFlight"] = {"artifactHashes": ["a" * 64], "packetId": "packet"}
        self.assertTrue(MODULE.quarantine_abandoned_inflight(state))
        self.assertNotIn("inFlight", state)
        self.assertEqual(state["uncertain"][0]["artifactHashes"], ["a" * 64])


if __name__ == "__main__":
    unittest.main()
