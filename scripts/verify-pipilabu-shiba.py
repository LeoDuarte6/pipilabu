"""Headless structural checks for a generated Pipilabu Shiba .blend file."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import bpy


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--expected-variant", choices=("customer", "owner"), required=True)
    parser.add_argument("--sentinel", required=True)
    return parser.parse_args(argv)


args = parse_args()
required_bones = {
    "root", "spine", "head", "jaw", "tail_01", "tail_02",
    "arm_L_upper", "arm_L_lower", "hand_L", "arm_R_upper", "arm_R_lower", "hand_R",
    "leg_L_upper", "leg_L_lower", "foot_L", "leg_R_upper", "leg_R_lower", "foot_R",
}
required_actions = {
    "Pipilabu_Idle", "Pipilabu_Receive", "Pipilabu_Hold", "Pipilabu_TurnLeave",
}
required_attachments = {
    "ATTACH_Fruit_R", "ATTACH_Fruit_L", "ATTACH_Mouth", "ATTACH_Back",
    "ATTACH_ShopkeeperProp", "ATTACH_OrderBillboard",
}

assert bpy.data.filepath, "No .blend file is open"
rigs = [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
assert len(rigs) == 1, f"Expected one armature, found {len(rigs)}"
rig = rigs[0]
assert rig.get("variant") == args.expected_variant, (rig.get("variant"), args.expected_variant)
assert required_bones == set(rig.data.bones.keys()), "Bone contract mismatch"
assert required_actions.issubset(bpy.data.actions.keys()), "Action contract mismatch"
assert all(len(action.fcurves) > 0 for action in bpy.data.actions), "Empty action found"
assert required_attachments.issubset(bpy.context.scene.objects.keys()), "Attachment contract mismatch"
assert "COLLISION_ROOT" in bpy.context.scene.objects, "Missing collision guide"

meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
assert meshes, "No mesh objects"
for obj in meshes:
    assert len(obj.vertex_groups) == 1, f"{obj.name} should have one rigid influence group"
    assert any(mod.type == "ARMATURE" and mod.object == rig for mod in obj.modifiers), f"{obj.name} lacks rig modifier"

fbx_path = Path(bpy.data.filepath).with_suffix(".fbx")
assert fbx_path.is_file(), f"Missing {fbx_path}"
assert fbx_path.stat().st_size > 100_000, f"Suspiciously small FBX: {fbx_path.stat().st_size}"

result = {
    "status": "ok",
    "blend": str(Path(bpy.data.filepath)),
    "fbx": str(fbx_path),
    "variant": args.expected_variant,
    "meshes": len(meshes),
    "bones": len(rig.data.bones),
    "actions": sorted(bpy.data.actions.keys()),
    "attachments": sorted(required_attachments),
}
sentinel = Path(args.sentinel).resolve()
sentinel.parent.mkdir(parents=True, exist_ok=True)
sentinel.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print("PIPILABU_VERIFY_OK " + json.dumps(result, sort_keys=True))
