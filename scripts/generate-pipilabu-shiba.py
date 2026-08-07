"""Build an original low-poly Pipilabu Shiba NPC and export Blender + FBX files.

Run with Blender, not the system Python. Arguments after ``--`` are handled here.
The geometry is deliberately procedural and original; no external mesh is imported.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


SCRIPT_VERSION = "1.0.0"
VARIANT_SCALES = {"customer": 1.0, "owner": 1.65}


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--variant", choices=sorted(VARIANT_SCALES), default="customer")
    parser.add_argument("--output-dir", required=True)
    return parser.parse_args(argv)


ARGS = parse_args()
VARIANT = ARGS.variant
SCALE = VARIANT_SCALES[VARIANT]
OUTPUT_DIR = Path(ARGS.output_dir).resolve()
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
STEM = f"pipilabu_shiba_{VARIANT}_v1"


def reset_scene() -> None:
    bpy.ops.object.mode_set(mode="OBJECT") if bpy.context.object and bpy.context.object.mode != "OBJECT" else None
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.armatures, bpy.data.materials, bpy.data.actions):
        for datablock in list(datablocks):
            datablocks.remove(datablock)


def make_material(name: str, rgba: tuple[float, float, float, float], roughness: float = 0.72) -> bpy.types.Material:
    material = bpy.data.materials.new(name)
    material.diffuse_color = rgba
    material.use_nodes = True
    principled = material.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = rgba
    principled.inputs["Roughness"].default_value = roughness
    return material


def apply_transform(obj: bpy.types.Object) -> None:
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.select_set(False)


def weight_to_bone(obj: bpy.types.Object, armature: bpy.types.Object, bone_name: str) -> None:
    group = obj.vertex_groups.new(name=bone_name)
    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    modifier = obj.modifiers.new(name="Armature", type="ARMATURE")
    modifier.object = armature
    obj.parent = armature
    obj["deforms_with"] = bone_name


def finish_mesh(obj: bpy.types.Object, name: str, material: bpy.types.Material, armature: bpy.types.Object, bone: str) -> bpy.types.Object:
    obj.name = name
    obj.data.name = f"{name}_Mesh"
    apply_transform(obj)
    obj.data.materials.append(material)
    weight_to_bone(obj, armature, bone)
    return obj


def uv_sphere(name: str, location: tuple[float, float, float], scale: tuple[float, float, float], material: bpy.types.Material, armature: bpy.types.Object, bone: str, segments: int = 12, rings: int = 8) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=tuple(v * SCALE for v in location))
    obj = bpy.context.object
    obj.scale = tuple(v * SCALE for v in scale)
    return finish_mesh(obj, name, material, armature, bone)


def cube(name: str, location: tuple[float, float, float], scale: tuple[float, float, float], material: bpy.types.Material, armature: bpy.types.Object, bone: str, bevel: float = 0.08) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(location=tuple(v * SCALE for v in location))
    obj = bpy.context.object
    obj.scale = tuple(v * SCALE for v in scale)
    apply_transform(obj)
    modifier = obj.modifiers.new(name="Soft corners", type="BEVEL")
    modifier.width = bevel * SCALE
    modifier.segments = 2
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    return finish_mesh(obj, name, material, armature, bone)


def cone(name: str, location: tuple[float, float, float], scale: tuple[float, float, float], material: bpy.types.Material, armature: bpy.types.Object, bone: str) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=1.0, radius2=0.15, depth=2.0, location=tuple(v * SCALE for v in location))
    obj = bpy.context.object
    obj.scale = tuple(v * SCALE for v in scale)
    obj.rotation_euler[2] = math.radians(45)
    return finish_mesh(obj, name, material, armature, bone)


def cylinder_between(name: str, start: tuple[float, float, float], end: tuple[float, float, float], radius: float, material: bpy.types.Material, armature: bpy.types.Object, bone: str) -> bpy.types.Object:
    p0 = Vector(start) * SCALE
    p1 = Vector(end) * SCALE
    direction = p1 - p0
    bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=radius * SCALE, depth=direction.length, location=(p0 + p1) * 0.5)
    obj = bpy.context.object
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = direction.to_track_quat("Z", "Y")
    obj.rotation_mode = "XYZ"
    return finish_mesh(obj, name, material, armature, bone)


def build_armature() -> bpy.types.Object:
    data = bpy.data.armatures.new("PipilabuShiba_Rig")
    rig = bpy.data.objects.new("PipilabuShiba_Rig", data)
    bpy.context.collection.objects.link(rig)
    rig.show_in_front = True
    rig.display_type = "WIRE"
    rig["rig_version"] = SCRIPT_VERSION
    rig["character_kind"] = "OriginalShibaNPC"
    rig["variant"] = VARIANT
    rig["customer_scale"] = VARIANT_SCALES["customer"]
    rig["owner_scale"] = VARIANT_SCALES["owner"]
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")

    def bone(name: str, head: tuple[float, float, float], tail: tuple[float, float, float], parent: str | None = None) -> None:
        edit_bone = data.edit_bones.new(name)
        edit_bone.head = Vector(head) * SCALE
        edit_bone.tail = Vector(tail) * SCALE
        if parent:
            edit_bone.parent = data.edit_bones[parent]

    bone("root", (0, 0, 0.06), (0, 0, 0.38))
    bone("spine", (0, 0, 0.38), (0, 0, 1.82), "root")
    bone("head", (0, 0, 1.82), (0, -0.02, 2.62), "spine")
    bone("jaw", (0, -0.34, 2.26), (0, -0.75, 2.20), "head")
    bone("tail_01", (0, 0.52, 1.46), (0, 0.88, 1.84), "spine")
    bone("tail_02", (0, 0.88, 1.84), (0.24, 0.98, 2.15), "tail_01")

    for side, x in (("L", -0.43), ("R", 0.43)):
        bone(f"arm_{side}_upper", (x, -0.13, 1.65), (x, -0.23, 1.11), "spine")
        bone(f"arm_{side}_lower", (x, -0.23, 1.11), (x, -0.42, 0.78), f"arm_{side}_upper")
        bone(f"hand_{side}", (x, -0.42, 0.78), (x, -0.58, 0.57), f"arm_{side}_lower")
        bone(f"leg_{side}_upper", (x * 0.78, 0.18, 0.84), (x * 0.78, 0.17, 0.47), "root")
        bone(f"leg_{side}_lower", (x * 0.78, 0.17, 0.47), (x * 0.78, -0.04, 0.20), f"leg_{side}_upper")
        bone(f"foot_{side}", (x * 0.78, -0.04, 0.20), (x * 0.78, -0.34, 0.14), f"leg_{side}_lower")

    bpy.ops.object.mode_set(mode="OBJECT")
    rig.select_set(False)
    return rig


def bone_empty(name: str, rig: bpy.types.Object, bone: str, location: tuple[float, float, float], display: str = "ARROWS", size: float = 0.12) -> bpy.types.Object:
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.empty_display_type = display
    obj.empty_display_size = size * SCALE
    obj.parent = rig
    obj.parent_type = "BONE"
    obj.parent_bone = bone
    # Bone-parented transforms are expressed relative to the bone tail in Blender.
    obj.matrix_parent_inverse = rig.matrix_world.inverted()
    obj.location = Vector(location) * SCALE
    obj["roblox_attachment"] = True
    obj["attachment_bone"] = bone
    return obj


def build_meshes(rig: bpy.types.Object) -> None:
    fur = make_material("MAT_Fur_Golden", (0.78, 0.34, 0.105, 1.0))
    fur_dark = make_material("MAT_Fur_Shadow", (0.39, 0.12, 0.045, 1.0))
    cream = make_material("MAT_Cream", (0.98, 0.77, 0.48, 1.0))
    dark = make_material("MAT_Features", (0.035, 0.023, 0.018, 1.0), 0.45)
    pink = make_material("MAT_Mouth", (0.75, 0.12, 0.17, 1.0), 0.55)

    uv_sphere("Body", (0, 0.03, 1.25), (0.68, 0.49, 0.84), fur, rig, "spine")
    uv_sphere("ChestPatch", (0, -0.43, 1.30), (0.42, 0.09, 0.56), cream, rig, "spine")
    uv_sphere("Head", (0, -0.03, 2.17), (0.76, 0.61, 0.66), fur, rig, "head")
    uv_sphere("Cheek_L", (-0.37, -0.50, 2.04), (0.38, 0.24, 0.30), cream, rig, "head", 10, 6)
    uv_sphere("Cheek_R", (0.37, -0.50, 2.04), (0.38, 0.24, 0.30), cream, rig, "head", 10, 6)
    uv_sphere("Muzzle", (0, -0.61, 2.05), (0.43, 0.26, 0.29), cream, rig, "jaw", 10, 6)
    uv_sphere("Nose", (0, -0.84, 2.18), (0.17, 0.105, 0.115), dark, rig, "head", 10, 6)
    cube("Mouth", (0, -0.79, 1.96), (0.12, 0.025, 0.035), pink, rig, "jaw", 0.025)
    uv_sphere("Eye_L", (-0.27, -0.57, 2.35), (0.09, 0.055, 0.12), dark, rig, "head", 10, 6)
    uv_sphere("Eye_R", (0.27, -0.57, 2.35), (0.09, 0.055, 0.12), dark, rig, "head", 10, 6)
    uv_sphere("EyeGlint_L", (-0.245, -0.622, 2.39), (0.022, 0.012, 0.027), cream, rig, "head", 8, 4)
    uv_sphere("EyeGlint_R", (0.295, -0.622, 2.39), (0.022, 0.012, 0.027), cream, rig, "head", 8, 4)
    cone("Ear_L", (-0.40, -0.01, 2.77), (0.26, 0.22, 0.37), fur_dark, rig, "head")
    cone("Ear_R", (0.40, -0.01, 2.77), (0.26, 0.22, 0.37), fur_dark, rig, "head")

    for side, x in (("L", -0.43), ("R", 0.43)):
        cylinder_between(f"Arm_{side}_Upper", (x, -0.13, 1.64), (x, -0.23, 1.10), 0.19, fur, rig, f"arm_{side}_upper")
        cylinder_between(f"Arm_{side}_Lower", (x, -0.23, 1.10), (x, -0.42, 0.77), 0.17, cream, rig, f"arm_{side}_lower")
        uv_sphere(f"Hand_{side}", (x, -0.54, 0.66), (0.22, 0.21, 0.22), cream, rig, f"hand_{side}", 10, 6)
        lx = x * 0.78
        cylinder_between(f"Leg_{side}_Upper", (lx, 0.18, 0.83), (lx, 0.17, 0.46), 0.22, fur, rig, f"leg_{side}_upper")
        cylinder_between(f"Leg_{side}_Lower", (lx, 0.17, 0.46), (lx, -0.04, 0.20), 0.19, cream, rig, f"leg_{side}_lower")
        cube(f"Foot_{side}", (lx, -0.25, 0.16), (0.26, 0.36, 0.15), cream, rig, f"foot_{side}", 0.10)

    cylinder_between("Tail_Base", (0, 0.52, 1.46), (0, 0.88, 1.84), 0.25, fur, rig, "tail_01")
    cylinder_between("Tail_Curl", (0, 0.88, 1.84), (0.24, 0.98, 2.15), 0.20, cream, rig, "tail_02")
    uv_sphere("Tail_Tip", (0.25, 0.98, 2.16), (0.22, 0.22, 0.24), cream, rig, "tail_02", 10, 6)


def build_markers(rig: bpy.types.Object) -> None:
    marker = bpy.data.objects.new("COLLISION_ROOT", None)
    bpy.context.collection.objects.link(marker)
    marker.empty_display_type = "CUBE"
    marker.empty_display_size = 1.0 * SCALE
    marker.scale = (0.58, 0.43, 1.38)
    marker.location = (0, 0, 1.38 * SCALE)
    marker.parent = rig
    marker["roblox_collision_proxy"] = True
    marker["recommended_can_collide"] = False

    bone_empty("ATTACH_Fruit_R", rig, "hand_R", (0, -0.12, 0.02), "SPHERE", 0.11)
    bone_empty("ATTACH_Fruit_L", rig, "hand_L", (0, -0.12, 0.02), "SPHERE", 0.11)
    bone_empty("ATTACH_Mouth", rig, "head", (0, -0.78, 2.08), "ARROWS", 0.10)
    bone_empty("ATTACH_Back", rig, "spine", (0, 0.54, 1.50), "ARROWS", 0.12)
    bone_empty("ATTACH_ShopkeeperProp", rig, "hand_L", (0, -0.18, 0.04), "CUBE", 0.12)
    bone_empty("ATTACH_OrderBillboard", rig, "head", (0, 0, 3.12), "PLAIN_AXES", 0.14)


def reset_pose(rig: bpy.types.Object) -> None:
    for pose_bone in rig.pose.bones:
        pose_bone.rotation_mode = "XYZ"
        pose_bone.location = (0, 0, 0)
        pose_bone.rotation_euler = (0, 0, 0)
        pose_bone.scale = (1, 1, 1)


def make_action(rig: bpy.types.Object, name: str, last_frame: int, poses: dict[int, dict[str, dict[str, tuple[float, float, float]]]]) -> None:
    action = bpy.data.actions.new(name=name)
    action.use_fake_user = True
    action["clip_role"] = name.removeprefix("Pipilabu_")
    action["frame_start"] = 1
    action["frame_end"] = last_frame
    rig.animation_data.action = action
    reset_pose(rig)
    for frame, bones in poses.items():
        for bone_name, channels in bones.items():
            pose_bone = rig.pose.bones[bone_name]
            for channel, value in channels.items():
                setattr(pose_bone, channel, value)
                pose_bone.keyframe_insert(data_path=channel, frame=frame, group=bone_name)
    rig.animation_data.action = None


def build_actions(rig: bpy.types.Object) -> None:
    rig.animation_data_create()
    make_action(rig, "Pipilabu_Idle", 40, {
        1: {"spine": {"location": (0, 0, 0)}, "head": {"rotation_euler": (0, 0, -0.05)}, "tail_02": {"rotation_euler": (0, 0.10, -0.16)}},
        20: {"spine": {"location": (0, 0, 0.035 * SCALE)}, "head": {"rotation_euler": (0.035, 0, 0.05)}, "tail_02": {"rotation_euler": (0, -0.10, 0.16)}},
        40: {"spine": {"location": (0, 0, 0)}, "head": {"rotation_euler": (0, 0, -0.05)}, "tail_02": {"rotation_euler": (0, 0.10, -0.16)}},
    })
    make_action(rig, "Pipilabu_Receive", 30, {
        1: {"arm_L_upper": {"rotation_euler": (0, 0, 0)}, "arm_R_upper": {"rotation_euler": (0, 0, 0)}, "jaw": {"rotation_euler": (0, 0, 0)}},
        12: {"spine": {"rotation_euler": (math.radians(-8), 0, 0)}, "arm_L_upper": {"rotation_euler": (math.radians(-62), 0, math.radians(-8))}, "arm_R_upper": {"rotation_euler": (math.radians(-62), 0, math.radians(8))}, "arm_L_lower": {"rotation_euler": (math.radians(-28), 0, 0)}, "arm_R_lower": {"rotation_euler": (math.radians(-28), 0, 0)}, "jaw": {"rotation_euler": (math.radians(12), 0, 0)}},
        20: {"spine": {"rotation_euler": (math.radians(3), 0, 0)}, "arm_L_upper": {"rotation_euler": (math.radians(-45), 0, math.radians(-5))}, "arm_R_upper": {"rotation_euler": (math.radians(-45), 0, math.radians(5))}, "jaw": {"rotation_euler": (0, 0, 0)}},
        30: {"arm_L_upper": {"rotation_euler": (math.radians(-42), 0, 0)}, "arm_R_upper": {"rotation_euler": (math.radians(-42), 0, 0)}},
    })
    make_action(rig, "Pipilabu_Hold", 40, {
        1: {"arm_L_upper": {"rotation_euler": (math.radians(-42), 0, math.radians(-7))}, "arm_R_upper": {"rotation_euler": (math.radians(-42), 0, math.radians(7))}, "head": {"rotation_euler": (0.08, 0, -0.06)}},
        20: {"arm_L_upper": {"rotation_euler": (math.radians(-46), 0, math.radians(-7))}, "arm_R_upper": {"rotation_euler": (math.radians(-46), 0, math.radians(7))}, "head": {"rotation_euler": (0.03, 0, 0.06)}, "tail_02": {"rotation_euler": (0, 0, 0.18)}},
        40: {"arm_L_upper": {"rotation_euler": (math.radians(-42), 0, math.radians(-7))}, "arm_R_upper": {"rotation_euler": (math.radians(-42), 0, math.radians(7))}, "head": {"rotation_euler": (0.08, 0, -0.06)}},
    })
    make_action(rig, "Pipilabu_TurnLeave", 48, {
        1: {"root": {"location": (0, 0, 0), "rotation_euler": (0, 0, 0)}},
        16: {"root": {"location": (0, 0, 0), "rotation_euler": (0, 0, math.radians(90))}, "head": {"rotation_euler": (0, 0, math.radians(-16))}},
        32: {"root": {"location": (0.75 * SCALE, 0, 0), "rotation_euler": (0, 0, math.radians(90))}, "leg_L_upper": {"rotation_euler": (math.radians(20), 0, 0)}, "leg_R_upper": {"rotation_euler": (math.radians(-20), 0, 0)}},
        48: {"root": {"location": (1.55 * SCALE, 0, 0), "rotation_euler": (0, 0, math.radians(90))}, "leg_L_upper": {"rotation_euler": (math.radians(-20), 0, 0)}, "leg_R_upper": {"rotation_euler": (math.radians(20), 0, 0)}},
    })
    reset_pose(rig)


def collect_metrics(rig: bpy.types.Object) -> dict[str, object]:
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    return {
        "generator_version": SCRIPT_VERSION,
        "blender_version": bpy.app.version_string,
        "variant": VARIANT,
        "scale_multiplier": SCALE,
        "mesh_objects": len(meshes),
        "vertices": sum(len(obj.data.vertices) for obj in meshes),
        "triangles": sum(len(poly.vertices) - 2 for obj in meshes for poly in obj.data.polygons),
        "bones": len(rig.data.bones),
        "actions": sorted(action.name for action in bpy.data.actions),
        "attachments": sorted(obj.name for obj in bpy.context.scene.objects if obj.name.startswith("ATTACH_")),
        "collision_marker": "COLLISION_ROOT",
        "bounds_meters_approx": [round(1.75 * SCALE, 3), round(2.05 * SCALE, 3), round(3.15 * SCALE, 3)],
    }


def render_preview() -> Path:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 640
    scene.render.resolution_y = 640
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False

    world = bpy.data.worlds.new("PipilabuPreviewWorld") if not scene.world else scene.world
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.055, 0.075, 0.095, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.32

    target = Vector((0, 0, 1.52 * SCALE))
    camera_data = bpy.data.cameras.new("PREVIEW_Camera")
    camera = bpy.data.objects.new("PREVIEW_Camera", camera_data)
    bpy.context.collection.objects.link(camera)
    camera.location = Vector((4.2, -7.8, 3.8)) * SCALE
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera_data.lens = 57
    scene.camera = camera

    for name, location, energy, size, color in (
        ("PREVIEW_Key", (-4.5, -4.0, 6.2), 1050, 4.0, (1.0, 0.78, 0.58)),
        ("PREVIEW_Fill", (4.8, -2.2, 4.2), 750, 3.0, (0.48, 0.68, 1.0)),
        ("PREVIEW_Rim", (0, 4.5, 5.0), 900, 3.0, (1.0, 0.42, 0.22)),
    ):
        light_data = bpy.data.lights.new(name, type="AREA")
        light_data.energy = energy
        light_data.shape = "DISK"
        light_data.size = size * SCALE
        light_data.color = color
        light = bpy.data.objects.new(name, light_data)
        bpy.context.collection.objects.link(light)
        light.location = Vector(location) * SCALE
        light.rotation_euler = (target - light.location).to_track_quat("-Z", "Y").to_euler()

    preview_path = OUTPUT_DIR / f"{STEM}.preview.png"
    scene.render.filepath = str(preview_path)
    bpy.ops.render.render(write_still=True)
    return preview_path


def save_and_export(rig: bpy.types.Object) -> dict[str, object]:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.frame_start = 1
    scene.frame_end = 48
    scene.render.fps = 24
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    scene["pipilabu_generator_version"] = SCRIPT_VERSION
    scene["asset_rights"] = "Original procedural geometry; no external meshes"
    scene["variant_usage"] = "customer=1.0; owner=1.65"

    blend_path = OUTPUT_DIR / f"{STEM}.blend"
    fbx_path = OUTPUT_DIR / f"{STEM}.fbx"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.fbx(
        filepath=str(fbx_path),
        use_selection=True,
        object_types={"ARMATURE", "MESH", "EMPTY"},
        apply_scale_options="FBX_SCALE_UNITS",
        use_space_transform=True,
        add_leaf_bones=False,
        use_armature_deform_only=True,
        bake_anim=True,
        bake_anim_use_all_bones=True,
        bake_anim_use_nla_strips=False,
        bake_anim_use_all_actions=True,
        bake_anim_force_startend_keying=True,
        path_mode="AUTO",
        embed_textures=False,
    )
    metrics = collect_metrics(rig)
    metrics["blend_file"] = blend_path.name
    metrics["fbx_file"] = fbx_path.name
    metrics["blend_bytes"] = blend_path.stat().st_size
    metrics["fbx_bytes"] = fbx_path.stat().st_size
    preview_path = OUTPUT_DIR / f"{STEM}.preview.png"
    if preview_path.is_file():
        metrics["preview_file"] = preview_path.name
        metrics["preview_bytes"] = preview_path.stat().st_size
    metrics_path = OUTPUT_DIR / f"{STEM}.metrics.json"
    metrics_path.write_text(json.dumps(metrics, indent=2) + "\n", encoding="utf-8")
    return metrics


def main() -> None:
    reset_scene()
    rig = build_armature()
    build_meshes(rig)
    build_markers(rig)
    build_actions(rig)
    render_preview()
    metrics = save_and_export(rig)
    print("PIPILABU_EXPORT_OK " + json.dumps(metrics, sort_keys=True))


main()
