import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("build-jon-visual-manifest.py")
SPEC = importlib.util.spec_from_file_location("jon_visual_manifest", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(MODULE)


class JonVisualManifestTests(unittest.TestCase):
    def test_discovers_review_images_and_excludes_texture_maps(self):
        with tempfile.TemporaryDirectory() as directory:
            repo = Path(directory)
            (repo / "assets/concepts").mkdir(parents=True)
            (repo / "assets/models/candidate").mkdir(parents=True)
            (repo / "assets/concepts/review.png").write_bytes(b"review")
            (repo / "assets/models/candidate/front.png").write_bytes(b"front")
            (repo / "assets/models/candidate/body.normal.png").write_bytes(b"normal")
            records = MODULE.discover(repo)
            self.assertEqual([record["path"] for record in records], ["assets/concepts/review.png", "assets/models/candidate/front.png"])

    def test_hash_changes_when_visual_changes(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "visual.png"
            path.write_bytes(b"one")
            first = MODULE.sha256(path)
            path.write_bytes(b"two")
            self.assertNotEqual(first, MODULE.sha256(path))

    def test_exact_delivery_marks_only_requested_live_hash(self):
        with tempfile.TemporaryDirectory() as directory:
            repo = Path(directory)
            (repo / "assets/concepts").mkdir(parents=True)
            (repo / "assets/concepts/one.png").write_bytes(b"one")
            (repo / "assets/concepts/two.png").write_bytes(b"two")
            artifacts = MODULE.discover(repo)
            requested = {str(artifacts[0]["sha256"])}
            state, marked = MODULE.update_state_for_delivery(
                {"schemaVersion": 1, "deliveries": [], "sentHashes": []},
                artifacts,
                requested,
                "test delivery",
                "Pipi Labu visual digest test",
            )
            self.assertEqual(marked, sorted(requested))
            self.assertEqual(state["sentHashes"], sorted(requested))
            self.assertEqual(state["deliveries"][0]["subject"], "Pipi Labu visual digest test")

    def test_exact_delivery_is_idempotent_and_rejects_unknown_hash(self):
        with tempfile.TemporaryDirectory() as directory:
            repo = Path(directory)
            (repo / "assets/concepts").mkdir(parents=True)
            (repo / "assets/concepts/one.webp").write_bytes(b"one")
            artifacts = MODULE.discover(repo)
            digest = str(artifacts[0]["sha256"])
            original = {"schemaVersion": 2, "deliveries": [], "sentHashes": [digest]}
            state, marked = MODULE.update_state_for_delivery(
                original, artifacts, {digest}, "repeat", "repeat"
            )
            self.assertIs(state, original)
            self.assertEqual(marked, [])
            with self.assertRaisesRegex(ValueError, "delivery_hash_not_in_manifest"):
                MODULE.update_state_for_delivery(original, artifacts, {"0" * 64}, "bad", "bad")


if __name__ == "__main__":
    unittest.main()
