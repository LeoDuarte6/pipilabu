"""Headless structural checks for a generated Pipilabu Shiba .blend file."""

from __future__ import annotations

import argparse
import json
import sys
import traceback
from pathlib import Path

import bpy
import bmesh


def _record_unhandled_exception(exc_type, exc_value, exc_traceback) -> None:
    error_path = Path.cwd() / ".local" / "pipilabu-blender-verify.error.log"
    error_path.parent.mkdir(parents=True, exist_ok=True)
    error_path.write_text("".join(traceback.format_exception(exc_type, exc_value, exc_traceback)), encoding="utf-8")
    sys.__excepthook__(exc_type, exc_value, exc_traceback)


sys.excepthook = _record_unhandled_exception


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--expected-variant", choices=("customer", "owner", "player"), required=True)
    parser.add_argument("--expected-model-version", choices=("v1", "v2", "v3", "v4", "v5", "v6", "v7", "v8", "v11"), default="v1")
    parser.add_argument("--blend-path")
    parser.add_argument("--sentinel", required=True)
    return parser.parse_args(argv)


args = parse_args()
if args.blend_path:
    bpy.ops.wm.open_mainfile(filepath=str(Path(args.blend_path).resolve()))
required_bones_v1 = {
    "root", "spine", "head", "jaw", "tail_01", "tail_02",
    "arm_L_upper", "arm_L_lower", "hand_L", "arm_R_upper", "arm_R_lower", "hand_R",
    "leg_L_upper", "leg_L_lower", "foot_L", "leg_R_upper", "leg_R_lower", "foot_R",
}
required_bones_v2 = {
    "root", "spine", "neck", "head", "jaw", "tail",
    "leg_FL", "paw_FL", "leg_FR", "paw_FR",
    "leg_BL", "paw_BL", "leg_BR", "paw_BR",
}
required_bones_v3 = {
    "root", "spine", "chest", "head", "ear_L", "ear_R", "tail",
    "upper_arm_L", "forearm_L", "hand_L", "upper_arm_R", "forearm_R", "hand_R",
    "upper_leg_L", "lower_leg_L", "foot_L", "upper_leg_R", "lower_leg_R", "foot_R",
}
required_bones_v4 = {"root", "body", "head", "muzzle", "ear_L", "ear_R", "paw_L", "paw_R", "tail"}
required_bones_by_version = {
    "v1": required_bones_v1,
    "v2": required_bones_v2,
    "v3": required_bones_v3,
    "v4": required_bones_v4,
    "v5": required_bones_v4,
    "v6": required_bones_v4,
    "v7": required_bones_v4,
    "v8": required_bones_v4,
    "v11": required_bones_v4,
}
required_bones = required_bones_by_version[args.expected_model_version]
required_actions_legacy = {
    "Pipilabu_Idle", "Pipilabu_Receive", "Pipilabu_Hold", "Pipilabu_TurnLeave",
}
required_actions_v3 = {"Pipilabu_Idle", "Pipilabu_Walk", "Pipilabu_Carry", "Pipilabu_Serve", "Pipilabu_Happy"}
required_actions_v4_owner = {"Pipilabu_Idle", "Pipilabu_Talk", "Pipilabu_Serve", "Pipilabu_Happy", "Pipilabu_Stressed"}
required_actions_v4_customer = {"Pipilabu_Idle", "Pipilabu_Receive", "Pipilabu_Hold", "Pipilabu_Happy", "Pipilabu_TurnLeave", "Pipilabu_Run"}
if args.expected_model_version in {"v4", "v5", "v6", "v7", "v8", "v11"}:
    required_actions = required_actions_v4_customer if args.expected_variant == "customer" else required_actions_v4_owner
elif args.expected_model_version == "v3":
    required_actions = required_actions_v3
else:
    required_actions = required_actions_legacy
required_attachments = {
    "ATTACH_Fruit_R", "ATTACH_Fruit_L", "ATTACH_Mouth", "ATTACH_Back",
    "ATTACH_ShopkeeperProp", "ATTACH_OrderBillboard",
}

