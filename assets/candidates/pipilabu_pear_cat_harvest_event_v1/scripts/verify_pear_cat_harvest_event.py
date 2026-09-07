"""Verify the deterministic ART-006 pear-cat harvest-event candidate."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

from PIL import Image


SCRIPT_VERSION = "1.0.0"
EXPECTED_STATES = ["TREE_HANG", "HAND_SQUASH", "BASKET_CLUSTER", "RECEIPT_DELIGHT"]
EXPECTED_SHEET_SIZE = (1800, 1120)
EXPECTED_MOBILE_SIZE = (960, 420)
EXPECTED_EYE_GLINT = (255, 245, 216)
EXPECTED_RUBY = (199, 72, 62)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate-dir", required=True)
    return parser.parse_args()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def stable_json_write(path: Path, payload: Any) -> None:
    with path.open("w", encoding="utf-8", newline="\n") as handle:
        json.dump(payload, handle, indent=2, sort_keys=True)
        handle.write("\n")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def verify_image(candidate_dir: Path, relative: str, expected_size: tuple[int, int]) -> dict[str, Any]:
    path = candidate_dir / relative
    require(path.is_file(), f"Missing image: {relative}")
    with Image.open(path) as image:
        require(image.format == "PNG", f"Not a PNG: {relative}")
        require(image.mode == "RGB", f"Image must be RGB: {relative}")
        require(image.size == expected_size, f"Unexpected size for {relative}: {image.size}")
        colors = image.getcolors(maxcolors=10_000_000)
        require(colors is not None and len(colors) > 80, f"Image has insufficient color variation: {relative}")
        color_set = {color for _, color in colors}
        if relative.endswith("sheet.png"):
            require(EXPECTED_EYE_GLINT in color_set, "Review sheet lost eye catchlight color")
            require(EXPECTED_RUBY in color_set, "Review sheet lost receipt-fruit accent")
    return {
        "path": relative,
        "bytes": path.stat().st_size,
        "sha256": sha256_file(path),
        "dimensions": list(expected_size),
        "mode": "RGB",
    }


def main() -> None:
    args = parse_args()
    candidate_dir = Path(args.candidate_dir).resolve()
    repo_root = candidate_dir.parents[2]
    contract_path = candidate_dir / "pear_cat_harvest_event_contract.json"
    report_path = candidate_dir / "generation_report.json"
    verification_dir = candidate_dir / "verification"
    verification_dir.mkdir(parents=True, exist_ok=True)

    contract = read_json(contract_path)
    report = read_json(report_path)
    require(contract["candidate_id"] == "PIPILABU-PEAR-CAT-HARVEST-EVENT-V1", "Wrong candidate id")
    require(contract["ticket"] == "ART-006", "Wrong ticket")
    require(contract["status"] == "REVIEW_CANDIDATE", "Candidate is not a review candidate")
    require(report["candidate_id"] == contract["candidate_id"], "Generation report candidate mismatch")
    require(report["ticket"] == "ART-006", "Generation report ticket mismatch")
    require(report["script_version"] == SCRIPT_VERSION, "Generator/verifier version mismatch")

    approval = contract["approval"]
    require(all(value is False for value in approval.values()), "Approval or mutation flag is not false")
    require(report["approval"] == approval, "Generation report approval flags drifted")
    runtime = report["runtime_mutation"]
    require(all(value is False for value in runtime.values()), "Generation report records a runtime mutation")

    source = contract["source"]
    source_scan = report["source_scan"]
    require(source["raw_attachment_status"] == "inaccessible_in_isolated_worktree", "Raw reference status changed")
    require(source["raw_reference_matches"] == [], "Unexpected raw reference match was recorded")
    require(source["fallback_brief_used"] is True, "Fallback brief was not recorded as used")
    require(source_scan["fallback_brief_used"] is True, "Generation report did not record fallback use")
    expected_fallback_sha = hashlib.sha256(source["fallback_brief"].encode("utf-8")).hexdigest()
    require(source_scan["fallback_brief"]["sha256"] == expected_fallback_sha, "Fallback brief hash mismatch")
    require(source["fallback_brief_sha256"] == "recorded_in_generation_report", "Fallback hash provenance marker missing")
    require(source_scan["raw_reference_matches"] == [], "Generation report has unexpected raw reference match")

    recorded_sources = {record["path"]: record for record in source_scan["local_doctrine_refs"]}
    expected_sources = {reference["path"]: reference for reference in source["local_doctrine_refs"]}
    require(set(recorded_sources) == set(expected_sources), "Doctrine source manifest differs from contract")
    for relative, reference in expected_sources.items():
        path = repo_root / relative
        require(path.is_file(), f"Missing doctrine source: {relative}")
        current_hash = sha256_file(path)
        record = recorded_sources[relative]
        require(record["sha256"] == current_hash, f"Doctrine source hash drifted: {relative}")
        require(record["bytes"] == path.stat().st_size, f"Doctrine source byte count drifted: {relative}")
        require(record["reason"] == reference["reason"], f"Doctrine source reason drifted: {relative}")

    require(report["contract"]["path"] == contract_path.name, "Contract path missing from report")
    require(report["contract"]["bytes"] == contract_path.stat().st_size, "Contract byte count mismatch")
    require(report["contract"]["sha256"] == sha256_file(contract_path), "Contract hash mismatch")

    identity = contract["identity_contract"]
    require(identity["role"] == "rare_orchard_customer_or_harvest_surprise", "Role boundary drifted")
    require("owner" in identity["family_boundary"].lower(), "Owner boundary missing")
    require("player" in identity["family_boundary"].lower(), "Player boundary missing")
    require("baby" in identity["family_boundary"].lower(), "Baby boundary missing")
    require("rights-safe" in identity["rights_safety"].lower() or "original" in identity["rights_safety"].lower(), "Rights-safety note missing")
    visual_distinction = " ".join(identity["visual_distinction"]).lower()
    require("tan/golden" in visual_distinction, "Warm tan/golden cat palette is missing")
    require("cat-loaf" in visual_distinction, "Cat-loaf identity is missing")
    require("feline eyes" in visual_distinction, "Feline eye language is missing")
    require("whiskers" in visual_distinction, "Whisker language is missing")
    require("fruit is context" in visual_distinction, "Fruit-context boundary is missing")

    silhouette = contract["silhouette_contract"]
    require(silhouette["pivot"] == "ground_center_under_body", "Pivot contract drifted")
    require(silhouette["body_bounds_studs"] == [2.25, 2.35, 2.1], "Body scale contract drifted")
    require("lateral" in silhouette["ear_rule"].lower(), "Lateral ear rule missing")
    require("no top" in silhouette["ear_rule"].lower(), "No-top-ear rule missing")
    forbidden = " ".join(silhouette["forbidden_geometry"]).lower()
    require("prominent top ears" in forbidden, "Top-ear rejection missing")
    require("dog muzzle" in forbidden, "Dog-boundary rejection missing")
    require("literal green pear body" in forbidden, "Literal pear-body rejection missing")
    require("stem or leaf" in forbidden, "Crown stem/leaf rejection missing")
    require("no literal pear taper" in silhouette["body_read"].lower(), "Round cat-loaf body rule missing")
    require("tan/golden" in contract["material_contract"]["base"].lower(), "Tan/golden material contract missing")
    require("literal pear-shaped" in " ".join(contract["material_contract"]["do_not"]).lower(), "Literal pear material rejection missing")

    states = contract["states"]
    require([state["id"] for state in states] == EXPECTED_STATES, "State order/count drifted")
    for state in states:
        for key in ("label", "emotion", "context", "pose", "interaction", "mobile_read"):
            require(isinstance(state.get(key), str) and state[key].strip(), f"State {state['id']} missing {key}")
    require(contract["mechanic_contract"]["sensory_peak"] == "RECEIPT_DELIGHT", "Sensory peak is not receipt delight")
    require(contract["mechanic_contract"]["new_mechanics_added"] is False, "New mechanics flag is not false")
    require(contract["mechanic_contract"]["verb_sequence"] == ["reach", "carry", "serve", "contact", "hold/receipt"], "Verb sequence drifted")

    review_relative = contract["artifacts"]["review_sheet"]
    mobile_relative = contract["artifacts"]["mobile_strip"]
    image_records = [
        verify_image(candidate_dir, review_relative, EXPECTED_SHEET_SIZE),
        verify_image(candidate_dir, mobile_relative, EXPECTED_MOBILE_SIZE),
    ]
    report_records = {record["path"]: record for record in report["artifacts"]}
    for record in image_records:
        source_record = report_records.get(record["path"])
        require(source_record is not None, f"Artifact missing from generation report: {record['path']}")
        require(source_record == record, f"Artifact hash/metadata mismatch: {record['path']}")

    unsafe_extensions = {".rbxl", ".rbxlx", ".place", ".blend", ".fbx", ".luau"}
    unsafe = [str(path.relative_to(candidate_dir)) for path in candidate_dir.rglob("*") if path.is_file() and path.suffix.lower() in unsafe_extensions]
    require(unsafe == [], f"Candidate contains out-of-scope runtime/scene assets: {unsafe}")

    checks = [
        "ART-006 contract identity/status and all approval flags are bounded",
        "fallback brief and local doctrine source paths/hashes are recorded",
        "golden feline family boundary, exact scale, ground pivot, no-top-ear, whisker, and no-literal-pear rules are present",
        "tree-hang/hand-squash/basket-cluster/receipt-delight states are ordered and mobile-read fields are non-empty",
        "review sheet is RGB 1800x1120 with eye catchlights and receipt accent",
        "mobile strip is RGB 960x420",
        "generation artifacts match their recorded SHA-256 hashes",
        "candidate contains no Studio/place/Blender/runtime source asset",
    ]
    structural = {
        "status": "PASS",
        "candidate_id": contract["candidate_id"],
        "ticket": "ART-006",
        "verifier_version": SCRIPT_VERSION,
        "checks": checks,
        "review_artifacts": image_records,
        "source_hashes": source_scan["local_doctrine_refs"],
        "fallback_brief_sha256": expected_fallback_sha,
        "human_approved": False,
        "studio_imported": False,
    }
    stable_json_write(verification_dir / "structural_report.json", structural)
    print("PIPILABU_PEAR_CAT_VERIFY_OK")


if __name__ == "__main__":
    main()
