"""Verify the bounded Pipi Labu baby-customer cast candidate.

This verifier checks the review contract and generated board only. It does not
open Blender, Studio, Rojo, or any cloud place, and it never treats the board
as approval of a character asset or gameplay integration.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

from PIL import Image


SCRIPT_VERSION = "1.0.0"
REQUIRED_ROLE_IDS = ["RubySprout", "HoneygoldHugger", "ShyLoaf", "HurryWaddle"]
REQUIRED_ACTIONS = [
    "Pipilabu_Idle",
    "Pipilabu_Receive",
    "Pipilabu_Hold",
    "Pipilabu_Happy",
    "Pipilabu_TurnLeave",
    "Pipilabu_Run",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate-dir", required=True)
    return parser.parse_args()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"PIPILABU_BABY_CAST_VERIFY_FAIL {message}")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    args = parse_args()
    candidate_dir = Path(args.candidate_dir).resolve()
    contract_path = candidate_dir / "baby_customer_cast_contract.json"
    image_path = candidate_dir / "baby_customer_cast_sheet.png"
    report_path = candidate_dir / "generation_report.json"
    require(contract_path.is_file(), "missing baby_customer_cast_contract.json")
    require(image_path.is_file(), "missing baby_customer_cast_sheet.png")
    require(report_path.is_file(), "missing generation_report.json")

    contract: dict[str, Any] = json.loads(contract_path.read_text(encoding="utf-8"))
    require(contract.get("candidate_id") == "PIPILABU-BABY-CUSTOMER-CAST-V1", "candidate id mismatch")
    require(contract.get("ticket") == "ART-002", "ticket mismatch")
    require(contract.get("status") == "REVIEW_CANDIDATE", "candidate must remain REVIEW_CANDIDATE")

    approval = contract.get("approval")
    require(isinstance(approval, dict) and approval, "approval block missing")
    require(all(value is False for value in approval.values()), "approval or integration flag is not false")

    source = contract.get("source_truth")
    require(isinstance(source, dict), "source_truth block missing")
    require(source.get("base_model_version") == "v4", "base model is not v4")
    require(source.get("base_generator_version") == "2.3.0", "base generator version changed")
    require(source.get("base_bounds_meters_approx") == [2.25, 2.05, 2.5], "base bounds changed")
    require(source.get("base_triangles") == 21326, "base triangle count changed")
    require(source.get("base_actions") == REQUIRED_ACTIONS, "base action contract changed")
    require("do not edit or overwrite" in source.get("reuse_rule", "").lower(), "source reuse rule missing")

    silhouette = contract.get("shared_silhouette_contract")
    require(isinstance(silhouette, dict), "shared_silhouette_contract missing")
    require("uninterrupted circular" in silhouette.get("crown", "").lower(), "crown contract is not circular/uninterrupted")
    require(silhouette.get("ear_placement") == "lateral_embedded_only", "ear placement is not lateral embedded only")
    ear_policy = silhouette.get("ear_policy", "").lower()
    require("swallowed" in ear_policy and "no geometry may rise above" in ear_policy, "ear policy does not reject top ears")
    require(silhouette.get("mobile_read_rule"), "mobile read rule missing")

    scale_band = silhouette.get("scale_band")
    require(isinstance(scale_band, dict), "scale band missing")
    body_min = float(scale_band["body_scale_min"])
    body_max = float(scale_band["body_scale_max"])
    head_min = float(scale_band["head_scale_min"])
    head_max = float(scale_band["head_scale_max"])

    roles = contract.get("roles")
    require(isinstance(roles, list) and len(roles) == 4, "cast must contain exactly four roles")
    role_ids = [role.get("id") for role in roles]
    require(role_ids == REQUIRED_ROLE_IDS, f"role order mismatch: {role_ids}")
    required_role_fields = {
        "id",
        "display_name",
        "queue_read",
        "primary_emotion",
        "body_scale",
        "head_scale",
        "gaze",
        "eye_treatment",
        "paw_pose",
        "apple_state",
        "silhouette_delta",
        "review_hypothesis",
    }
    forbidden_role_terms = ("prominent upright ear", "top-set ear", "top ear", "upright ear")
    for role in roles:
        require(required_role_fields.issubset(role), f"role fields incomplete: {role.get('id')}")
        require(body_min <= float(role["body_scale"]) <= body_max, f"body scale out of band: {role['id']}")
        require(head_min <= float(role["head_scale"]) <= head_max, f"head scale out of band: {role['id']}")
        role_text = json.dumps(role, sort_keys=True).lower()
        require(not any(term in role_text for term in forbidden_role_terms), f"role introduces rejected ear language: {role['id']}")
    honeygold = next(role for role in roles if role["id"] == "HoneygoldHugger")
    require("held" in honeygold["apple_state"].lower(), "HoneygoldHugger does not encode a held apple")
    for role in roles:
        if role["id"] != "HoneygoldHugger":
            require("no apple" in role["apple_state"].lower(), f"unexpected apple state: {role['id']}")

    artifact = contract.get("review_artifact")
    require(isinstance(artifact, dict), "review_artifact missing")
    require(artifact.get("file") == image_path.name, "review artifact filename mismatch")
    expected_size = (int(artifact["width"]), int(artifact["height"]))
    with Image.open(image_path) as image:
        image.load()
        require(image.size == expected_size == (1600, 1000), f"unexpected PNG size/mode: {image.size}/{image.mode}")
        require(image.mode in ("RGB", "RGBA"), f"unexpected PNG mode: {image.mode}")
        thumbnail = image.convert("RGB").resize((80, 50))
        thumbnail.load()
        sampled_colors = {thumbnail.getpixel((x, y)) for x in range(thumbnail.width) for y in range(thumbnail.height)}
        require(len(sampled_colors) >= 16, "rendered board lacks visual color/detail variation")

    image_digest = sha256(image_path)
    generation_report: dict[str, Any] = json.loads(report_path.read_text(encoding="utf-8"))
    require(generation_report.get("candidate_id") == contract["candidate_id"], "generation report candidate mismatch")
    require(generation_report.get("file") == image_path.name, "generation report file mismatch")
    require(generation_report.get("width") == expected_size[0] and generation_report.get("height") == expected_size[1], "generation report dimensions mismatch")
    require(generation_report.get("sha256") == image_digest, "generation report hash mismatch")
    require(generation_report.get("role_ids") == REQUIRED_ROLE_IDS, "generation report roles mismatch")
    require(generation_report.get("source_pixels") == "procedural Pillow drawing only", "generation report source is not procedural")
    require(generation_report.get("studio_imported") is False and generation_report.get("human_approved") is False, "generation report records approval/import")

    verification_dir = candidate_dir / "verification"
    verification_dir.mkdir(parents=True, exist_ok=True)
    structural_report = {
        "verifier_version": SCRIPT_VERSION,
        "candidate_id": contract["candidate_id"],
        "ticket": contract["ticket"],
        "status": "PASS",
        "checks": {
            "contract_status": True,
            "approval_flags_false": True,
            "v4_source_invariants": True,
            "four_roles_in_contract_order": True,
            "shared_circular_crown_lateral_ear_rule": True,
            "role_scale_band": True,
            "png_dimensions_and_mode": True,
            "png_thumbnail_detail": True,
            "generation_hash": True,
            "studio_or_human_approval": False,
        },
        "image": {"file": image_path.name, "width": expected_size[0], "height": expected_size[1], "sha256": image_digest},
        "role_ids": REQUIRED_ROLE_IDS,
        "studio_imported": False,
        "human_approved": False,
    }
    output_path = verification_dir / "structural_report.json"
    output_path.write_text(json.dumps(structural_report, indent=2) + "\n", encoding="utf-8")
    print("PIPILABU_BABY_CAST_VERIFY_OK " + json.dumps(structural_report, sort_keys=True))


if __name__ == "__main__":
    main()