assert bpy.data.filepath, "No .blend file is open"
rigs = [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
assert len(rigs) == 1, f"Expected one armature, found {len(rigs)}"
rig = rigs[0]
assert rig.get("variant") == args.expected_variant, (rig.get("variant"), args.expected_variant)
if args.expected_model_version in {"v2", "v3", "v4", "v5", "v6", "v7", "v8", "v11"}:
    assert rig.get("model_version") == args.expected_model_version, rig.get("model_version")
if args.expected_model_version in {"v4", "v5", "v6", "v7", "v8", "v11"}:
    assert args.expected_variant in {"owner", "customer"}, "v4-v11 are scoped to Pipi Labu NPCs"
    assert rig.get("player_character") is False, "Peepilabu must not be marked as the player"
    expected_kind = "PeepilabuCustomerNPC" if args.expected_variant == "customer" else "PeepilabuOwnerHeroNPC"
    assert rig.get("character_kind") == expected_kind, (rig.get("character_kind"), expected_kind)
assert required_bones == set(rig.data.bones.keys()), "Bone contract mismatch"
assert required_actions.issubset(bpy.data.actions.keys()), "Action contract mismatch"
assert all(len(action.fcurves) > 0 for action in bpy.data.actions), "Empty action found"
assert required_attachments.issubset(bpy.context.scene.objects.keys()), "Attachment contract mismatch"
assert "COLLISION_ROOT" in bpy.context.scene.objects, "Missing collision guide"

meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH" and not obj.name.startswith("PREVIEW_")]
assert meshes, "No mesh objects"
for obj in meshes:
    is_skinned_body = bool(obj.get("fused_surface")) or (args.expected_model_version in {"v8", "v11"} and obj.name == "MainFusedBody")
    if is_skinned_body:
        assert len(obj.vertex_groups) >= 1, f"{obj.name} should expose at least one skinned body group"
        for vertex in obj.data.vertices:
            assert len(vertex.groups) <= 3, f"{obj.name} vertex {vertex.index} exceeds three influences"
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        unseen = set(bm.verts)
        components = 0
        while unseen:
            components += 1
            stack = [unseen.pop()]
            while stack:
                current = stack.pop()
                for edge in current.link_edges:
                    neighbor = edge.other_vert(current)
                    if neighbor in unseen:
                        unseen.remove(neighbor)
                        stack.append(neighbor)
        assert components == 1, f"{obj.name} has {components} disconnected shells"
        assert all(edge.is_manifold for edge in bm.edges), f"{obj.name} is not watertight/manifold"
        body_triangles = sum(len(poly.vertices) - 2 for poly in obj.data.polygons)
        assert body_triangles <= 20_000, f"{obj.name} exceeds 20k triangles: {body_triangles}"
        bm.free()
    else:
        assert len(obj.vertex_groups) == 1, f"{obj.name} should have one rigid influence group"
    assert any(mod.type == "ARMATURE" and mod.object == rig for mod in obj.modifiers), f"{obj.name} lacks rig modifier"

surface_maps = {}
if args.expected_model_version in {"v4", "v5", "v6", "v7", "v8", "v11"}:
    body = bpy.context.scene.objects["MainFusedBody"]
    surface_maps = json.loads(body.get("surface_maps", "{}"))
    assert set(surface_maps) == {"colormap", "normalmap", "roughnessmap", "metalnessmap"}, surface_maps
    model_dir = Path(bpy.data.filepath).parent
    for map_name in surface_maps.values():
        map_path = model_dir / map_name
        assert map_path.is_file() and map_path.stat().st_size > 10_000, f"Missing/small surface map: {map_path}"
    if args.expected_model_version in {"v5", "v6", "v7", "v8", "v11"}:
        if args.expected_model_version == "v5":
            assert "market-video frames" in body.get("visual_reference", ""), body.get("visual_reference")
        elif args.expected_model_version == "v8":
            assert "original-video silhouette lock" in body.get("visual_reference", ""), body.get("visual_reference")
            assert "No top-ear geometry" in body.get("top_ear_policy", ""), body.get("top_ear_policy")
        elif args.expected_model_version == "v11":
            assert "owner-reconstruction-sheet-v11" in body.get("visual_reference", ""), body.get("visual_reference")
            assert "No ear geometry" in body.get("top_ear_policy", ""), body.get("top_ear_policy")
            assert "No tail geometry" in body.get("tail_policy", ""), body.get("tail_policy")
        material = body.data.materials[0]
        assert material.get("baked_colormap_review_required") is False
        assert material.get("baked_normalmap_review_required") is False

fbx_path = Path(bpy.data.filepath).with_suffix(".fbx")
assert fbx_path.is_file(), f"Missing {fbx_path}"
assert fbx_path.stat().st_size > 100_000, f"Suspiciously small FBX: {fbx_path.stat().st_size}"
if args.expected_model_version in {"v5", "v6", "v7", "v8", "v11"}:
    for action_name in required_actions:
        action_path = fbx_path.parent / f"{fbx_path.stem}.{action_name.removeprefix('Pipilabu_').lower()}.fbx"
        assert action_path.is_file() and action_path.stat().st_size > 100_000, f"Missing/small action FBX: {action_path}"

result = {
    "status": "ok",
    "blend": str(Path(bpy.data.filepath)),
    "fbx": str(fbx_path),
    "variant": args.expected_variant,
    "model_version": args.expected_model_version,
    "meshes": len(meshes),
    "bones": len(rig.data.bones),
    "actions": sorted(bpy.data.actions.keys()),
    "attachments": sorted(required_attachments),
    "surface_maps": surface_maps if args.expected_model_version in {"v4", "v5", "v6", "v7", "v8", "v11"} else {},
}
sentinel = Path(args.sentinel).resolve()
sentinel.parent.mkdir(parents=True, exist_ok=True)
sentinel.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print("PIPILABU_VERIFY_OK " + json.dumps(result, sort_keys=True))
