"""Verify the isolated ART-003 apple and serving-prop candidate."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

from PIL import Image


SCRIPT_VERSION = "1.0.0"
EXPECTED_MODULE_IDS = [
    "APPLE_RUBY_HANDOFF_1_3",
    "APPLE_HONEYGOLD_HANDOFF_1_3",
    "CRATE_RUBY_6X2_5",
    "CRATE_HONEYGOLD_6X2_5",
    "COUNTER_TRAY_3X1_6",
    "PRICE_MARKER_RUBY_1X0_75",
    "PRICE_MARKER_HONEYGOLD_1X0_75",
]
EXPECTED_MATERIALS = {
    "AppleSkin_Ruby",
    "AppleSkin_Honeygold",
    "Stem_Wood",
    "Leaf_Muted",
    "Crate_WarmWood",
    "Crate_DarkWood",
    "Tray_Cream",
    "Marker_Paper",
    "CollisionProxy",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate-dir", required=True)
    return parser.parse_args()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"PIPILABU_APPLE_PROPS_VERIFY_FAIL {message}")


def close_vector(actual: list[float], expected: list[float], label: str, tolerance: float = 0.00001) -> None:
    require(len(actual) == len(expected), f"{label} length mismatch")
    require(all(abs(float(left) - float(right)) <= tolerance for left, right in zip(actual, expected)), f"{label} mismatch: {actual} != {expected}")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def parse_obj(path: Path) -> dict[str, Any]:
    vertices: list[list[float]] = []
    faces: list[list[int]] = []
    materials: list[str] = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if line.startswith("v "):
            values = line.split()
            require(len(values) == 4, f"invalid vertex in {path.name}")
            vertices.append([float(values[1]), float(values[2]), float(values[3])])
        elif line.startswith("usemtl "):
            material = line.split(maxsplit=1)[1]
            if material not in materials:
                materials.append(material)
        elif line.startswith("f "):
            values = line.split()[1:]
            require(len(values) >= 3, f"degenerate face in {path.name}")
            indices: list[int] = []
            for value in values:
                index_text = value.split("/", maxsplit=1)[0]
                index = int(index_text)
                indices.append(index - 1 if index > 0 else len(vertices) + index)
            require(all(0 <= index < len(vertices) for index in indices), f"face index out of range in {path.name}")
            faces.append(indices)
    require(vertices and faces, f"empty OBJ: {path.name}")
    bounds_min = [round(min(vertex[index] for vertex in vertices), 6) for index in range(3)]
    bounds_max = [round(max(vertex[index] for vertex in vertices), 6) for index in range(3)]
    return {
        "vertices": len(vertices),
        "faces": len(faces),
        "triangles": sum(max(0, len(face) - 2) for face in faces),
        "bounds_min": bounds_min,
        "bounds_max": bounds_max,
        "materials": sorted(materials),
    }


def read_mtl_names(path: Path) -> set[str]:
    return {line.split(maxsplit=1)[1] for line in path.read_text(encoding="utf-8").splitlines() if line.startswith("newmtl ")}


def main() -> None:
    args = parse_args()
    candidate_dir = Path(args.candidate_dir).resolve()
    contract_path = candidate_dir / "apple_serving_props_contract.json"
    report_path = candidate_dir / "generation_report.json"
    image_path = candidate_dir / "apple_serving_props_sheet.png"
    layout_path = candidate_dir / "assembly_layout.json"
    require(contract_path.is_file(), "missing apple_serving_props_contract.json")
    require(report_path.is_file(), "missing generation_report.json")
    require(image_path.is_file(), "missing apple_serving_props_sheet.png")
    require(layout_path.is_file(), "missing assembly_layout.json")

    contract: dict[str, Any] = json.loads(contract_path.read_text(encoding="utf-8"))
    require(contract.get("candidate_id") == "PIPILABU-APPLE-SERVING-PROP-KIT-V1", "candidate id mismatch")
    require(contract.get("ticket") == "ART-003", "ticket mismatch")
    require(contract.get("status") == "REVIEW_CANDIDATE", "candidate must remain REVIEW_CANDIDATE")
    approval = contract.get("approval")
    require(isinstance(approval, dict) and approval, "approval block missing")
    require(all(value is False for value in approval.values()), "approval or integration flag is not false")

    source = contract.get("source_truth")
    require(isinstance(source, dict), "source_truth missing")
    require(source.get("catalog_file") == "src/shared/AppleCatalog.luau", "catalog source changed")
    require(source.get("gameplay_file") == "src/server/GameService.luau", "gameplay source changed")
    require(source.get("existing_crate_size_studs") == [6.0, 2.5, 5.0], "existing crate size changed")
    existing = source.get("existing_prop_contract")
    require(isinstance(existing, dict), "existing prop contract missing")
    require(existing.get("held_apple_size_studs") == [1.3, 1.3, 1.3], "held apple source size changed")
    require(existing.get("received_target_size_studs") == [1.42, 1.16, 1.42], "received target source size changed")
    require(existing.get("received_settle_size_studs") == [1.3, 1.3, 1.3], "received settle size changed")
    require(existing.get("handoff_duration_seconds") == 0.16, "handoff duration changed")
    require(existing.get("handoff_arc_height_studs") == 0.28, "handoff arc changed")
    require(existing.get("handoff_spin_degrees") == 18.0, "handoff spin changed")
    require(existing.get("handoff_settle_seconds") == 0.08, "handoff settle changed")
    require("Do not edit" in source.get("reuse_rule", ""), "read-only reuse rule missing")

    materials = contract.get("material_contract")
    require(isinstance(materials, dict) and materials.get("metalness") == 0.0, "material contract missing or metalness changed")
    require(EXPECTED_MATERIALS - {"CollisionProxy"} <= set(materials.get("roles", {}).keys()), "material roles incomplete")

    modules = contract.get("modules")
    require(isinstance(modules, list) and [module.get("id") for module in modules] == EXPECTED_MODULE_IDS, "module order or count mismatch")
    triangle_budgets = contract["import_contract"]["review_budget"]
    module_metrics: dict[str, Any] = {}
    for module in modules:
        obj_path = candidate_dir / module["file"]
        mtl_path = candidate_dir / module["material_file"]
        require(obj_path.is_file(), f"missing OBJ: {module['id']}")
        require(mtl_path.is_file(), f"missing MTL: {module['id']}")
        metrics = parse_obj(obj_path)
        module_metrics[module["id"]] = metrics
        close_vector(metrics["bounds_min"], module["bounds_min"], f"{module['id']} bounds_min")
        close_vector(metrics["bounds_max"], module["bounds_max"], f"{module['id']} bounds_max")
        require(set(metrics["materials"]) <= set(module["materials"]), f"unexpected material on {module['id']}")
        require(set(metrics["materials"]) <= read_mtl_names(mtl_path), f"OBJ material missing from MTL: {module['id']}")
        budget_key = {
            "apple_visual": "apple_triangles_max",
            "apple_crate_visual": "crate_triangles_max",
            "counter_display_tray": "tray_triangles_max",
            "price_marker_display": "marker_triangles_max",
        }.get(module["type"])
        require(budget_key is not None and metrics["triangles"] <= triangle_budgets[budget_key], f"triangle budget exceeded: {module['id']}")
        if module["type"] in {"apple_visual", "counter_display_tray", "price_marker_display"}:
            require(module["collision_mode"] == "none", f"display prop collision mode changed: {module['id']}")
            require(module["can_collide"] is False and module["can_touch"] is False and module["can_query"] is False, f"display prop flags changed: {module['id']}")
        if module["type"] == "apple_crate_visual":
            require(module["collision_mode"] == "structural_proxy", f"crate collision mode changed: {module['id']}")
            require(module["can_collide"] is True and module["can_touch"] is False and module["can_query"] is True, f"crate flags changed: {module['id']}")

    collision = contract["collision_contract"]
    collision_obj = candidate_dir / collision["file"]
    collision_mtl = collision_obj.with_suffix(".mtl")
    require(collision_obj.is_file() and collision_mtl.is_file(), "missing crate collision proxy")
    collision_metrics = parse_obj(collision_obj)
    close_vector(collision_metrics["bounds_min"], collision["bounds_min"], "collision bounds_min")
    close_vector(collision_metrics["bounds_max"], collision["bounds_max"], "collision bounds_max")
    require(collision_metrics["triangles"] <= triangle_budgets["collision_triangles_max"], "collision triangle budget exceeded")
    require(collision["flags"] == {"CanCollide": True, "CanTouch": False, "CanQuery": True}, "collision flags changed")
    require(read_mtl_names(collision_mtl) == {"CollisionProxy"}, "collision MTL contains unexpected roles")

    handoff = contract["handoff_contract"]
    require(handoff["player_hold"]["attachment"] == "RightHand", "player attachment changed")
    require(handoff["customer_receipt"]["prop_name"] == "ReceivedApple", "received prop name changed")
    require("Contact is the largest visual beat" in handoff["handoff"]["focal_rule"], "contact focal rule missing")
    require(handoff["customer_receipt"]["pre_settle_size"] == [1.42, 1.16, 1.42], "receipt pre-settle contract changed")

    rarity = contract["rarity_seam"]
    require(rarity["status"] == "RESERVED_NO_RUNTIME" and rarity["default_state"] == "omitted", "rarity seam is not reserved/omitted")
    require(all(term in rarity["prohibited_now"] for term in ["new mechanics", "glow", "rarity UI"]), "rarity seam guard incomplete")

    layout: dict[str, Any] = json.loads(layout_path.read_text(encoding="utf-8"))
    require(len(layout.get("placements", [])) == 7, "assembly placement count changed")
    require([placement["module_id"] for placement in layout["placements"]] == [
        "CRATE_RUBY_6X2_5",
        "CRATE_HONEYGOLD_6X2_5",
        "APPLE_RUBY_HANDOFF_1_3",
        "APPLE_HONEYGOLD_HANDOFF_1_3",
        "COUNTER_TRAY_3X1_6",
        "PRICE_MARKER_RUBY_1X0_75",
        "PRICE_MARKER_HONEYGOLD_1X0_75",
    ], "assembly placement order changed")
    handoff_story = layout.get("handoff_story")
    require([state["state"] for state in handoff_story] == ["carry", "contact", "customer_hold"], "handoff storyboard states changed")
    require(handoff_story[1].get("visual_only") is True, "contact storyboard was not marked visual-only")
    require(layout["rarity_seam"] == {"status": "reserved_omitted", "runtime": False}, "layout rarity seam changed")

    with Image.open(image_path) as image:
        image.load()
        require(image.size == (1800, 1100) and image.mode in ("RGB", "RGBA"), f"unexpected review PNG: {image.size}/{image.mode}")
        thumbnail = image.convert("RGB").resize((90, 55))
        thumbnail.load()
        sampled_colors = {thumbnail.getpixel((x, y)) for x in range(thumbnail.width) for y in range(thumbnail.height)}
        require(len(sampled_colors) >= 24, "review PNG lacks authored color/detail variation")

    generation_report: dict[str, Any] = json.loads(report_path.read_text(encoding="utf-8"))
    require(generation_report.get("candidate_id") == contract["candidate_id"], "generation report candidate mismatch")
    require(generation_report.get("module_count") == len(EXPECTED_MODULE_IDS), "generation report module count mismatch")
    require(generation_report.get("review_artifact", {}).get("sha256") == sha256(image_path), "review image hash mismatch")
    require(generation_report.get("studio_imported") is False and generation_report.get("human_approved") is False, "generation report records approval/import")
    require(generation_report.get("source_pixels") == "procedural Pillow drawing and generated OBJ/MTL only", "generation source is not procedural")
    normalized_generated = {str(path).replace("\\", "/") for path in generation_report.get("generated_files", [])}
    require("apple_serving_props_sheet.png" in normalized_generated and "collision/COLLISION_CRATE_6X2_5.obj" in normalized_generated, "generation file inventory incomplete")

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
            "read_only_gameplay_source_invariants": True,
            "module_bounds_pivots_and_materials": True,
            "triangle_budgets": True,
            "display_collision_flags": True,
            "crate_collision_proxy": True,
            "handoff_attachment_and_scale_contract": True,
            "rarity_seam_reserved_without_runtime": True,
            "assembly_layout": True,
            "review_png_dimensions_and_detail": True,
            "generation_report_hash": True,
            "studio_or_human_approval": False,
        },
        "module_metrics": module_metrics,
        "collision_metrics": collision_metrics,
        "review_artifact": {"file": image_path.name, "width": 1800, "height": 1100, "sha256": sha256(image_path)},
        "studio_imported": False,
        "human_approved": False,
    }
    output_path = verification_dir / "structural_report.json"
    output_path.write_text(json.dumps(structural_report, indent=2) + "\n", encoding="utf-8", newline="\n")
    print("PIPILABU_APPLE_PROPS_VERIFY_OK " + json.dumps(structural_report, sort_keys=True))


if __name__ == "__main__":
    main()
