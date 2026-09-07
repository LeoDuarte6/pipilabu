"""Build an original low-poly Pipilabu Shiba NPC and export Blender + FBX files.

Run with Blender, not the system Python. Arguments after ``--`` are handled here.
The geometry is deliberately procedural and original; no external mesh is imported.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Vector


SCRIPT_VERSION = "3.5.1"
VARIANT_SCALES = {"customer": 1.0, "owner": 1.65, "player": 1.0}


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--variant", choices=sorted(VARIANT_SCALES), default="customer")
    parser.add_argument("--model-version", choices=("v1", "v2", "v3", "v4", "v5", "v6", "v7", "v8", "v11"), default="v1")
    parser.add_argument("--output-dir", required=True)
    return parser.parse_args(argv)


ARGS = parse_args()
VARIANT = ARGS.variant
MODEL_VERSION = ARGS.model_version
SCALE = VARIANT_SCALES[VARIANT]
OUTPUT_DIR = Path(ARGS.output_dir).resolve()
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
STEM = f"pipilabu_shiba_{VARIANT}_{MODEL_VERSION}"


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
    ior_level = principled.inputs.get("IOR Level")
    if ior_level and roughness >= 0.85:
        ior_level.default_value = 0.0
    coat_weight = principled.inputs.get("Coat Weight")
    if coat_weight and roughness >= 0.85:
        coat_weight.default_value = 0.0
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


def smooth_uv_shell(
    name: str,
    location: tuple[float, float, float],
    scale: tuple[float, float, float],
    material: bpy.types.Material,
    armature: bpy.types.Object,
    bone: str,
    segments: int = 72,
    rings: int = 48,
) -> bpy.types.Object:
    """Create a Roblox-stable smooth shell without voxel remesh terracing.

    The v6/v7 implicit blob surface looked smooth in Blender because its render
    normals concealed the decimated voxel rings. Roblox recomputed those normals
    and exposed the rings. A dense, regular UV shell keeps the silhouette and
    vertex normals deterministic in both renderers while remaining below the
    20k-triangle per-mesh import limit.
    """
    obj = uv_sphere(name, location, scale, material, armature, bone, segments, rings)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    obj.select_set(False)
    return obj


def apply_vertex_color_material(
    obj: bpy.types.Object,
    base_material: bpy.types.Material,
    cream_material: bpy.types.Material,
    cream_resolver,
) -> bpy.types.Material:
    """Paint a soft coat mask directly on a regular shell for PBR baking."""
    material = bpy.data.materials.new(f"MAT_{obj.name}_VertexBlend")
    material.use_nodes = True
    material.diffuse_color = base_material.diffuse_color
    principled = material.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Roughness"].default_value = 0.94
    color_node = material.node_tree.nodes.new("ShaderNodeVertexColor")
    color_node.layer_name = "PipilabuColor"
    material.node_tree.links.new(color_node.outputs["Color"], principled.inputs["Base Color"])
    obj.data.materials.clear()
    obj.data.materials.append(material)

    color_attribute = obj.data.color_attributes.new(name="PipilabuColor", type="BYTE_COLOR", domain="CORNER")
    base_rgb = Vector(base_material.diffuse_color[:3])
    cream_rgb = Vector(cream_material.diffuse_color[:3])
    for loop in obj.data.loops:
        world_position = (obj.matrix_world @ obj.data.vertices[loop.vertex_index].co) / SCALE
        cream_amount = max(0.0, min(1.0, float(cream_resolver(world_position))))
        color = base_rgb.lerp(cream_rgb, cream_amount)
        color_attribute.data[loop.index].color = (*color, 1.0)
    obj.data.update()
    return material


def add_short_coat_surface(obj: bpy.types.Object, amplitude: float = 0.0032) -> None:
    """Break a perfect primitive highlight with regular-topology coat grain."""
    for vertex in obj.data.vertices:
        p = vertex.co / SCALE
        grain = (
            math.sin(p.x * 43.0 + p.y * 17.0 + p.z * 31.0)
            + 0.45 * math.sin(p.x * 79.0 - p.y * 37.0 + p.z * 53.0)
        ) / 1.45
        vertex.co += vertex.normal * (amplitude * SCALE * grain)
    obj.data.update()
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    obj.select_set(False)


def shape_customer_shell(obj: bpy.types.Object) -> None:
    """Pull a regular ellipsoid into one continuous belly-low head/body mass."""
    for vertex in obj.data.vertices:
        world_y = (obj.location.y + vertex.co.y) / SCALE
        amount = max(0.0, min(1.0, (-world_y - 0.18) / 0.60))
        amount = amount * amount * (3.0 - 2.0 * amount)
        vertex.co.x *= 1.0 + 0.16 * amount
        vertex.co.z *= 1.0 + 0.42 * amount
        vertex.co.z += 0.075 * SCALE * amount
    obj.data.update()

    body_group = obj.vertex_groups.get("body")
    if body_group:
        obj.vertex_groups.remove(body_group)
    head_group = obj.vertex_groups.get("head") or obj.vertex_groups.new(name="head")
    body_group = obj.vertex_groups.new(name="body")
    for vertex in obj.data.vertices:
        world_y = (obj.location.y + vertex.co.y) / SCALE
        head_weight = max(0.0, min(1.0, (-world_y - 0.10) / 0.72))
        head_weight = head_weight * head_weight * (3.0 - 2.0 * head_weight)
        if head_weight > 0.0:
            head_group.add([vertex.index], head_weight, "REPLACE")
        if head_weight < 1.0:
            body_group.add([vertex.index], 1.0 - head_weight, "REPLACE")

    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    obj.select_set(False)


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


def rounded_ear(
    name: str,
    center_x: float,
    material: bpy.types.Material,
    armature: bpy.types.Object,
    bone: str,
    inner_material: bpy.types.Material | None = None,
) -> bpy.types.Object:
    """Build a compact beveled Shiba ear instead of a hard pyramid spike."""
    sign = -1 if center_x < 0 else 1
    outline = [
        (center_x - 0.19, 2.18),
        (center_x - 0.13, 2.39),
        (center_x - 0.035 * sign, 2.52),
        (center_x + 0.13, 2.39),
        (center_x + 0.19, 2.18),
    ]
    depth_front = -0.09
    depth_back = 0.10
    vertices = [(x * SCALE, depth_front * SCALE, z * SCALE) for x, z in outline]
    vertices.extend((x * SCALE, depth_back * SCALE, z * SCALE) for x, z in outline)
    faces = [tuple(range(5)), tuple(reversed(range(5, 10)))]
    for index in range(5):
        next_index = (index + 1) % 5
        faces.append((index, next_index, next_index + 5, index + 5))
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    ear = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(ear)
    bevel = ear.modifiers.new(name="Rounded ear edges", type="BEVEL")
    bevel.width = 0.045 * SCALE
    bevel.segments = 3
    bpy.context.view_layer.objects.active = ear
    ear.select_set(True)
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    ear.select_set(False)
    ear.data.materials.append(material)
    weight_to_bone(ear, armature, bone)

    if inner_material:
        uv_sphere(
            f"{name}_Inner",
            (center_x, -0.115, 2.34),
            (0.105, 0.018, 0.105),
            inner_material,
            armature,
            bone,
            12,
            8,
        )
    return ear


def smile_curve(
    name: str,
    points: list[tuple[float, float, float]],
    material: bpy.types.Material,
    armature: bpy.types.Object,
    bone: str,
    thickness: float = 0.012,
) -> bpy.types.Object:
    curve_data = bpy.data.curves.new(f"{name}_Curve", type="CURVE")
    curve_data.dimensions = "3D"
    curve_data.resolution_u = 3
    curve_data.bevel_depth = thickness * SCALE
    curve_data.bevel_resolution = 3
    spline = curve_data.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for bezier_point, point in zip(spline.bezier_points, points):
        bezier_point.co = Vector(point) * SCALE
        bezier_point.handle_left_type = "AUTO"
        bezier_point.handle_right_type = "AUTO"
    curve_obj = bpy.data.objects.new(name, curve_data)
    bpy.context.collection.objects.link(curve_obj)
    curve_obj.data.materials.append(material)
    bpy.context.view_layer.objects.active = curve_obj
    curve_obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    curve_obj = bpy.context.object
    curve_obj.name = name
    weight_to_bone(curve_obj, armature, bone)
    curve_obj.select_set(False)
    return curve_obj


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


def ellipsoid_between(name: str, start: tuple[float, float, float], end: tuple[float, float, float], radius: float, material: bpy.types.Material, armature: bpy.types.Object, bone: str) -> bpy.types.Object:
    p0 = Vector(start) * SCALE
    p1 = Vector(end) * SCALE
    direction = p1 - p0
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, location=(p0 + p1) * 0.5)
    obj = bpy.context.object
    obj.scale = (radius * SCALE, radius * SCALE, direction.length * 0.56)
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = direction.to_track_quat("Z", "Y")
    obj.rotation_mode = "XYZ"
    return finish_mesh(obj, name, material, armature, bone)


def fused_surface(
    name: str,
    blobs: list[tuple[tuple[float, float, float], tuple[float, float, float]]],
    materials: tuple[bpy.types.Material, bpy.types.Material],
    armature: bpy.types.Object,
    weight_resolver,
    cream_resolver,
) -> bpy.types.Object:
    """Fuse overlapping ellipsoids into one smooth skinned surface."""
    pieces: list[bpy.types.Object] = []
    for index, (location, scale) in enumerate(blobs):
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=16,
            ring_count=10,
            location=tuple(value * SCALE for value in location),
        )
        piece = bpy.context.object
        piece.name = f"{name}_Blob_{index:02d}"
        piece.scale = tuple(value * SCALE for value in scale)
        apply_transform(piece)
        pieces.append(piece)

    bpy.ops.object.select_all(action="DESELECT")
    for piece in pieces:
        piece.select_set(True)
    bpy.context.view_layer.objects.active = pieces[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    obj.data.name = f"{name}_Mesh"
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    bpy.context.view_layer.objects.active = obj
    obj.data.remesh_voxel_size = (0.016 if MODEL_VERSION == "v11" else 0.018 if MODEL_VERSION == "v7" else 0.022 if MODEL_VERSION == "v6" else 0.026 if MODEL_VERSION == "v5" else 0.040 if MODEL_VERSION == "v4" else 0.055) * SCALE
    obj.data.remesh_voxel_adaptivity = 0.0
    bpy.ops.object.voxel_remesh()

    decimate = obj.modifiers.new(name="Roblox silhouette budget", type="DECIMATE")
    if MODEL_VERSION in {"v7", "v11"}:
        pre_subdivision_triangles = sum(len(poly.vertices) - 2 for poly in obj.data.polygons)
        target_triangles = 17500.0 if MODEL_VERSION == "v11" else 4500.0
        decimate.ratio = min(1.0, target_triangles / max(1, pre_subdivision_triangles))
    else:
        decimate.ratio = (0.86 if VARIANT == "owner" else 0.90) if MODEL_VERSION == "v6" else (0.80 if VARIANT == "owner" else 0.86) if MODEL_VERSION == "v5" else 0.62 if MODEL_VERSION == "v4" else 0.78
    bpy.ops.object.modifier_apply(modifier=decimate.name)
    if MODEL_VERSION in {"v6", "v7"}:
        subdivision = obj.modifiers.new(name="Round video silhouette", type="SUBSURF")
        subdivision.subdivision_type = "CATMULL_CLARK"
        subdivision.levels = 1
        subdivision.render_levels = 1
        bpy.ops.object.modifier_apply(modifier=subdivision.name)
        if MODEL_VERSION != "v7":
            import_budget = obj.modifiers.new(name="Roblox post-subdivision budget", type="DECIMATE")
            import_budget.ratio = 0.035 if VARIANT == "owner" else 0.070
            bpy.ops.object.modifier_apply(modifier=import_budget.name)
    relax = obj.modifiers.new(name="Relax voxel highlights", type="SMOOTH")
    relax.factor = 0.12 if MODEL_VERSION == "v11" else 0.11 if MODEL_VERSION == "v7" else 0.16 if MODEL_VERSION == "v6" else 0.20 if MODEL_VERSION == "v5" else 0.18 if MODEL_VERSION == "v4" else 0.24
    relax.iterations = 4 if MODEL_VERSION == "v11" else 3 if MODEL_VERSION == "v7" else 4 if MODEL_VERSION == "v6" else 5 if MODEL_VERSION == "v5" else 4 if MODEL_VERSION == "v4" else 3
    bpy.ops.object.modifier_apply(modifier=relax.name)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    if MODEL_VERSION in {"v7", "v11"}:
        # Break the procedural-sphere highlight without spending another mesh.
        # The front face stays restrained; shoulder/back/belly edges carry the
        # stronger short-coat silhouette that survives Roblox's PBR path.
        for vertex in obj.data.vertices:
            position = vertex.co / SCALE
            face_damping = 0.16 if MODEL_VERSION == "v11" and position.y < -0.58 else 0.22 if position.y < -0.64 else 1.0
            fiber = (
                math.sin(position.x * 37.0 + position.y * 19.0 + position.z * 29.0)
                + 0.55 * math.sin(position.x * 71.0 - position.y * 31.0 + position.z * 43.0)
            ) / 1.55
            coat_amplitude = 0.0028 if MODEL_VERSION == "v11" else 0.0018
            vertex.co += vertex.normal * (coat_amplitude * SCALE * face_damping * fiber)
        obj.data.update()
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.normals_make_consistent(inside=False)
        bpy.ops.object.mode_set(mode="OBJECT")
    for polygon in obj.data.polygons:
        polygon.use_smooth = True

    blend_material = bpy.data.materials.new(f"MAT_{name}_VertexBlend")
    blend_material.use_nodes = True
    blend_material.diffuse_color = materials[0].diffuse_color
    principled = blend_material.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Roughness"].default_value = 0.90
    color_node = blend_material.node_tree.nodes.new("ShaderNodeVertexColor")
    color_node.layer_name = "PipilabuColor"
    blend_material.node_tree.links.new(color_node.outputs["Color"], principled.inputs["Base Color"])
    obj.data.materials.append(blend_material)

    color_attribute = obj.data.color_attributes.new(name="PipilabuColor", type="BYTE_COLOR", domain="CORNER")
    tan_rgb = Vector(materials[0].diffuse_color[:3])
    cream_rgb = Vector(materials[1].diffuse_color[:3])
    for loop in obj.data.loops:
        position = (obj.matrix_world @ obj.data.vertices[loop.vertex_index].co) / SCALE
        cream_amount = float(cream_resolver(position))
        cream_amount = max(0.0, min(1.0, cream_amount))
        color = tan_rgb.lerp(cream_rgb, cream_amount)
        color_attribute.data[loop.index].color = (*color, 1.0)
    obj.data.update()

    groups: dict[str, bpy.types.VertexGroup] = {}
    for vertex in obj.data.vertices:
        weights = weight_resolver((obj.matrix_world @ vertex.co) / SCALE)
        for bone_name, weight in weights.items():
            if weight <= 0:
                continue
            group = groups.get(bone_name)
            if group is None:
                group = obj.vertex_groups.new(name=bone_name)
                groups[bone_name] = group
            group.add([vertex.index], weight, "REPLACE")

    armature_modifier = obj.modifiers.new(name="Armature", type="ARMATURE")
    armature_modifier.object = armature
    obj.parent = armature
    obj["fused_surface"] = True
    obj["max_influences"] = 3
    return obj


def apply_fur_tile(obj: bpy.types.Object, tile_path: Path) -> None:
    """Multiply subtle reference-derived strand variation over the authored coat mask."""
    material = obj.data.materials[0]
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    vertex_color = nodes.get("Vertex Color") or next((node for node in nodes if node.bl_idname == "ShaderNodeVertexColor"), None)
    principled = nodes.get("Principled BSDF")
    if not principled:
        raise RuntimeError("Fur tile requires a Principled BSDF material")
    if vertex_color:
        coat_color_output = vertex_color.outputs["Color"]
    else:
        authored_color = nodes.new("ShaderNodeRGB")
        authored_color.name = "Pipilabu_AuthoredCoatColor"
        authored_color.outputs["Color"].default_value = material.diffuse_color
        coat_color_output = authored_color.outputs["Color"]
    texture_coordinates = nodes.new("ShaderNodeTexCoord")
    mapping = nodes.new("ShaderNodeMapping")
    mapping.inputs["Scale"].default_value = (6.8, 6.8, 6.8) if MODEL_VERSION == "v8" else (5.6, 5.6, 5.6) if MODEL_VERSION == "v7" else (4.2, 4.2, 4.2)
    fur_texture = nodes.new("ShaderNodeTexImage")
    fur_texture.name = "Pipilabu_ReferenceFurTile"
    fur_texture.image = bpy.data.images.load(str(tile_path), check_existing=True)
    fur_texture.projection = "BOX"
    fur_texture.projection_blend = 0.22
    desaturate = nodes.new("ShaderNodeHueSaturation")
    desaturate.inputs["Saturation"].default_value = 0.0
    desaturate.inputs["Value"].default_value = 1.05
    multiply = nodes.new("ShaderNodeMixRGB")
    multiply.blend_type = "MULTIPLY"
    # v7 moves coat texture into the normal/silhouette signal. A strong triplanar
    # color multiply baked visible horizontal bands after Studio import.
    multiply.inputs[0].default_value = 0.52 if MODEL_VERSION == "v8" else 0.0 if MODEL_VERSION == "v7" else 0.24
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.055 if MODEL_VERSION == "v8" else 0.12 if MODEL_VERSION == "v7" else 0.025
    bump.inputs["Distance"].default_value = 0.010 if MODEL_VERSION == "v8" else 0.018 if MODEL_VERSION == "v7" else 0.012
    links.new(texture_coordinates.outputs["Generated"], mapping.inputs["Vector"])
    links.new(mapping.outputs["Vector"], fur_texture.inputs["Vector"])
    links.new(fur_texture.outputs["Color"], desaturate.inputs["Color"])
    links.new(coat_color_output, multiply.inputs[1])
    links.new(desaturate.outputs["Color"], multiply.inputs[2])
    links.new(multiply.outputs["Color"], principled.inputs["Base Color"])
    links.new(desaturate.outputs["Color"], bump.inputs["Height"])
    material["reference_bump_review_required"] = True
    material["reference_fur_tile"] = tile_path.name


def _save_generated_map(image: bpy.types.Image, path: Path) -> None:
    image.filepath_raw = str(path)
    image.file_format = "PNG"
    image.save()


def _make_plush_normal_map(size: int, path: Path) -> bpy.types.Image:
    image = bpy.data.images.new("Pipilabu_PlushNormal", width=size, height=size, alpha=True)
    pixels = [0.0] * (size * size * 4)
    for y in range(size):
        v = y / max(1, size - 1)
        for x in range(size):
            u = x / max(1, size - 1)
            # Two low-amplitude directional fibers; intentionally subtle at Roblox scale.
            amplitude_x = 0.0 if MODEL_VERSION in {"v7", "v8"} else 0.018
            amplitude_y = 0.0 if MODEL_VERSION in {"v7", "v8"} else 0.014
            nx = 0.5 + amplitude_x * math.sin((u * 113.0 + v * 29.0) * math.tau)
            ny = 0.5 + amplitude_y * math.sin((u * 31.0 - v * 107.0) * math.tau)
            index = (y * size + x) * 4
            pixels[index : index + 4] = (nx, ny, 0.999, 1.0)
    image.pixels.foreach_set(pixels)
    _save_generated_map(image, path)
    return image


def _make_scalar_map(name: str, size: int, value: float, path: Path, *, non_color: bool = True) -> bpy.types.Image:
    image = bpy.data.images.new(name, width=size, height=size, alpha=True)
    # Blender may reinterpret/reset image pixels when its colorspace changes. Set the
    # intended data colorspace before populating the scalar map so roughness values
    # survive PNG serialization instead of silently becoming black.
    if non_color:
        image.colorspace_settings.name = "Non-Color"
    row = [value, value, value, 1.0] * size
    image.pixels.foreach_set(row * size)
    image.update()
    _save_generated_map(image, path)
    return image


def bake_body_surface_maps(obj: bpy.types.Object, texture_size: int = 1024) -> dict[str, str]:
    """Bake the authored vertex-color pattern to UV maps and add restrained plush PBR detail."""
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(50), island_margin=0.025)
    bpy.ops.object.mode_set(mode="OBJECT")

    color_path = OUTPUT_DIR / f"{STEM}.colormap.png"
    normal_path = OUTPUT_DIR / f"{STEM}.normal.png"
    roughness_path = OUTPUT_DIR / f"{STEM}.roughness.png"
    metalness_path = OUTPUT_DIR / f"{STEM}.metalness.png"
    material = obj.data.materials[0]
    color_image = bpy.data.images.new("Pipilabu_BakedColor", width=texture_size, height=texture_size, alpha=True)
    color_image.generated_color = tuple(material.diffuse_color)

    nodes = material.node_tree.nodes
    image_node = nodes.new("ShaderNodeTexImage")
    image_node.name = "BAKE_TARGET_ColorMap"
    image_node.image = color_image
    nodes.active = image_node

    scene = bpy.context.scene
    previous_engine = scene.render.engine
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 12
    scene.cycles.use_denoising = False
    scene.render.bake.margin = 12
    bpy.ops.object.bake(type="DIFFUSE", pass_filter={"COLOR"}, use_clear=True, margin=12)
    _save_generated_map(color_image, color_path)

    normal_image = _make_plush_normal_map(texture_size, normal_path)
    roughness_image = _make_scalar_map("Pipilabu_Roughness", texture_size, 0.92, roughness_path)
    metalness_image = _make_scalar_map("Pipilabu_Metalness", texture_size, 0.0, metalness_path)

    principled = nodes.get("Principled BSDF")
    color_node = nodes.get("Pipilabu_BakedColorNode") or nodes.new("ShaderNodeTexImage")
    color_node.name = "Pipilabu_BakedColorNode"
    color_node.image = color_image
    # Keep the clean authored vertex colors wired for the beauty render. The baked map is
    # exported and validated separately until its UV-island review is artifact-free.
    material["baked_colormap_review_required"] = True

    normal_node = nodes.new("ShaderNodeTexImage")
    normal_node.name = "Pipilabu_PlushNormalNode"
    normal_node.image = normal_image
    normal_node.image.colorspace_settings.name = "Non-Color"
    normal_map = nodes.new("ShaderNodeNormalMap")
    normal_map.inputs["Strength"].default_value = 0.0 if MODEL_VERSION in {"v7", "v8", "v11"} else 0.06
    material.node_tree.links.new(normal_node.outputs["Color"], normal_map.inputs["Color"])
    material["baked_normalmap_review_required"] = True

    rough_node = nodes.new("ShaderNodeTexImage")
    rough_node.name = "Pipilabu_RoughnessNode"
    rough_node.image = roughness_image
    material.node_tree.links.new(rough_node.outputs["Color"], principled.inputs["Roughness"])
    metal_node = nodes.new("ShaderNodeTexImage")
    metal_node.name = "Pipilabu_MetalnessNode"
    metal_node.image = metalness_image
    material.node_tree.links.new(metal_node.outputs["Color"], principled.inputs["Metallic"])
    material["roblox_surfaceappearance_colormap"] = color_path.name
    material["roblox_surfaceappearance_normalmap"] = normal_path.name
    material["roblox_surfaceappearance_roughnessmap"] = roughness_path.name
    material["roblox_surfaceappearance_metalnessmap"] = metalness_path.name
    if MODEL_VERSION in {"v5", "v6", "v7", "v8", "v11"}:
        # Current validation previews deliberately use the Roblox-supported PBR contract. If
        # this validation render is wrong, export/import cannot rescue it.
        for link in list(material.node_tree.links):
            if link.to_node == principled and link.to_socket.name in {"Base Color", "Normal"}:
                material.node_tree.links.remove(link)
        material.node_tree.links.new(color_node.outputs["Color"], principled.inputs["Base Color"])
        material.node_tree.links.new(normal_map.outputs["Normal"], principled.inputs["Normal"])
        material.node_tree.links.new(principled.outputs["BSDF"], nodes["Material Output"].inputs["Surface"])
        material["baked_colormap_review_required"] = False
        material["baked_normalmap_review_required"] = False
        material["preview_shader"] = "Roblox-equivalent baked Color/Normal/Roughness/Metalness"
    else:
        base_source = next(
            link.from_socket
            for link in material.node_tree.links
            if link.to_node == principled and link.to_socket.name == "Base Color"
        )
        diffuse = nodes.new("ShaderNodeBsdfDiffuse")
        diffuse.name = "Pipilabu_MatteFurPreview"
        diffuse.inputs["Roughness"].default_value = 1.0
        material.node_tree.links.new(base_source, diffuse.inputs["Color"])
        reference_bump = nodes.get("Bump")
        if reference_bump:
            material.node_tree.links.new(reference_bump.outputs["Normal"], diffuse.inputs["Normal"])
        material.node_tree.links.new(diffuse.outputs["BSDF"], nodes["Material Output"].inputs["Surface"])
        material["preview_shader"] = "Matte diffuse; Roblox uses exported SurfaceAppearance maps"
    scene.render.engine = previous_engine
    bpy.ops.object.select_all(action="DESELECT")
    return {
        "colormap": color_path.name,
        "normalmap": normal_path.name,
        "roughnessmap": roughness_path.name,
        "metalnessmap": metalness_path.name,
    }


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


def build_armature_v2() -> bpy.types.Object:
    """Build the floor-hugging loaf rig defined by the source-video review."""
    data = bpy.data.armatures.new("PipilabuShiba_Rig")
    rig = bpy.data.objects.new("PipilabuShiba_Rig", data)
    bpy.context.collection.objects.link(rig)
    rig.show_in_front = True
    rig.display_type = "WIRE"
    rig["rig_version"] = SCRIPT_VERSION
    rig["model_version"] = MODEL_VERSION
    rig["character_kind"] = "OriginalPipilabuLoaf"
    rig["variant"] = VARIANT
    rig["art_direction"] = "Low horizontal shiba-inspired loaf; original procedural geometry"
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")

    def bone(name: str, head: tuple[float, float, float], tail: tuple[float, float, float], parent: str | None = None) -> None:
        edit_bone = data.edit_bones.new(name)
        edit_bone.head = Vector(head) * SCALE
        edit_bone.tail = Vector(tail) * SCALE
        if parent:
            edit_bone.parent = data.edit_bones[parent]

    bone("root", (0, 0.18, 0.08), (0, 0.18, 0.38))
    bone("spine", (0, 0.40, 0.60), (0, -0.42, 0.72), "root")
    bone("neck", (0, -0.42, 0.72), (0, -0.75, 0.84), "spine")
    bone("head", (0, -0.75, 0.84), (0, -1.24, 0.86), "neck")
    bone("jaw", (0, -1.14, 0.71), (0, -1.52, 0.68), "head")
    bone("tail", (0, 0.72, 0.62), (0.26, 1.16, 0.84), "spine")

    for label, x, y in (
        ("FL", -0.40, -0.46),
        ("FR", 0.40, -0.46),
        ("BL", -0.40, 0.56),
        ("BR", 0.40, 0.56),
    ):
        bone(f"leg_{label}", (x, y, 0.46), (x, y, 0.19), "spine")
        bone(f"paw_{label}", (x, y, 0.19), (x, y - 0.22, 0.11), f"leg_{label}")

    bpy.ops.object.mode_set(mode="OBJECT")
    rig.select_set(False)
    return rig


def build_customer_meshes_v2(rig: bpy.types.Object) -> None:
    tan = make_material("MAT_V2_Caramel", (0.66, 0.35, 0.145, 1.0), 0.88)
    tan_shadow = make_material("MAT_V2_CaramelShadow", (0.43, 0.20, 0.075, 1.0), 0.90)
    cream = make_material("MAT_V2_Urajiro", (0.90, 0.80, 0.65, 1.0), 0.90)
    ink = make_material("MAT_V2_Features", (0.029, 0.021, 0.016, 1.0), 0.72)
    glint = make_material("MAT_V2_EyeGlint", (0.96, 0.91, 0.82, 1.0), 0.42)

    # 2.75 x 1.42 x 1.16 overall: a 1.94:1 floor-hugging loaf at rest.
    uv_sphere("Body", (0, 0.05, 0.52), (0.58, 1.00, 0.46), tan, rig, "spine", 16, 10)
    uv_sphere("Urajiro_Belly", (0, 0.00, 0.27), (0.51, 0.82, 0.17), cream, rig, "spine", 14, 8)
    uv_sphere("Head", (0, -0.78, 0.76), (0.58, 0.52, 0.52), tan, rig, "head", 16, 10)
    uv_sphere("Cheek_L", (-0.28, -1.27, 0.71), (0.29, 0.18, 0.21), cream, rig, "head", 12, 8)
    uv_sphere("Cheek_R", (0.28, -1.27, 0.71), (0.29, 0.18, 0.21), cream, rig, "head", 12, 8)
    uv_sphere("Muzzle", (0, -1.43, 0.68), (0.30, 0.18, 0.18), cream, rig, "jaw", 12, 8)
    uv_sphere("Nose", (0, -1.59, 0.73), (0.12, 0.075, 0.085), ink, rig, "head", 10, 6)
    mouth_l = cube("Mouth_L", (-0.075, -1.585, 0.61), (0.085, 0.018, 0.018), ink, rig, "jaw", 0.015)
    mouth_l.rotation_euler[1] = math.radians(-11)
    mouth_r = cube("Mouth_R", (0.075, -1.585, 0.61), (0.085, 0.018, 0.018), ink, rig, "jaw", 0.015)
    mouth_r.rotation_euler[1] = math.radians(11)

    for side, x in (("L", -0.25), ("R", 0.25)):
        uv_sphere(f"Eye_{side}", (x, -1.355, 0.93), (0.068, 0.030, 0.046), ink, rig, "head", 10, 6)
        uv_sphere(f"EyeGlint_{side}", (x + 0.014, -1.384, 0.942), (0.013, 0.008, 0.010), glint, rig, "head", 8, 4)
        ear_x = -0.36 if side == "L" else 0.36
        cone(f"Ear_{side}", (ear_x, -0.74, 1.29), (0.13, 0.12, 0.13), tan_shadow, rig, "head")

    for label, x, y in (
        ("FL", -0.40, -0.46),
        ("FR", 0.40, -0.46),
        ("BL", -0.40, 0.56),
        ("BR", 0.40, 0.56),
    ):
        uv_sphere(f"Paw_{label}", (x, y - 0.12, 0.11), (0.16, 0.23, 0.10), cream, rig, f"paw_{label}", 10, 6)

    uv_sphere("TailTip", (0.20, 1.02, 0.50), (0.16, 0.18, 0.15), cream, rig, "tail", 10, 6)


def build_owner_meshes_v2(rig: bpy.types.Object) -> None:
    tan = make_material("MAT_V2_Caramel", (0.66, 0.35, 0.145, 1.0), 0.88)
    tan_shadow = make_material("MAT_V2_CaramelShadow", (0.43, 0.20, 0.075, 1.0), 0.90)
    cream = make_material("MAT_V2_Urajiro", (0.90, 0.80, 0.65, 1.0), 0.90)
    ink = make_material("MAT_V2_Features", (0.029, 0.021, 0.016, 1.0), 0.72)
    glint = make_material("MAT_V2_EyeGlint", (0.96, 0.91, 0.82, 1.0), 0.42)

    # Owner is a purpose-built counter composition, never a scaled customer.
    uv_sphere("OwnerShoulders", (0, 0.10, 0.68), (1.14, 0.72, 0.64), tan, rig, "spine", 18, 12)
    uv_sphere("Head", (0, -0.14, 1.62), (1.25, 1.00, 1.24), tan, rig, "head", 20, 14)
    uv_sphere("Cheek_L", (-0.55, -1.02, 1.31), (0.55, 0.29, 0.39), cream, rig, "head", 14, 10)
    uv_sphere("Cheek_R", (0.55, -1.02, 1.31), (0.55, 0.29, 0.39), cream, rig, "head", 14, 10)
    uv_sphere("Muzzle", (0, -1.24, 1.24), (0.58, 0.32, 0.33), cream, rig, "jaw", 14, 10)
    uv_sphere("Nose", (0, -1.51, 1.36), (0.21, 0.13, 0.14), ink, rig, "head", 12, 8)
    mouth_l = cube("Mouth_L", (-0.13, -1.49, 1.12), (0.15, 0.027, 0.027), ink, rig, "jaw", 0.020)
    mouth_l.rotation_euler[1] = math.radians(-10)
    mouth_r = cube("Mouth_R", (0.13, -1.49, 1.12), (0.15, 0.027, 0.027), ink, rig, "jaw", 0.020)
    mouth_r.rotation_euler[1] = math.radians(10)
    for side, x in (("L", -0.50), ("R", 0.50)):
        uv_sphere(f"Eye_{side}", (x, -1.135, 1.68), (0.11, 0.045, 0.075), ink, rig, "head", 10, 6)
        uv_sphere(f"EyeGlint_{side}", (x + 0.024, -1.177, 1.70), (0.022, 0.010, 0.018), glint, rig, "head", 8, 4)
        ear_x = -0.76 if side == "L" else 0.76
        cone(f"Ear_{side}", (ear_x, -0.26, 2.82), (0.22, 0.20, 0.25), tan_shadow, rig, "head")

    for label, x in (("FL", -0.78), ("FR", 0.78)):
        uv_sphere(f"Paw_{label}", (x, -0.96, 0.24), (0.30, 0.33, 0.19), cream, rig, f"paw_{label}", 12, 8)


def build_meshes_v2(rig: bpy.types.Object) -> None:
    if VARIANT == "owner":
        build_owner_meshes_v2(rig)
    else:
        build_customer_meshes_v2(rig)


def build_biped_armature_v3() -> bpy.types.Object:
    data = bpy.data.armatures.new("PipilabuBiped_Rig")
    rig = bpy.data.objects.new("PipilabuBiped_Rig", data)
    bpy.context.collection.objects.link(rig)
    rig.show_in_front = True
    rig.display_type = "WIRE"
    rig["rig_version"] = SCRIPT_VERSION
    rig["model_version"] = MODEL_VERSION
    rig["character_kind"] = "OriginalPipilabuBiped"
    rig["variant"] = VARIANT
    rig["art_direction"] = "Anthropomorphic shopkeeper; fused plush main mass; socket limbs"
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")

    def bone(name: str, head: tuple[float, float, float], tail: tuple[float, float, float], parent: str | None = None) -> None:
        edit_bone = data.edit_bones.new(name)
        edit_bone.head = Vector(head) * SCALE
        edit_bone.tail = Vector(tail) * SCALE
        if parent:
            edit_bone.parent = data.edit_bones[parent]

    bone("root", (0, 0, 0.10), (0, 0, 0.42))
    bone("spine", (0, 0, 0.42), (0, 0, 1.10), "root")
    bone("chest", (0, 0, 1.10), (0, 0, 1.55), "spine")
    bone("head", (0, 0, 1.55), (0, -0.03, 2.18), "chest")
    bone("ear_L", (-0.40, -0.02, 2.15), (-0.45, -0.02, 2.47), "head")
    bone("ear_R", (0.40, -0.02, 2.15), (0.45, -0.02, 2.47), "head")
    bone("tail", (0, 0.42, 0.82), (0.18, 0.76, 0.92), "spine")

    for side, sign in (("L", -1), ("R", 1)):
        bone(f"upper_arm_{side}", (0.50 * sign, 0, 1.47), (0.67 * sign, -0.02, 1.07), "chest")
        bone(f"forearm_{side}", (0.67 * sign, -0.02, 1.07), (0.72 * sign, -0.10, 0.73), f"upper_arm_{side}")
        bone(f"hand_{side}", (0.72 * sign, -0.10, 0.73), (0.72 * sign, -0.18, 0.55), f"forearm_{side}")
        bone(f"upper_leg_{side}", (0.30 * sign, 0, 0.72), (0.32 * sign, 0, 0.39), "root")
        bone(f"lower_leg_{side}", (0.32 * sign, 0, 0.39), (0.33 * sign, -0.03, 0.18), f"upper_leg_{side}")
        bone(f"foot_{side}", (0.33 * sign, -0.03, 0.18), (0.33 * sign, -0.27, 0.12), f"lower_leg_{side}")

    bpy.ops.object.mode_set(mode="OBJECT")
    rig.select_set(False)
    return rig


def build_owner_armature_v4() -> bpy.types.Object:
    is_customer = VARIANT == "customer"
    rig_name = "PeepilabuCustomer_Rig" if is_customer else "PeepilabuOwner_Rig"
    data = bpy.data.armatures.new(rig_name)
    rig = bpy.data.objects.new(rig_name, data)
    bpy.context.collection.objects.link(rig)
    rig.show_in_front = True
    rig.display_type = "WIRE"
    rig["rig_version"] = SCRIPT_VERSION
    rig["model_version"] = MODEL_VERSION
    rig["character_kind"] = "PeepilabuCustomerNPC" if is_customer else "PeepilabuOwnerHeroNPC"
    rig["variant"] = VARIANT
    rig["art_direction"] = (
        "Small warm Peepilabu customer; approved owner silhouette and expressive face"
        if is_customer
        else "Huge warm Pipi Labu owner behind counter; circular head, tiny lateral ear hints and paws"
    )
    rig["player_character"] = False
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")

    def bone(name: str, head: tuple[float, float, float], tail: tuple[float, float, float], parent: str | None = None) -> None:
        edit_bone = data.edit_bones.new(name)
        edit_bone.head = Vector(head) * SCALE
        edit_bone.tail = Vector(tail) * SCALE
        if parent:
            edit_bone.parent = data.edit_bones[parent]

    bone("root", (0, 0, 0.08), (0, 0, 0.36))
    bone("body", (0, 0, 0.36), (0, 0, 1.18), "root")
    bone("head", (0, 0, 1.00), (0, -0.04, 1.92), "body")
    bone("muzzle", (0, -0.42, 1.20), (0, -0.88, 1.18), "head")
    bone("ear_L", (-0.76, -0.01, 1.56), (-0.94, -0.01, 1.70), "head")
    bone("ear_R", (0.76, -0.01, 1.56), (0.94, -0.01, 1.70), "head")
    bone("paw_L", (-0.66, -0.48, 0.46), (-0.74, -0.78, 0.28), "body")
    bone("paw_R", (0.66, -0.48, 0.46), (0.74, -0.78, 0.28), "body")
    bone("tail", (0, 0.65, 0.70), (0.26, 0.91, 0.82), "body")

    bpy.ops.object.mode_set(mode="OBJECT")
    rig.select_set(False)
    return rig


def build_player_meshes_v3(rig: bpy.types.Object) -> None:
    tan = make_material("MAT_V3_Caramel", (0.60, 0.29, 0.095, 1.0), 0.90)
    cream = make_material("MAT_V3_Urajiro", (0.91, 0.82, 0.68, 1.0), 0.92)
    tan_shadow = make_material("MAT_V3_CaramelShadow", (0.38, 0.15, 0.045, 1.0), 0.92)
    ink = make_material("MAT_V3_Features", (0.025, 0.018, 0.014, 1.0), 0.55)
    glint = make_material("MAT_V3_EyeGlint", (0.98, 0.94, 0.86, 1.0), 0.34)

    blobs = [
        ((0, 0.02, 0.96), (0.62, 0.50, 0.82)),
        ((0, -0.01, 1.43), (0.59, 0.51, 0.54)),
        ((0, -0.04, 1.91), (0.73, 0.62, 0.66)),
        ((-0.32, -0.50, 1.78), (0.34, 0.23, 0.27)),
        ((0.32, -0.50, 1.78), (0.34, 0.23, 0.27)),
        ((0, -0.66, 1.68), (0.37, 0.23, 0.23)),
    ]

    def weights(position: Vector) -> dict[str, float]:
        if position.z >= 1.55:
            head_weight = min(1.0, (position.z - 1.45) / 0.30)
            return {"head": head_weight, "chest": 1.0 - head_weight}
        if position.z >= 1.08:
            chest_weight = min(1.0, (position.z - 1.00) / 0.25)
            return {"chest": chest_weight, "spine": 1.0 - chest_weight}
        return {"spine": 1.0}

    def ramp(edge_0: float, edge_1: float, value: float) -> float:
        amount = max(0.0, min(1.0, (value - edge_0) / (edge_1 - edge_0)))
        return amount * amount * (3.0 - 2.0 * amount)

    def cream_mask(position: Vector) -> float:
        front_amount = ramp(0.22, 0.50, -position.y)
        face_lower = ramp(1.34, 1.55, position.z)
        face_upper = 1.0 - ramp(1.88, 2.08, position.z)
        face_amount = front_amount * face_lower * face_upper
        chest_height = 1.0 - ramp(1.28, 1.50, position.z)
        chest_floor = ramp(0.28, 0.48, position.z)
        chest_width = 1.0 - ramp(0.42, 0.56, abs(position.x))
        chest_amount = front_amount * chest_height * chest_floor * chest_width
        belly_amount = (1.0 - ramp(0.30, 0.44, position.z)) * chest_width
        return max(face_amount, chest_amount, belly_amount)

    fused_surface("MainFusedBody", blobs, (tan, cream), rig, weights, cream_mask)

    for side, sign in (("L", -1), ("R", 1)):
        ellipsoid_between(
            f"Arm_{side}",
            (0.43 * sign, 0, 1.45),
            (0.70 * sign, -0.10, 0.73),
            0.18,
            tan,
            rig,
            f"upper_arm_{side}",
        )
        uv_sphere(f"Hand_{side}", (0.70 * sign, -0.14, 0.60), (0.20, 0.18, 0.21), cream, rig, f"hand_{side}", 12, 8)
        ellipsoid_between(
            f"Leg_{side}",
            (0.27 * sign, 0, 0.70),
            (0.33 * sign, -0.03, 0.18),
            0.23,
            tan,
            rig,
            f"upper_leg_{side}",
        )
        uv_sphere(f"Foot_{side}", (0.33 * sign, -0.18, 0.14), (0.27, 0.34, 0.15), cream, rig, f"foot_{side}", 12, 8)

    for side, sign in (("L", -1), ("R", 1)):
        cone(f"Ear_{side}", (0.43 * sign, -0.02, 2.45), (0.18, 0.15, 0.20), tan_shadow, rig, f"ear_{side}")
        uv_sphere(f"Eye_{side}", (0.28 * sign, -0.625, 1.98), (0.085, 0.042, 0.058), ink, rig, "head", 12, 8)
        uv_sphere(f"EyeGlint_{side}", (0.28 * sign + 0.018, -0.664, 2.00), (0.016, 0.008, 0.012), glint, rig, "head", 8, 4)

    uv_sphere("Nose", (0, -0.84, 1.76), (0.14, 0.09, 0.10), ink, rig, "head", 12, 8)
    mouth_l = cube("Mouth_L", (-0.085, -0.925, 1.62), (0.095, 0.018, 0.018), ink, rig, "head", 0.015)
    mouth_l.rotation_euler[1] = math.radians(-10)
    mouth_r = cube("Mouth_R", (0.085, -0.925, 1.62), (0.095, 0.018, 0.018), ink, rig, "head", 0.015)
    mouth_r.rotation_euler[1] = math.radians(10)
    ellipsoid_between("Tail", (0, 0.44, 0.83), (0.18, 0.75, 0.91), 0.18, tan, rig, "tail")
    uv_sphere("TailTip", (0.20, 0.78, 0.92), (0.18, 0.17, 0.17), cream, rig, "tail", 10, 6)


def build_player_meshes_v4(rig: bpy.types.Object) -> None:
    """Anthropomorphic worker dog: caramel face, compact muzzle, soft ears, texture-ready body."""
    caramel = make_material("MAT_V4_Caramel", (0.66, 0.32, 0.105, 1.0), 0.92)
    cream = make_material("MAT_V4_Urajiro", (0.86, 0.69, 0.48, 1.0), 0.94)
    ear_inner = make_material("MAT_V4_InnerEar", (0.47, 0.19, 0.13, 1.0), 0.88)
    ink = make_material("MAT_V4_Features", (0.018, 0.012, 0.010, 1.0), 0.26)
    glint = make_material("MAT_V4_EyeGlint", (1.0, 0.94, 0.82, 1.0), 0.18)
    cheek = make_material("MAT_V4_CheekWarmth", (0.70, 0.28, 0.18, 1.0), 0.88)

    # One continuous mass for the body, neck, head, cheeks and short muzzle.
    blobs = [
        ((0, 0.02, 0.91), (0.61, 0.50, 0.78)),
        ((0, -0.01, 1.39), (0.58, 0.50, 0.50)),
        ((0, -0.02, 1.87), (0.70, 0.60, 0.62)),
        ((-0.31, -0.50, 1.70), (0.32, 0.22, 0.25)),
        ((0.31, -0.50, 1.70), (0.32, 0.22, 0.25)),
        ((0, -0.66, 1.61), (0.34, 0.21, 0.20)),
    ]

    def weights(position: Vector) -> dict[str, float]:
        if position.z >= 1.49:
            head_weight = min(1.0, max(0.0, (position.z - 1.43) / 0.30))
            return {"head": head_weight, "chest": 1.0 - head_weight}
        if position.z >= 1.02:
            chest_weight = min(1.0, max(0.0, (position.z - 0.96) / 0.28))
            return {"chest": chest_weight, "spine": 1.0 - chest_weight}
        return {"spine": 1.0}

    def ramp(edge_0: float, edge_1: float, value: float) -> float:
        amount = max(0.0, min(1.0, (value - edge_0) / (edge_1 - edge_0)))
        return amount * amount * (3.0 - 2.0 * amount)

    def cream_mask(position: Vector) -> float:
        # Urajiro lives on the short muzzle/lower cheeks, never across the forehead.
        muzzle_front = ramp(0.48, 0.67, -position.y)
        muzzle_floor = ramp(1.43, 1.54, position.z)
        muzzle_ceiling = 1.0 - ramp(1.76, 1.84, position.z)
        muzzle_width = 1.0 - ramp(0.44, 0.59, abs(position.x))
        muzzle = muzzle_front * muzzle_floor * muzzle_ceiling * muzzle_width
        chest_front = ramp(0.26, 0.48, -position.y)
        chest_floor = ramp(0.24, 0.43, position.z)
        chest_ceiling = 1.0 - ramp(1.18, 1.40, position.z)
        chest_width = 1.0 - ramp(0.34, 0.51, abs(position.x))
        chest = chest_front * chest_floor * chest_ceiling * chest_width
        belly = (1.0 - ramp(0.26, 0.39, position.z)) * chest_width
        return max(muzzle, chest, belly)

    body = fused_surface("MainFusedBody", blobs, (caramel, cream), rig, weights, cream_mask)

    for side, sign in (("L", -1), ("R", 1)):
        ellipsoid_between(
            f"Arm_{side}",
            (0.42 * sign, 0, 1.40),
            (0.67 * sign, -0.11, 0.72),
            0.18,
            caramel,
            rig,
            f"upper_arm_{side}",
        )
        uv_sphere(f"Hand_{side}", (0.68 * sign, -0.15, 0.58), (0.20, 0.18, 0.20), cream, rig, f"hand_{side}", 16, 10)
        ellipsoid_between(
            f"Leg_{side}",
            (0.26 * sign, 0, 0.67),
            (0.31 * sign, -0.02, 0.18),
            0.22,
            caramel,
            rig,
            f"upper_leg_{side}",
        )
        uv_sphere(f"Foot_{side}", (0.31 * sign, -0.18, 0.13), (0.26, 0.33, 0.14), cream, rig, f"foot_{side}", 16, 10)

    rounded_ear("Ear_L", -0.40, caramel, rig, "ear_L", ear_inner)
    rounded_ear("Ear_R", 0.40, caramel, rig, "ear_R", ear_inner)

    for side, sign in (("L", -1), ("R", 1)):
        eye = uv_sphere(f"Eye_{side}", (0.245 * sign, -0.603, 1.90), (0.105, 0.035, 0.060), ink, rig, "head", 16, 10)
        eye.rotation_euler[1] = math.radians(5 * sign)
        uv_sphere(f"EyeGlint_{side}", (0.245 * sign + 0.020, -0.635, 1.915), (0.018, 0.007, 0.013), glint, rig, "head", 8, 6)
        uv_sphere(f"CheekWarmth_{side}", (0.405 * sign, -0.676, 1.65), (0.085, 0.012, 0.035), cheek, rig, "head", 12, 8)

    uv_sphere("Nose", (0, -0.845, 1.69), (0.125, 0.075, 0.085), ink, rig, "head", 16, 10)
    smile_curve("MouthStem", [(0, -0.851, 1.64), (0, -0.857, 1.575)], ink, rig, "head", 0.010)
    smile_curve("Smile_L", [(0, -0.858, 1.575), (-0.055, -0.858, 1.545), (-0.125, -0.842, 1.565)], ink, rig, "head", 0.011)
    smile_curve("Smile_R", [(0, -0.858, 1.575), (0.055, -0.858, 1.545), (0.125, -0.842, 1.565)], ink, rig, "head", 0.011)
    ellipsoid_between("Tail", (0, 0.43, 0.82), (0.19, 0.74, 0.92), 0.18, caramel, rig, "tail")
    uv_sphere("TailTip", (0.21, 0.77, 0.93), (0.18, 0.17, 0.17), cream, rig, "tail", 12, 8)

    fur_tile = Path(__file__).resolve().parents[1] / "assets" / "textures" / "peepilabu" / "shiba_short_fur_tile_v1.png"
    apply_fur_tile(body, fur_tile)
    surface_maps = bake_body_surface_maps(body, texture_size=1024)
    body["surface_maps"] = json.dumps(surface_maps, sort_keys=True)


def build_owner_meshes_v4(rig: bpy.types.Object) -> None:
    """Build the approved Peepilabu silhouette for either the owner or a small customer."""
    caramel = make_material("MAT_V4_Caramel", (0.46, 0.17, 0.055, 1.0), 0.93)
    cream = make_material("MAT_V4_Urajiro", (0.72, 0.50, 0.28, 1.0), 0.95)
    ink = make_material("MAT_V4_Features", (0.014, 0.009, 0.007, 1.0), 0.22)
    glint = make_material("MAT_V4_EyeGlint", (1.0, 0.95, 0.84, 1.0), 0.12)
    eye_warmth = make_material("MAT_V4_EyeWarmth", (0.16, 0.052, 0.012, 1.0), 0.20)

    blobs = [
        ((0, 0.02, 1.00), (1.05, 0.83, 0.96)),
        ((0, -0.04, 1.43), (1.06, 0.80, 0.84)),
        ((-0.42, -0.61, 1.23), (0.46, 0.28, 0.36)),
        ((0.42, -0.61, 1.23), (0.46, 0.28, 0.36)),
        ((0, -0.79, 1.12), (0.48, 0.29, 0.28)),
        # Pipi Labu's face reads as one round silhouette. These are tiny,
        # side-set fur/ear hints, intentionally buried inside that contour
        # instead of classic upright Shiba triangles above the crown.
        ((-0.88, -0.02, 1.62), (0.14, 0.11, 0.17)),
        ((0.88, -0.02, 1.62), (0.14, 0.11, 0.17)),
    ]

    def weights(position: Vector) -> dict[str, float]:
        ear_side = min(1.0, max(0.0, (abs(position.x) - 0.72) / 0.18))
        ear_band = min(1.0, max(0.0, 1.0 - abs(position.z - 1.62) / 0.26))
        ear_weight = ear_side * ear_band
        if ear_weight > 0.0:
            ear_bone = "ear_L" if position.x < 0 else "ear_R"
            return {ear_bone: ear_weight, "head": 1.0 - ear_weight}
        if position.z >= 0.94:
            head_weight = min(1.0, max(0.0, (position.z - 0.88) / 0.34))
            return {"head": head_weight, "body": 1.0 - head_weight}
        return {"body": 1.0}

    def ramp(edge_0: float, edge_1: float, value: float) -> float:
        amount = max(0.0, min(1.0, (value - edge_0) / (edge_1 - edge_0)))
        return amount * amount * (3.0 - 2.0 * amount)

    def cream_mask(position: Vector) -> float:
        front = ramp(0.48, 0.70, -position.y)
        muzzle_floor = ramp(0.82, 0.96, position.z)
        muzzle_ceiling = 1.0 - ramp(1.34, 1.47, position.z)
        muzzle_width = 1.0 - ramp(0.60, 0.78, abs(position.x))
        muzzle = front * muzzle_floor * muzzle_ceiling * muzzle_width
        belly_floor = ramp(0.12, 0.28, position.z)
        belly_ceiling = 1.0 - ramp(0.62, 0.86, position.z)
        belly_width = 1.0 - ramp(0.72, 0.96, abs(position.x))
        belly = ramp(0.10, 0.35, -position.y) * belly_floor * belly_ceiling * belly_width
        return max(muzzle, belly)

    body = fused_surface("MainFusedBody", blobs, (caramel, cream), rig, weights, cream_mask)

    for side, sign in (("L", -1), ("R", 1)):
        eye = uv_sphere(f"Eye_{side}", (0.32 * sign, -0.80, 1.48), (0.145, 0.038, 0.064), ink, rig, "head", 24, 14)
        eye.rotation_euler[1] = math.radians(5 * sign)
        uv_sphere(f"EyeWarmth_{side}", (0.32 * sign, -0.839, 1.456), (0.048, 0.006, 0.014), eye_warmth, rig, "head", 12, 8)
        uv_sphere(f"EyeGlint_{side}", (0.32 * sign - 0.026, -0.840, 1.510), (0.021, 0.006, 0.014), glint, rig, "head", 10, 6)
        uv_sphere(f"EyeGlintSmall_{side}", (0.32 * sign + 0.036, -0.840, 1.474), (0.010, 0.005, 0.007), glint, rig, "head", 8, 6)
        uv_sphere(f"Paw_{side}", (0.60 * sign, -0.73, 0.36), (0.31, 0.39, 0.22), cream, rig, f"paw_{side}", 32, 16)
        for claw_index, claw_x in enumerate((-0.075, 0.0, 0.075)):
            x = 0.60 * sign + claw_x
            smile_curve(
                f"PawLine_{side}_{claw_index + 1}",
                [(x, -1.095, 0.35), (x + 0.008 * sign, -1.105, 0.29)],
                caramel,
                rig,
                f"paw_{side}",
                0.008,
            )

    uv_sphere("Nose", (0, -1.035, 1.24), (0.16, 0.085, 0.105), ink, rig, "muzzle", 24, 14)
    smile_curve("MouthStem", [(0, -1.115, 1.17), (0, -1.116, 1.09)], ink, rig, "muzzle", 0.012)
    smile_curve("Smile_L", [(0, -1.117, 1.09), (-0.10, -1.116, 1.03), (-0.22, -1.085, 1.08)], ink, rig, "muzzle", 0.014)
    smile_curve("Smile_R", [(0, -1.117, 1.09), (0.10, -1.116, 1.03), (0.22, -1.085, 1.08)], ink, rig, "muzzle", 0.014)
    ellipsoid_between("Tail", (0, 0.70, 0.72), (0.25, 0.95, 0.84), 0.22, caramel, rig, "tail")

    fur_tile = Path(__file__).resolve().parents[1] / "assets" / "textures" / "peepilabu" / "shiba_short_fur_tile_v1.png"
    apply_fur_tile(body, fur_tile)
    surface_maps = bake_body_surface_maps(body, texture_size=1024)
    body["surface_maps"] = json.dumps(surface_maps, sort_keys=True)


def build_market_video_meshes_v5(rig: bpy.types.Object) -> None:
    """Build Leo's market-video seller/customer family, not a generic cartoon dog."""
    is_customer = VARIANT == "customer"
    caramel = make_material("MAT_V5_Caramel", (0.61, 0.335, 0.15, 1.0), 0.91)
    cream = make_material("MAT_V5_Urajiro", (0.86, 0.735, 0.56, 1.0), 0.93)
    ink = make_material("MAT_V5_Features", (0.012, 0.009, 0.008, 1.0), 0.22)
    eye_warmth = make_material("MAT_V5_EyeWarmth", (0.19, 0.075, 0.025, 1.0), 0.28)
    glint = make_material("MAT_V5_EyeGlint", (1.0, 0.96, 0.86, 1.0), 0.10)

    def ramp(edge_0: float, edge_1: float, value: float) -> float:
        amount = max(0.0, min(1.0, (value - edge_0) / (edge_1 - edge_0)))
        return amount * amount * (3.0 - 2.0 * amount)

    if is_customer:
        # The reference customers are low quadrupedal loaves with a real Shiba
        # face. They are not miniature copies of the biped owner rig.
        blobs = [
            # Compact, pear-shaped body and muscular haunch. The video animals
            # are low and weighty, not a long capsule with a dog face attached.
            ((0, 0.22, 0.52), (0.61, 0.78, 0.46)),
            ((0, 0.63, 0.50), (0.62, 0.57, 0.47)),
            ((0, -0.47, 0.62), (0.59, 0.52, 0.55)),
            # Shiba cheek ruff and a small projected muzzle establish the
            # breed face without turning it into a cartoon seal.
            ((-0.25, -0.82, 0.52), (0.31, 0.27, 0.25)),
            ((0.25, -0.82, 0.52), (0.31, 0.27, 0.25)),
            ((0, -1.04, 0.46), (0.27, 0.24, 0.18)),
            # Four short planted legs are fused into the coat silhouette.
            ((-0.39, -0.60, 0.24), (0.22, 0.32, 0.20)),
            ((0.39, -0.60, 0.24), (0.22, 0.32, 0.20)),
            ((-0.43, 0.62, 0.23), (0.24, 0.31, 0.20)),
            ((0.43, 0.62, 0.23), (0.24, 0.31, 0.20)),
            # Folded/swallowed ear roots stay inside the head contour.
            ((-0.43, -0.42, 0.83), (0.12, 0.10, 0.10)),
            ((0.43, -0.42, 0.83), (0.12, 0.10, 0.10)),
        ]

        def weights(position: Vector) -> dict[str, float]:
            if position.y < -0.28:
                if position.z < 0.38 and abs(position.x) > 0.22:
                    paw = "paw_L" if position.x < 0 else "paw_R"
                    return {paw: 0.82, "body": 0.18}
                if abs(position.x) > 0.34 and position.z > 0.75:
                    ear = "ear_L" if position.x < 0 else "ear_R"
                    return {ear: 0.18, "head": 0.82}
                return {"head": 1.0}
            return {"body": 1.0}

        def cream_mask(position: Vector) -> float:
            face_front = ramp(0.66, 0.96, -position.y)
            face_floor = ramp(0.30, 0.42, position.z)
            face_ceiling = 1.0 - ramp(0.58, 0.68, position.z)
            face_width = 1.0 - ramp(0.42, 0.59, abs(position.x))
            muzzle = face_front * face_floor * face_ceiling * face_width
            chest = ramp(0.38, 0.64, -position.y) * (1.0 - ramp(0.40, 0.56, position.z))
            underside = (1.0 - ramp(0.28, 0.42, position.z)) * (1.0 - ramp(0.50, 0.64, abs(position.x)))
            return max(muzzle, chest * 0.72, underside * 0.60)

        body = fused_surface("MainFusedBody", blobs, (caramel, cream), rig, weights, cream_mask)
        for side, sign in (("L", -1), ("R", 1)):
            eye = uv_sphere(f"Eye_{side}", (0.225 * sign, -1.205, 0.690), (0.095, 0.034, 0.060), ink, rig, "head", 28, 16)
            eye.rotation_euler[1] = math.radians(8 * sign)
            uv_sphere(f"EyeWarmth_{side}", (0.225 * sign, -1.238, 0.672), (0.030, 0.006, 0.014), eye_warmth, rig, "head", 12, 8)
            uv_sphere(f"EyeGlint_{side}", (0.202 * sign, -1.240, 0.720), (0.012, 0.005, 0.010), glint, rig, "head", 10, 6)
            # Cream toe caps stay flush to the planted caramel legs; no detached
            # white disks. Three tiny crease marks sell a paw at gameplay size.
            uv_sphere(f"ToeCap_{side}", (0.39 * sign, -0.845, 0.205), (0.15, 0.055, 0.092), cream, rig, f"paw_{side}", 24, 12)
            for toe in (-1, 0, 1):
                x = 0.39 * sign + toe * 0.055
                smile_curve(f"Toe_{side}_{toe + 2}", [(x, -0.914, 0.23), (x, -0.925, 0.19)], ink, rig, f"paw_{side}", 0.004)
        uv_sphere("Nose", (0, -1.275, 0.505), (0.115, 0.074, 0.078), ink, rig, "muzzle", 28, 16)
        smile_curve("MouthStem", [(0, -1.334, 0.48), (0, -1.338, 0.43)], ink, rig, "muzzle", 0.007)
        smile_curve("Smile_L", [(0, -1.339, 0.43), (-0.055, -1.334, 0.413), (-0.13, -1.311, 0.438)], ink, rig, "muzzle", 0.008)
        smile_curve("Smile_R", [(0, -1.339, 0.43), (0.055, -1.334, 0.413), (0.13, -1.311, 0.438)], ink, rig, "muzzle", 0.008)
        # Low curled tail mound; it should not read as a ball glued to the rump.
        ellipsoid_between("Tail", (0.05, 0.91, 0.55), (0.31, 1.10, 0.67), 0.17, caramel, rig, "tail")
    else:
        # The owner is the reference video's huge seller: mostly natural head
        # and shoulder mass above the counter, with no visible ear triangles.
        blobs = [
            ((0, 0.08, 0.90), (0.97, 0.74, 0.76)),
            ((0, -0.05, 1.38), (0.94, 0.67, 0.68)),
            ((0, -0.26, 1.55), (0.83, 0.54, 0.47)),
            ((-0.39, -0.62, 1.22), (0.38, 0.29, 0.29)),
            ((0.39, -0.62, 1.22), (0.38, 0.29, 0.29)),
            ((0, -0.88, 1.10), (0.35, 0.25, 0.21)),
            # Lateral folds remain swallowed by the crown silhouette.
            ((-0.75, -0.06, 1.55), (0.13, 0.10, 0.13)),
            ((0.75, -0.06, 1.55), (0.13, 0.10, 0.13)),
        ]

        def weights(position: Vector) -> dict[str, float]:
            if abs(position.x) > 0.68 and position.z > 1.33:
                ear = "ear_L" if position.x < 0 else "ear_R"
                return {ear: 0.16, "head": 0.84}
            if position.z >= 0.90:
                head_weight = min(1.0, max(0.0, (position.z - 0.84) / 0.34))
                return {"head": head_weight, "body": 1.0 - head_weight}
            return {"body": 1.0}

        def cream_mask(position: Vector) -> float:
            front = ramp(0.49, 0.72, -position.y)
            muzzle_floor = ramp(0.78, 0.92, position.z)
            muzzle_ceiling = 1.0 - ramp(1.20, 1.34, position.z)
            muzzle_width = 1.0 - ramp(0.58, 0.76, abs(position.x))
            muzzle = front * muzzle_floor * muzzle_ceiling * muzzle_width
            chest = ramp(0.12, 0.34, -position.y) * (1.0 - ramp(0.68, 0.86, position.z)) * (1.0 - ramp(0.72, 0.94, abs(position.x)))
            return max(muzzle, chest)

        body = fused_surface("MainFusedBody", blobs, (caramel, cream), rig, weights, cream_mask)
        for side, sign in (("L", -1), ("R", 1)):
            uv_sphere(f"Paw_{side}", (0.57 * sign, -0.72, 0.34), (0.25, 0.33, 0.16), caramel, rig, f"paw_{side}", 32, 18)
            uv_sphere(f"ToeCap_{side}", (0.57 * sign, -1.00, 0.335), (0.20, 0.075, 0.12), cream, rig, f"paw_{side}", 28, 14)
            for toe in (-1, 0, 1):
                x = 0.57 * sign + toe * 0.060
                smile_curve(f"Toe_{side}_{toe + 2}", [(x, -1.073, 0.37), (x, -1.083, 0.31)], ink, rig, f"paw_{side}", 0.0045)
            eye = uv_sphere(f"Eye_{side}", (0.325 * sign, -1.065, 1.43), (0.115, 0.036, 0.066), ink, rig, "head", 30, 18)
            eye.rotation_euler[1] = math.radians(7 * sign)
            uv_sphere(f"EyeWarmth_{side}", (0.325 * sign, -1.099, 1.411), (0.036, 0.006, 0.016), eye_warmth, rig, "head", 12, 8)
            uv_sphere(f"EyeGlint_{side}", (0.297 * sign, -1.101, 1.466), (0.014, 0.005, 0.011), glint, rig, "head", 10, 6)
        uv_sphere("Nose", (0, -1.105, 1.175), (0.135, 0.080, 0.090), ink, rig, "muzzle", 30, 18)
        smile_curve("MouthStem", [(0, -1.168, 1.125), (0, -1.171, 1.064)], ink, rig, "muzzle", 0.008)
        smile_curve("Smile_L", [(0, -1.172, 1.064), (-0.078, -1.167, 1.035), (-0.17, -1.142, 1.071)], ink, rig, "muzzle", 0.009)
        smile_curve("Smile_R", [(0, -1.172, 1.064), (0.078, -1.167, 1.035), (0.17, -1.142, 1.071)], ink, rig, "muzzle", 0.009)
        ellipsoid_between("Tail", (0, 0.68, 0.70), (0.22, 0.94, 0.82), 0.21, caramel, rig, "tail")

    body["visual_reference"] = "Leo 2026-08-09 market-video frames; no visible top-ear triangles"
    fur_tile = Path(__file__).resolve().parents[1] / "assets" / "textures" / "peepilabu" / "shiba_short_fur_tile_v1.png"
    apply_fur_tile(body, fur_tile)
    surface_maps = bake_body_surface_maps(body, texture_size=1024)
    body["surface_maps"] = json.dumps(surface_maps, sort_keys=True)


def build_video_turnaround_meshes_v6(rig: bpy.types.Object) -> None:
    """Build the owner/customer silhouettes locked by the 2026-08-09 video turnaround.

    v6 deliberately uses two different body plans. The owner is a massive grounded
    Shiba seller with forelegs flowing out of the shoulder mass. The customer is a
    long, belly-low quadruped. Both share small, inset facial features and ears that
    remain inside the crown silhouette.
    """
    is_customer = VARIANT == "customer"
    is_v7 = MODEL_VERSION == "v7"
    material_prefix = "MAT_V7" if is_v7 else "MAT_V6"
    caramel = make_material(f"{material_prefix}_Caramel", (0.66, 0.37, 0.16, 1.0) if is_v7 else (0.57, 0.285, 0.105, 1.0), 0.96 if is_v7 else 0.93)
    cream = make_material(f"{material_prefix}_Urajiro", (0.86, 0.71, 0.51, 1.0) if is_v7 else (0.88, 0.76, 0.59, 1.0), 0.97 if is_v7 else 0.95)
    ink = make_material(f"{material_prefix}_Features", (0.008, 0.006, 0.005, 1.0), 0.30)
    eye_warmth = make_material(f"{material_prefix}_EyeWarmth", (0.13, 0.045, 0.014, 1.0), 0.34)
    glint = make_material(f"{material_prefix}_EyeGlint", (0.96, 0.91, 0.80, 1.0), 0.14)

    def ramp(edge_0: float, edge_1: float, value: float) -> float:
        amount = max(0.0, min(1.0, (value - edge_0) / (edge_1 - edge_0)))
        return amount * amount * (3.0 - 2.0 * amount)

    if is_customer:
        blobs = ([
            # v7 follows the approved turnaround much more literally: long coat
            # mass, distinct shoulder/head planes, a short Shiba muzzle, and feet
            # that barely interrupt the belly silhouette.
            ((0, 0.34, 0.42), (0.56, 0.91, 0.33)),
            ((0, 0.77, 0.44), (0.57, 0.53, 0.36)),
            ((0, -0.28, 0.46), (0.49, 0.44, 0.38)),
            ((0, -0.66, 0.54), (0.43, 0.38, 0.39)),
            ((0, -0.88, 0.56), (0.34, 0.29, 0.28)),
            ((-0.16, -1.00, 0.48), (0.20, 0.18, 0.18)),
            ((0.16, -1.00, 0.48), (0.20, 0.18, 0.18)),
            ((0, -1.13, 0.44), (0.20, 0.18, 0.14)),
            ((-0.34, -0.48, 0.20), (0.145, 0.25, 0.125)),
            ((0.34, -0.48, 0.20), (0.145, 0.25, 0.125)),
            ((-0.38, 0.70, 0.19), (0.15, 0.23, 0.12)),
            ((0.38, 0.70, 0.19), (0.15, 0.23, 0.12)),
            ((-0.35, -0.65, 0.68), (0.045, 0.038, 0.040)),
            ((0.35, -0.65, 0.68), (0.045, 0.038, 0.040)),
        ] if is_v7 else [
            # Long back and hanging belly: the silhouette must read as a living
            # low quadruped rather than a sphere or a scaled-down owner.
            ((0, 0.29, 0.43), (0.54, 0.88, 0.34)),
            ((0, 0.73, 0.45), (0.55, 0.54, 0.37)),
            ((0, -0.33, 0.48), (0.48, 0.46, 0.40)),
            ((0, -0.70, 0.52), (0.45, 0.42, 0.39)),
            # Breed-specific cheek planes and a short projected muzzle.
            ((-0.19, -0.91, 0.47), (0.24, 0.22, 0.19)),
            ((0.19, -0.91, 0.47), (0.24, 0.22, 0.19)),
            ((0, -1.075, 0.425), (0.21, 0.18, 0.14)),
            # Four tiny planted limb masses. They interrupt the belly line but
            # never become white toy balls.
            ((-0.36, -0.51, 0.22), (0.18, 0.27, 0.15)),
            ((0.36, -0.51, 0.22), (0.18, 0.27, 0.15)),
            ((-0.39, 0.68, 0.21), (0.18, 0.25, 0.14)),
            ((0.39, 0.68, 0.21), (0.18, 0.25, 0.14)),
            # Visually swallowed lateral folds, not readable top triangles.
            ((-0.36, -0.58, 0.69), (0.075, 0.060, 0.055)),
            ((0.36, -0.58, 0.69), (0.075, 0.060, 0.055)),
        ])

        def weights(position: Vector) -> dict[str, float]:
            if position.y < -0.28:
                if abs(position.x) > 0.29 and position.z > 0.62:
                    ear = "ear_L" if position.x < 0 else "ear_R"
                    return {ear: 0.10, "head": 0.90}
                return {"head": 1.0}
            return {"body": 1.0}

        def cream_mask(position: Vector) -> float:
            face_front = ramp(0.72, 1.02, -position.y)
            face_floor = ramp(0.29, 0.39, position.z)
            face_ceiling = 1.0 - ramp(0.56, 0.67, position.z)
            face_width = 1.0 - ramp(0.34, 0.48, abs(position.x))
            muzzle = face_front * face_floor * face_ceiling * face_width
            underside = (1.0 - ramp(0.25, 0.38, position.z)) * (1.0 - ramp(0.40, 0.55, abs(position.x)))
            return max(muzzle, underside * 0.78)

        body = fused_surface("MainFusedBody", blobs, (caramel, cream), rig, weights, cream_mask)
        for side, sign in (("L", -1), ("R", 1)):
            # Narrow, inset eyes keep the video Shiba expression. Their shallow
            # depth prevents the floating goggle failure in v5 side renders.
            eye_center = (0.150 * sign, -1.165, 0.585) if is_v7 else (0.172 * sign, -1.095, 0.590)
            eye_scale = (0.069, 0.022, 0.046) if is_v7 else (0.052, 0.013, 0.032)
            eye = uv_sphere(f"Eye_{side}", eye_center, eye_scale, ink, rig, "head", 32 if is_v7 else 28, 18 if is_v7 else 16)
            eye.rotation_euler[1] = math.radians(6 * sign)
            warmth_center = (0.150 * sign, -1.186, 0.572) if is_v7 else (0.172 * sign, -1.107, 0.584)
            glint_center = (0.134 * sign, -1.188, 0.612) if is_v7 else (0.159 * sign, -1.109, 0.606)
            uv_sphere(f"EyeWarmth_{side}", warmth_center, (0.023, 0.0035, 0.010) if is_v7 else (0.016, 0.0025, 0.007), eye_warmth, rig, "head", 12, 8)
            uv_sphere(f"EyeGlint_{side}", glint_center, (0.008, 0.0025, 0.006) if is_v7 else (0.006, 0.002, 0.0045), glint, rig, "head", 10, 6)
            # Only the front toe edge gets a cream hint; the whole foot remains
            # fused into the caramel leg silhouette.
            uv_sphere(f"ToeCap_{side}", (0.355 * sign, -0.742, 0.178), (0.074, 0.023, 0.037), cream, rig, f"paw_{side}", 24, 12)
            for toe in (-1, 0, 1):
                x = 0.355 * sign + toe * 0.037
                smile_curve(f"Toe_{side}_{toe + 2}", [(x, -0.793, 0.205), (x, -0.798, 0.177)], ink, rig, f"paw_{side}", 0.0032)
        uv_sphere("Nose", (0, -1.292, 0.438) if is_v7 else (0, -1.218, 0.445), (0.086, 0.052, 0.058) if is_v7 else (0.070, 0.041, 0.048), ink, rig, "muzzle", 32 if is_v7 else 30, 18)
        mouth_y = -1.347 if is_v7 else -1.263
        mouth_z = 0.410 if is_v7 else 0.423
        smile_curve("MouthStem", [(0, mouth_y, mouth_z), (0, mouth_y - 0.002, mouth_z - 0.033)], ink, rig, "muzzle", 0.0045 if is_v7 else 0.005)
        smile_curve("Smile_L", [(0, mouth_y - 0.003, mouth_z - 0.033), (-0.043, mouth_y + 0.002, mouth_z - 0.047), (-0.102, mouth_y + 0.021, mouth_z - 0.026)], ink, rig, "muzzle", 0.005 if is_v7 else 0.006)
        smile_curve("Smile_R", [(0, mouth_y - 0.003, mouth_z - 0.033), (0.043, mouth_y + 0.002, mouth_z - 0.047), (0.102, mouth_y + 0.021, mouth_z - 0.026)], ink, rig, "muzzle", 0.005 if is_v7 else 0.006)
        ellipsoid_between("Tail", (0.02, 0.96, 0.48), (0.21, 1.10, 0.55), 0.115, caramel, rig, "tail")
    else:
        blobs = ([
            # v7 owner: one continuous fur mass, natural shoulder taper, broad
            # forehead, reduced toy cheeks, short bridge and compact muzzle.
            ((0, 0.10, 0.80), (1.02, 0.75, 0.79)),
            ((0, -0.01, 1.15), (0.96, 0.68, 0.72)),
            ((0, -0.18, 1.49), (0.83, 0.58, 0.67)),
            ((0, -0.43, 1.52), (0.63, 0.43, 0.44)),
            ((-0.29, -0.65, 1.31), (0.31, 0.25, 0.27)),
            ((0.29, -0.65, 1.31), (0.31, 0.25, 0.27)),
            ((0, -0.80, 1.26), (0.29, 0.23, 0.22)),
            ((0, -1.00, 1.17), (0.245, 0.20, 0.16)),
            ((0, -0.40, 0.94), (0.72, 0.40, 0.27)),
            ((-0.68, -0.28, 1.62), (0.055, 0.042, 0.045)),
            ((0.68, -0.28, 1.62), (0.055, 0.042, 0.045)),
        ] if is_v7 else [
            # One grounded shoulder/torso mass, then a distinct crown. The
            # broad lower silhouette is essential to the giant seller read.
            ((0, 0.09, 0.86), (1.03, 0.76, 0.83)),
            ((0, -0.01, 1.18), (0.96, 0.69, 0.69)),
            ((0, -0.18, 1.48), (0.82, 0.57, 0.64)),
            ((0, -0.43, 1.54), (0.61, 0.43, 0.43)),
            ((-0.32, -0.62, 1.35), (0.36, 0.29, 0.28)),
            ((0.32, -0.62, 1.35), (0.36, 0.29, 0.28)),
            ((0, -0.87, 1.17), (0.31, 0.27, 0.21)),
            # Ear roots never break the round crown.
            ((-0.65, -0.25, 1.63), (0.085, 0.065, 0.070)),
            ((0.65, -0.25, 1.63), (0.085, 0.065, 0.070)),
        ])

        def weights(position: Vector) -> dict[str, float]:
            if abs(position.x) > 0.57 and position.z > 1.50:
                ear = "ear_L" if position.x < 0 else "ear_R"
                return {ear: 0.10, "head": 0.90}
            if position.z >= 0.92:
                head_weight = min(1.0, max(0.0, (position.z - 0.84) / 0.32))
                return {"head": head_weight, "body": 1.0 - head_weight}
            return {"body": 1.0}

        def cream_mask(position: Vector) -> float:
            front = ramp(0.50, 0.82, -position.y)
            muzzle_floor = ramp(0.91, 1.04, position.z)
            muzzle_ceiling = 1.0 - ramp(1.31, 1.43, position.z)
            muzzle_width = 1.0 - ramp(0.49, 0.66, abs(position.x))
            muzzle = front * muzzle_floor * muzzle_ceiling * muzzle_width
            chest = ramp(0.15, 0.42, -position.y) * (1.0 - ramp(0.78, 0.98, position.z)) * (1.0 - ramp(0.66, 0.91, abs(position.x)))
            return max(muzzle, chest)

        body = fused_surface("MainFusedBody", blobs, (caramel, cream), rig, weights, cream_mask)
        for side, sign in (("L", -1), ("R", 1)):
            eye_center = (0.245 * sign, -1.035, 1.455) if is_v7 else (0.275 * sign, -0.955, 1.455)
            eye_scale = (0.088, 0.026, 0.059) if is_v7 else (0.064, 0.015, 0.038)
            eye = uv_sphere(f"Eye_{side}", eye_center, eye_scale, ink, rig, "head", 32 if is_v7 else 30, 18)
            eye.rotation_euler[1] = math.radians(6 * sign)
            warmth_center = (0.245 * sign, -1.060, 1.438) if is_v7 else (0.275 * sign, -0.969, 1.447)
            glint_center = (0.222 * sign, -1.062, 1.486) if is_v7 else (0.258 * sign, -0.971, 1.476)
            uv_sphere(f"EyeWarmth_{side}", warmth_center, (0.030, 0.004, 0.013) if is_v7 else (0.020, 0.0025, 0.008), eye_warmth, rig, "head", 12, 8)
            uv_sphere(f"EyeGlint_{side}", glint_center, (0.010, 0.003, 0.007) if is_v7 else (0.007, 0.002, 0.005), glint, rig, "head", 10, 6)
            # A low separate paw pad sharpens the counter contact while the arm
            # above it remains fused into the shoulder mass.
            paw_scale = (0.170, 0.245, 0.095) if is_v7 else (0.185, 0.255, 0.100)
            toe_scale = (0.118, 0.040, 0.054) if is_v7 else (0.135, 0.044, 0.062)
            uv_sphere(f"PawPad_{side}", (0.50 * sign, -0.86, 0.285), paw_scale, caramel, rig, f"paw_{side}", 32, 18)
            uv_sphere(f"ToeCap_{side}", (0.50 * sign, -1.060, 0.282), toe_scale, cream, rig, f"paw_{side}", 28, 14)
            for toe in (-1, 0, 1):
                x = 0.50 * sign + toe * 0.041
                smile_curve(f"Toe_{side}_{toe + 2}", [(x, -1.140, 0.325), (x, -1.145, 0.275)], ink, rig, f"paw_{side}", 0.004)
        uv_sphere("Nose", (0, -1.205, 1.175) if is_v7 else (0, -1.075, 1.205), (0.125, 0.072, 0.080) if is_v7 else (0.105, 0.058, 0.069), ink, rig, "muzzle", 32 if is_v7 else 30, 18)
        mouth_y = -1.268 if is_v7 else -1.123
        mouth_z = 1.142 if is_v7 else 1.172
        smile_curve("MouthStem", [(0, mouth_y, mouth_z), (0, mouth_y - 0.002, mouth_z - 0.049)], ink, rig, "muzzle", 0.0055 if is_v7 else 0.0065)
        smile_curve("Smile_L", [(0, mouth_y - 0.003, mouth_z - 0.049), (-0.060, mouth_y + 0.001, mouth_z - 0.070), (-0.137, mouth_y + 0.022, mouth_z - 0.042)], ink, rig, "muzzle", 0.0065 if is_v7 else 0.0075)
        smile_curve("Smile_R", [(0, mouth_y - 0.003, mouth_z - 0.049), (0.060, mouth_y + 0.001, mouth_z - 0.070), (0.137, mouth_y + 0.022, mouth_z - 0.042)], ink, rig, "muzzle", 0.0065 if is_v7 else 0.0075)
        ellipsoid_between("Tail", (0, 0.69, 0.66), (0.18, 0.91, 0.75), 0.17, caramel, rig, "tail")

    body["visual_reference"] = "assets/concepts/pipi-labu-video-turnaround-v6.png; video-frame silhouette lock"
    body["top_ear_policy"] = "No crown-breaking triangles; lateral roots remain swallowed"
    body["promotion_status"] = "Candidate only until Blender and Studio gameplay review"
    if is_v7:
        body["fidelity_pass"] = "Approved-turnaround sculpt pass: denser silhouette, natural facial planes, stronger Roblox-equivalent coat signal"
    fur_tile = Path(__file__).resolve().parents[1] / "assets" / "textures" / "peepilabu" / "shiba_short_fur_tile_v1.png"
    apply_fur_tile(body, fur_tile)
    surface_maps = bake_body_surface_maps(body, texture_size=1024)
    body["surface_maps"] = json.dumps(surface_maps, sort_keys=True)


def build_video_turnaround_meshes_v8(rig: bpy.types.Object) -> None:
    """Build the rejected v8 Studio-equivalence evidence models.

    This pass intentionally removes every crown-breaking ear mesh. The owner is
    one uninterrupted round shell; the customer uses overlapping torso and head
    shells so the head can animate without importing the voxel terraces seen in
    v7. Leo rejected the resulting primitive/blob character quality on
    2026-08-09. Preserve this builder for regression evidence only; do not use it
    as the base of another promoted character candidate.
    """
    is_customer = VARIANT == "customer"
    caramel = make_material("MAT_V8_Caramel", (0.64, 0.36, 0.16, 1.0), 0.96)
    cream = make_material("MAT_V8_Urajiro", (0.88, 0.74, 0.56, 1.0), 0.97)
    ink = make_material("MAT_V8_Features", (0.010, 0.007, 0.005, 1.0), 0.34)
    ear_shadow = make_material("MAT_V8_EarFold", (0.37, 0.17, 0.065, 1.0), 0.97)
    eye_warmth = make_material("MAT_V8_EyeWarmth", (0.11, 0.040, 0.014, 1.0), 0.32)
    glint = make_material("MAT_V8_EyeGlint", (0.98, 0.94, 0.86, 1.0), 0.12)

    def ramp(edge_0: float, edge_1: float, value: float) -> float:
        amount = max(0.0, min(1.0, (value - edge_0) / (edge_1 - edge_0)))
        return amount * amount * (3.0 - 2.0 * amount)

    if is_customer:
        body = smooth_uv_shell("MainFusedBody", (0, 0.13, 0.40), (0.53, 1.02, 0.35), caramel, rig, "body")
        shape_customer_shell(body)
        def customer_belly_mask(position: Vector) -> float:
            underside = 1.0 - ramp(0.16, 0.29, position.z)
            width = 1.0 - ramp(0.32, 0.48, abs(position.x))
            return underside * width * 0.92
        apply_vertex_color_material(body, caramel, cream, customer_belly_mask)
        add_short_coat_surface(body, 0.0024)
        # Low cream underside and face planes. Their shallow depth preserves the
        # original-video read without the detached marshmallow-cheek failure.
        uv_sphere("BellyPatch", (0, 0.24, 0.105), (0.39, 0.69, 0.035), cream, rig, "body", 48, 24)
        uv_sphere("MuzzleBridge", (0, -0.970, 0.465), (0.205, 0.045, 0.125), cream, rig, "muzzle", 48, 24)
        for side, sign in (("L", -1), ("R", 1)):
            uv_sphere(f"Cheek_{side}", (0.145 * sign, -0.945, 0.485), (0.155, 0.038, 0.120), cream, rig, "head", 40, 22)
            eye = uv_sphere(f"Eye_{side}", (0.145 * sign, -1.005, 0.603), (0.057, 0.025, 0.043), ink, rig, "head", 28, 16)
            eye.rotation_euler[1] = math.radians(5 * sign)
            uv_sphere(f"EyeWarmth_{side}", (0.145 * sign, -1.028, 0.592), (0.018, 0.003, 0.009), eye_warmth, rig, "head", 12, 8)
            uv_sphere(f"EyeGlint_{side}", (0.130 * sign, -1.030, 0.623), (0.006, 0.002, 0.005), glint, rig, "head", 10, 6)
            paw_y = -0.40
            smooth_uv_shell(f"Paw_{side}", (0.335 * sign, paw_y, 0.155), (0.135, 0.20, 0.095), caramel, rig, f"paw_{side}", 32, 18)
            uv_sphere(f"ToeCap_{side}", (0.335 * sign, paw_y - 0.165, 0.145), (0.080, 0.025, 0.042), cream, rig, f"paw_{side}", 24, 12)
            uv_sphere(f"RearPaw_{side}", (0.355 * sign, 0.72, 0.135), (0.105, 0.16, 0.065), caramel, rig, "body", 28, 16)
        uv_sphere("Nose", (0, -1.055, 0.455), (0.080, 0.052, 0.057), ink, rig, "muzzle", 30, 18)
        smile_curve("MouthStem", [(0, -1.105, 0.427), (0, -1.108, 0.394)], ink, rig, "muzzle", 0.004)
        smile_curve("Smile_L", [(0, -1.109, 0.394), (-0.040, -1.103, 0.380), (-0.090, -1.089, 0.397)], ink, rig, "muzzle", 0.0045)
        smile_curve("Smile_R", [(0, -1.109, 0.394), (0.040, -1.103, 0.380), (0.090, -1.089, 0.397)], ink, rig, "muzzle", 0.0045)
        ellipsoid_between("Tail", (0.12, 0.91, 0.43), (0.33, 1.07, 0.50), 0.105, caramel, rig, "tail")
        body["top_ear_policy"] = "No separate ear geometry; crown remains fully continuous"
    else:
        body = smooth_uv_shell("MainFusedBody", (0, 0.05, 0.93), (1.02, 0.76, 0.88), caramel, rig, "body")
        add_short_coat_surface(body)
        def owner_cream_mask(position: Vector) -> float:
            front = ramp(0.54, 0.72, -position.y)
            face_floor = ramp(0.92, 1.04, position.z)
            face_ceiling = 1.0 - ramp(1.34, 1.47, position.z)
            face_width = 1.0 - ramp(0.36, 0.58, abs(position.x))
            face = front * face_floor * face_ceiling * face_width
            chest_floor = ramp(0.22, 0.36, position.z)
            chest_ceiling = 1.0 - ramp(0.78, 0.96, position.z)
            chest_width = 1.0 - ramp(0.30, 0.53, abs(position.x))
            chest = front * chest_floor * chest_ceiling * chest_width
            return max(face, chest * 0.92)
        apply_vertex_color_material(body, caramel, cream, owner_cream_mask)
        # Flattened cream masks hug the front shell. The face stays within the
        # crown and projects only enough to read as a Shiba, never as a long snout.
        uv_sphere("MuzzleBridge", (0, -0.750, 1.095), (0.245, 0.040, 0.115), cream, rig, "muzzle", 48, 24)
        for side, sign in (("L", -1), ("R", 1)):
            uv_sphere(f"EarFold_{side}", (0.64 * sign, -0.305, 1.505), (0.105, 0.015, 0.070), ear_shadow, rig, f"ear_{side}", 28, 16)
            eye = uv_sphere(f"Eye_{side}", (0.220 * sign, -0.735, 1.345), (0.064, 0.025, 0.045), ink, rig, "head", 30, 18)
            eye.rotation_euler[1] = math.radians(5 * sign)
            uv_sphere(f"EyeWarmth_{side}", (0.220 * sign, -0.758, 1.334), (0.020, 0.004, 0.009), eye_warmth, rig, "head", 12, 8)
            uv_sphere(f"EyeGlint_{side}", (0.202 * sign, -0.760, 1.370), (0.007, 0.003, 0.005), glint, rig, "head", 10, 6)
            uv_sphere(f"Foreleg_{side}", (0.62 * sign, -0.505, 0.565), (0.245, 0.235, 0.415), caramel, rig, f"paw_{side}", 42, 24)
            uv_sphere(f"Paw_{side}", (0.62 * sign, -0.625, 0.220), (0.205, 0.245, 0.070), caramel, rig, f"paw_{side}", 36, 20)
            uv_sphere(f"ToeCap_{side}", (0.62 * sign, -0.835, 0.222), (0.140, 0.026, 0.048), cream, rig, f"paw_{side}", 26, 14)
        uv_sphere("Nose", (0, -0.825, 1.095), (0.092, 0.056, 0.060), ink, rig, "muzzle", 32, 18)
        smile_curve("MouthStem", [(0, -0.873, 1.065), (0, -0.875, 1.028)], ink, rig, "muzzle", 0.0045)
        smile_curve("Smile_L", [(0, -0.876, 1.028), (-0.050, -0.869, 1.012), (-0.112, -0.850, 1.034)], ink, rig, "muzzle", 0.005)
        smile_curve("Smile_R", [(0, -0.876, 1.028), (0.050, -0.869, 1.012), (0.112, -0.850, 1.034)], ink, rig, "muzzle", 0.005)
        uv_sphere("Tail", (0.93, 0.42, 0.72), (0.15, 0.12, 0.14), caramel, rig, "tail", 32, 18)

    body["visual_reference"] = "assets/concepts/pipi-labu-video-turnaround-v6.png; original-video silhouette lock"
    body["top_ear_policy"] = "No top-ear geometry; rounded crown is absolute"
    body["promotion_status"] = "REJECTED_BY_LEO_2026_08_09; regression evidence only"
    body["fidelity_pass"] = "v8 regular-topology import proof; visual target failed"
    fur_tile = Path(__file__).resolve().parents[1] / "assets" / "textures" / "peepilabu" / "shiba_short_fur_tile_v1.png"
    apply_fur_tile(body, fur_tile)
    surface_maps = bake_body_surface_maps(body, texture_size=1024)
    body["surface_maps"] = json.dumps(surface_maps, sort_keys=True)


def build_owner_meshes_v11(rig: bpy.types.Object) -> None:
    """Build the v11 room-orb owner selected by Leo from the reel audit.

    V11 is deliberately owner-only. It preserves the proven rig/export contract
    while replacing the rejected v8 face and limb proportions with the registered
    v11 target: one giant fused orb, tiny planted paws, no ear or tail geometry,
    low small eyes beneath a heavy crown, broad cream cheeks, and a crescent grin.
    """
    if VARIANT != "owner":
        raise ValueError("v11 is an owner-only reconstruction candidate")

    caramel = make_material("MAT_V11_Caramel", (0.72, 0.405, 0.18, 1.0), 0.94)
    cream = make_material("MAT_V11_Urajiro", (0.91, 0.79, 0.63, 1.0), 0.96)
    ink = make_material("MAT_V11_Features", (0.008, 0.005, 0.004, 1.0), 0.25)
    mouth_inner = make_material("MAT_V11_MouthInner", (0.055, 0.016, 0.012, 1.0), 0.58)
    tooth = make_material("MAT_V11_Tooth", (0.94, 0.87, 0.73, 1.0), 0.78)
    glint = make_material("MAT_V11_EyeGlint", (1.0, 0.96, 0.88, 1.0), 0.10)

    def ramp(edge_0: float, edge_1: float, value: float) -> float:
        amount = max(0.0, min(1.0, (value - edge_0) / (edge_1 - edge_0)))
        return amount * amount * (3.0 - 2.0 * amount)

    def owner_cream_mask(position: Vector) -> float:
        front = ramp(0.50, 0.78, -position.y)
        face_floor = ramp(0.82, 0.99, position.z)
        face_ceiling = 1.0 - ramp(1.40, 1.56, position.z)
        face_width = 1.0 - ramp(0.50, 0.79, abs(position.x))
        face = front * face_floor * face_ceiling * face_width
        chest_floor = ramp(0.19, 0.34, position.z)
        chest_ceiling = 1.0 - ramp(0.88, 1.04, position.z)
        chest_width = 1.0 - ramp(0.42, 0.72, abs(position.x))
        chest = front * chest_floor * chest_ceiling * chest_width
        return max(face, chest * 0.94)

    def owner_weights(position: Vector) -> dict[str, float]:
        head_weight = ramp(0.48, 0.86, -position.y) * ramp(0.72, 1.00, position.z)
        head_weight = min(0.82, head_weight)
        return {"body": 1.0 - head_weight, "head": head_weight}

    # The face planes are fused into the body before remeshing so the profile is
    # one continuous sculpted surface rather than floating cream components.
    body = fused_surface(
        "MainFusedBody",
        [
            ((0, 0.08, 0.96), (1.08, 0.82, 0.92)),
            ((-0.235, -0.68, 1.14), (0.35, 0.20, 0.26)),
            ((0.235, -0.68, 1.14), (0.35, 0.20, 0.26)),
            ((0, -0.79, 1.105), (0.32, 0.22, 0.17)),
        ],
        (caramel, cream),
        rig,
        owner_weights,
        owner_cream_mask,
    )
    for vertex in body.data.vertices:
        position = (body.matrix_world @ vertex.co) / SCALE
        if position.z < 0.18:
            vertex.co.z += (0.18 - position.z) * 0.72 * SCALE
    body.data.update()

    for side, sign in (("L", -1), ("R", 1)):
        uv_sphere(f"Eye_{side}", (0.255 * sign, -0.755, 1.385), (0.058, 0.027, 0.040), ink, rig, "head", 32, 18)
        uv_sphere(f"EyeGlint_{side}", (0.238 * sign, -0.781, 1.402), (0.008, 0.003, 0.006), glint, rig, "head", 10, 6)
        # Paws are intentionally tiny and planted. No long foreleg silhouette.
        uv_sphere(f"Forepaw_{side}", (0.62 * sign, -0.555, 0.245), (0.185, 0.205, 0.145), caramel, rig, f"paw_{side}", 38, 22)
        uv_sphere(f"ToeCap_{side}", (0.62 * sign, -0.725, 0.205), (0.135, 0.035, 0.060), cream, rig, f"paw_{side}", 28, 16)

    uv_sphere("Nose", (0, -1.005, 1.115), (0.105, 0.062, 0.070), ink, rig, "muzzle", 36, 20)
    uv_sphere("MouthOpening", (0, -0.985, 1.005), (0.215, 0.026, 0.065), mouth_inner, rig, "muzzle", 42, 20)
    smile_curve("Smile_L", [(0, -1.015, 1.045), (-0.075, -1.012, 1.000), (-0.175, -0.985, 1.035)], ink, rig, "muzzle", 0.010)
    smile_curve("Smile_R", [(0, -1.015, 1.045), (0.075, -1.012, 1.000), (0.175, -0.985, 1.035)], ink, rig, "muzzle", 0.010)
    cube("LowerTooth", (0, -1.015, 0.990), (0.045, 0.010, 0.012), tooth, rig, "muzzle", 0.008)

    body["visual_reference"] = "assets/concepts/pipi-labu-owner-reconstruction-sheet-v11.png; original reel owner face sequence"
    body["top_ear_policy"] = "No ear geometry; uninterrupted round crown is absolute"
    body["tail_policy"] = "No tail geometry for the counter-anchored owner"
    body["promotion_status"] = "CANDIDATE_ONLY_PENDING_REGISTERED_AND_STUDIO_REVIEW"
    body["fidelity_pass"] = "v11 reel-driven room-orb reconstruction"
    fur_tile = Path(__file__).resolve().parents[1] / "assets" / "textures" / "peepilabu" / "shiba_short_fur_tile_v1.png"
    apply_fur_tile(body, fur_tile)
    surface_maps = bake_body_surface_maps(body, texture_size=1024)
    body["surface_maps"] = json.dumps(surface_maps, sort_keys=True)


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


def build_markers_v2(rig: bpy.types.Object) -> None:
    marker = bpy.data.objects.new("COLLISION_ROOT", None)
    bpy.context.collection.objects.link(marker)
    marker.empty_display_type = "CUBE"
    marker.empty_display_size = 1.0 * SCALE
    marker.scale = (0.55, 0.88, 0.58) if VARIANT == "customer" else (1.15, 0.78, 1.45)
    marker.location = Vector((0, 0.02, 0.60 if VARIANT == "customer" else 1.45)) * SCALE
    marker.parent = rig
    marker["roblox_collision_proxy"] = True
    marker["recommended_can_collide"] = False

    bone_empty("ATTACH_Fruit_R", rig, "paw_FR", (0.0, -0.18, 0.06), "SPHERE", 0.11)
    bone_empty("ATTACH_Fruit_L", rig, "paw_FL", (0.0, -0.18, 0.06), "SPHERE", 0.11)
    bone_empty("ATTACH_Mouth", rig, "head", (0, -1.55, 0.72), "ARROWS", 0.10)
    bone_empty("ATTACH_Back", rig, "spine", (0, 0.40, 0.82), "ARROWS", 0.12)
    bone_empty("ATTACH_ShopkeeperProp", rig, "paw_FL", (0, -0.20, 0.04), "CUBE", 0.12)
    billboard_z = 3.25 if VARIANT == "owner" else 1.75
    bone_empty("ATTACH_OrderBillboard", rig, "head", (0, 0, billboard_z), "PLAIN_AXES", 0.14)


def build_markers_v3(rig: bpy.types.Object) -> None:
    marker = bpy.data.objects.new("COLLISION_ROOT", None)
    bpy.context.collection.objects.link(marker)
    marker.empty_display_type = "CUBE"
    marker.empty_display_size = 1.0 * SCALE
    marker.scale = (0.54, 0.42, 1.12)
    marker.location = Vector((0, 0, 1.12)) * SCALE
    marker.parent = rig
    marker["roblox_collision_proxy"] = True
    marker["recommended_can_collide"] = False

    bone_empty("ATTACH_Fruit_R", rig, "hand_R", (0, -0.18, 0.02), "SPHERE", 0.11)
    bone_empty("ATTACH_Fruit_L", rig, "hand_L", (0, -0.18, 0.02), "SPHERE", 0.11)
    bone_empty("ATTACH_Mouth", rig, "head", (0, -0.82, 1.72), "ARROWS", 0.10)
    bone_empty("ATTACH_Back", rig, "chest", (0, 0.48, 1.45), "ARROWS", 0.12)
    bone_empty("ATTACH_ShopkeeperProp", rig, "hand_L", (0, -0.20, 0.04), "CUBE", 0.12)
    bone_empty("ATTACH_OrderBillboard", rig, "head", (0, 0, 2.75), "PLAIN_AXES", 0.14)


def build_markers_v4(rig: bpy.types.Object) -> None:
    marker = bpy.data.objects.new("COLLISION_ROOT", None)
    bpy.context.collection.objects.link(marker)
    marker.empty_display_type = "CUBE"
    marker.empty_display_size = 1.0 * SCALE
    marker.scale = (0.92, 0.70, 1.03)
    marker.location = Vector((0, 0, 1.03)) * SCALE
    marker.parent = rig
    marker["roblox_collision_proxy"] = True
    marker["recommended_can_collide"] = False

    bone_empty("ATTACH_Fruit_R", rig, "paw_R", (0, -0.18, 0.10), "SPHERE", 0.13)
    bone_empty("ATTACH_Fruit_L", rig, "paw_L", (0, -0.18, 0.10), "SPHERE", 0.13)
    bone_empty("ATTACH_Mouth", rig, "muzzle", (0, -0.86, 1.19), "ARROWS", 0.10)
    bone_empty("ATTACH_Back", rig, "body", (0, 0.72, 1.22), "ARROWS", 0.12)
    bone_empty("ATTACH_ShopkeeperProp", rig, "paw_L", (0, -0.20, 0.10), "CUBE", 0.13)
    bone_empty("ATTACH_OrderBillboard", rig, "head", (0, 0, 2.52), "PLAIN_AXES", 0.14)


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


def build_actions_v2(rig: bpy.types.Object) -> None:
    rig.animation_data_create()
    make_action(rig, "Pipilabu_Idle", 40, {
        1: {
            "spine": {"location": (0, 0, 0), "scale": (1, 1, 1)},
            "head": {"rotation_euler": (0, 0, -0.035)},
            "tail": {"rotation_euler": (0, 0.08, -0.10)},
        },
        20: {
            "spine": {"location": (0, 0, 0.018 * SCALE), "scale": (1.012, 1.018, 0.985)},
            "head": {"rotation_euler": (0.025, 0, 0.035)},
            "tail": {"rotation_euler": (0, -0.08, 0.10)},
        },
        40: {
            "spine": {"location": (0, 0, 0), "scale": (1, 1, 1)},
            "head": {"rotation_euler": (0, 0, -0.035)},
            "tail": {"rotation_euler": (0, 0.08, -0.10)},
        },
    })
    make_action(rig, "Pipilabu_Receive", 30, {
        1: {
            "leg_FL": {"rotation_euler": (0, 0, 0)},
            "leg_FR": {"rotation_euler": (0, 0, 0)},
            "jaw": {"rotation_euler": (0, 0, 0)},
        },
        12: {
            "spine": {"rotation_euler": (math.radians(-5), 0, 0)},
            "head": {"rotation_euler": (math.radians(9), 0, 0)},
            "leg_FL": {"rotation_euler": (math.radians(-58), 0, math.radians(-5))},
            "leg_FR": {"rotation_euler": (math.radians(-58), 0, math.radians(5))},
            "paw_FL": {"rotation_euler": (math.radians(22), 0, 0)},
            "paw_FR": {"rotation_euler": (math.radians(22), 0, 0)},
            "jaw": {"rotation_euler": (math.radians(11), 0, 0)},
        },
        22: {
            "head": {"rotation_euler": (math.radians(-4), 0, math.radians(3))},
            "leg_FL": {"rotation_euler": (math.radians(-44), 0, math.radians(-4))},
            "leg_FR": {"rotation_euler": (math.radians(-44), 0, math.radians(4))},
            "jaw": {"rotation_euler": (0, 0, 0)},
        },
        30: {
            "leg_FL": {"rotation_euler": (math.radians(-42), 0, math.radians(-4))},
            "leg_FR": {"rotation_euler": (math.radians(-42), 0, math.radians(4))},
        },
    })
    make_action(rig, "Pipilabu_Hold", 40, {
        1: {
            "leg_FL": {"rotation_euler": (math.radians(-42), 0, math.radians(-4))},
            "leg_FR": {"rotation_euler": (math.radians(-42), 0, math.radians(4))},
            "head": {"rotation_euler": (0.04, 0, -0.05)},
        },
        20: {
            "leg_FL": {"rotation_euler": (math.radians(-46), 0, math.radians(-4))},
            "leg_FR": {"rotation_euler": (math.radians(-46), 0, math.radians(4))},
            "head": {"rotation_euler": (0.01, 0, 0.05)},
            "tail": {"rotation_euler": (0, 0, 0.14)},
        },
        40: {
            "leg_FL": {"rotation_euler": (math.radians(-42), 0, math.radians(-4))},
            "leg_FR": {"rotation_euler": (math.radians(-42), 0, math.radians(4))},
            "head": {"rotation_euler": (0.04, 0, -0.05)},
        },
    })
    make_action(rig, "Pipilabu_TurnLeave", 48, {
        1: {"root": {"location": (0, 0, 0), "rotation_euler": (0, 0, 0)}},
        16: {
            "root": {"location": (0, 0, 0), "rotation_euler": (0, 0, math.radians(90))},
            "head": {"rotation_euler": (0, 0, math.radians(-18))},
        },
        24: {
            "root": {"location": (0.42 * SCALE, 0, 0), "rotation_euler": (0, 0, math.radians(90))},
            "leg_FL": {"rotation_euler": (math.radians(18), 0, 0)},
            "leg_BR": {"rotation_euler": (math.radians(18), 0, 0)},
            "leg_FR": {"rotation_euler": (math.radians(-18), 0, 0)},
            "leg_BL": {"rotation_euler": (math.radians(-18), 0, 0)},
        },
        36: {
            "root": {"location": (0.90 * SCALE, 0, 0), "rotation_euler": (0, 0, math.radians(90))},
            "leg_FL": {"rotation_euler": (math.radians(-18), 0, 0)},
            "leg_BR": {"rotation_euler": (math.radians(-18), 0, 0)},
            "leg_FR": {"rotation_euler": (math.radians(18), 0, 0)},
            "leg_BL": {"rotation_euler": (math.radians(18), 0, 0)},
        },
        48: {
            "root": {"location": (1.50 * SCALE, 0, 0), "rotation_euler": (0, 0, math.radians(90))},
            "leg_FL": {"rotation_euler": (math.radians(18), 0, 0)},
            "leg_BR": {"rotation_euler": (math.radians(18), 0, 0)},
            "leg_FR": {"rotation_euler": (math.radians(-18), 0, 0)},
            "leg_BL": {"rotation_euler": (math.radians(-18), 0, 0)},
        },
    })
    reset_pose(rig)


def build_actions_v3(rig: bpy.types.Object) -> None:
    rig.animation_data_create()
    make_action(rig, "Pipilabu_Idle", 40, {
        1: {
            "spine": {"location": (0, 0, 0), "scale": (1, 1, 1)},
            "head": {"rotation_euler": (0, 0, -0.025)},
            "tail": {"rotation_euler": (0, 0.08, -0.08)},
        },
        20: {
            "spine": {"location": (0, 0, 0.018 * SCALE), "scale": (1.008, 1.010, 0.992)},
            "head": {"rotation_euler": (0.020, 0, 0.025)},
            "tail": {"rotation_euler": (0, -0.08, 0.08)},
        },
        40: {
            "spine": {"location": (0, 0, 0), "scale": (1, 1, 1)},
            "head": {"rotation_euler": (0, 0, -0.025)},
            "tail": {"rotation_euler": (0, 0.08, -0.08)},
        },
    })
    make_action(rig, "Pipilabu_Walk", 32, {
        1: {
            "upper_leg_L": {"rotation_euler": (math.radians(18), 0, 0)},
            "upper_leg_R": {"rotation_euler": (math.radians(-18), 0, 0)},
            "upper_arm_L": {"rotation_euler": (math.radians(-14), 0, 0)},
            "upper_arm_R": {"rotation_euler": (math.radians(14), 0, 0)},
        },
        9: {"root": {"location": (0, 0, 0.025 * SCALE)}},
        17: {
            "upper_leg_L": {"rotation_euler": (math.radians(-18), 0, 0)},
            "upper_leg_R": {"rotation_euler": (math.radians(18), 0, 0)},
            "upper_arm_L": {"rotation_euler": (math.radians(14), 0, 0)},
            "upper_arm_R": {"rotation_euler": (math.radians(-14), 0, 0)},
        },
        25: {"root": {"location": (0, 0, 0.025 * SCALE)}},
        32: {
            "upper_leg_L": {"rotation_euler": (math.radians(18), 0, 0)},
            "upper_leg_R": {"rotation_euler": (math.radians(-18), 0, 0)},
            "upper_arm_L": {"rotation_euler": (math.radians(-14), 0, 0)},
            "upper_arm_R": {"rotation_euler": (math.radians(14), 0, 0)},
        },
    })
    make_action(rig, "Pipilabu_Carry", 40, {
        1: {
            "upper_arm_L": {"rotation_euler": (math.radians(-48), 0, math.radians(-10))},
            "upper_arm_R": {"rotation_euler": (math.radians(-48), 0, math.radians(10))},
            "forearm_L": {"rotation_euler": (math.radians(-48), 0, 0)},
            "forearm_R": {"rotation_euler": (math.radians(-48), 0, 0)},
            "head": {"rotation_euler": (0.04, 0, -0.03)},
        },
        20: {
            "upper_arm_L": {"rotation_euler": (math.radians(-51), 0, math.radians(-10))},
            "upper_arm_R": {"rotation_euler": (math.radians(-51), 0, math.radians(10))},
            "head": {"rotation_euler": (0.01, 0, 0.03)},
        },
        40: {
            "upper_arm_L": {"rotation_euler": (math.radians(-48), 0, math.radians(-10))},
            "upper_arm_R": {"rotation_euler": (math.radians(-48), 0, math.radians(10))},
            "forearm_L": {"rotation_euler": (math.radians(-48), 0, 0)},
            "forearm_R": {"rotation_euler": (math.radians(-48), 0, 0)},
            "head": {"rotation_euler": (0.04, 0, -0.03)},
        },
    })
    make_action(rig, "Pipilabu_Serve", 30, {
        1: {
            "upper_arm_R": {"rotation_euler": (math.radians(-48), 0, math.radians(8))},
            "forearm_R": {"rotation_euler": (math.radians(-48), 0, 0)},
        },
        13: {
            "chest": {"rotation_euler": (math.radians(-7), 0, 0)},
            "upper_arm_R": {"rotation_euler": (math.radians(-78), 0, math.radians(8))},
            "forearm_R": {"rotation_euler": (math.radians(-18), 0, 0)},
            "head": {"rotation_euler": (math.radians(5), 0, 0)},
        },
        20: {
            "chest": {"rotation_euler": (math.radians(3), 0, 0)},
            "upper_arm_R": {"rotation_euler": (math.radians(-86), 0, math.radians(6))},
            "forearm_R": {"rotation_euler": (0, 0, 0)},
        },
        30: {
            "upper_arm_R": {"rotation_euler": (math.radians(-48), 0, math.radians(8))},
            "forearm_R": {"rotation_euler": (math.radians(-48), 0, 0)},
        },
    })
    make_action(rig, "Pipilabu_Happy", 32, {
        1: {
            "spine": {"scale": (1, 1, 1)},
            "ear_L": {"rotation_euler": (0, 0, 0)},
            "ear_R": {"rotation_euler": (0, 0, 0)},
        },
        10: {
            "spine": {"location": (0, 0, 0.08 * SCALE), "scale": (1.08, 1.06, 0.91)},
            "ear_L": {"rotation_euler": (0, math.radians(-12), math.radians(-9))},
            "ear_R": {"rotation_euler": (0, math.radians(12), math.radians(9))},
            "head": {"rotation_euler": (math.radians(-6), 0, 0)},
        },
        20: {
            "spine": {"location": (0, 0, -0.025 * SCALE), "scale": (0.96, 0.98, 1.05)},
            "ear_L": {"rotation_euler": (0, math.radians(8), math.radians(6))},
            "ear_R": {"rotation_euler": (0, math.radians(-8), math.radians(-6))},
        },
        32: {
            "spine": {"scale": (1, 1, 1)},
            "ear_L": {"rotation_euler": (0, 0, 0)},
            "ear_R": {"rotation_euler": (0, 0, 0)},
        },
    })
    reset_pose(rig)


def build_actions_v4(rig: bpy.types.Object) -> None:
    if VARIANT == "customer":
        build_customer_actions_v4(rig)
        return

    rig.animation_data_create()
    make_action(rig, "Pipilabu_Idle", 48, {
        1: {
            "body": {"scale": (1, 1, 1)},
            "head": {"rotation_euler": (0, 0, math.radians(-1.5))},
            "ear_L": {"rotation_euler": (0, 0, 0)},
            "ear_R": {"rotation_euler": (0, 0, 0)},
        },
        24: {
            "body": {"location": (0, 0, 0.014 * SCALE), "scale": (1.006, 1.008, 0.994)},
            "head": {"rotation_euler": (math.radians(1.0), 0, math.radians(1.5))},
            "ear_L": {"rotation_euler": (0, math.radians(-2), math.radians(-2))},
            "ear_R": {"rotation_euler": (0, math.radians(2), math.radians(2))},
        },
        48: {
            "body": {"scale": (1, 1, 1)},
            "head": {"rotation_euler": (0, 0, math.radians(-1.5))},
        },
    })
    talk_key_10 = {"head": {"rotation_euler": (math.radians(-3), 0, math.radians(2))}}
    talk_key_20 = {"head": {"rotation_euler": (math.radians(2), 0, math.radians(-1))}}
    if MODEL_VERSION not in {"v6", "v7", "v8", "v11"}:
        talk_key_10["muzzle"] = {"rotation_euler": (math.radians(4), 0, 0)}
        talk_key_20["muzzle"] = {"rotation_euler": (math.radians(-2), 0, 0)}
    make_action(rig, "Pipilabu_Talk", 32, {
        1: {"head": {"rotation_euler": (0, 0, math.radians(-2))}},
        10: talk_key_10,
        20: talk_key_20,
        32: {"head": {"rotation_euler": (0, 0, math.radians(-2))}},
    })
    make_action(rig, "Pipilabu_Serve", 34, {
        1: {"paw_R": {"rotation_euler": (0, 0, 0)}},
        13: {
            "body": {"rotation_euler": (math.radians(-3), 0, 0)},
            "head": {"rotation_euler": (math.radians(3), 0, 0)},
            "paw_R": {"rotation_euler": (math.radians(-28), 0, math.radians(5)), "location": (0, -0.10 * SCALE, 0.10 * SCALE)},
        },
        22: {
            "paw_R": {"rotation_euler": (math.radians(-38), 0, math.radians(6)), "location": (0, -0.18 * SCALE, 0.15 * SCALE)},
        },
        34: {"paw_R": {"rotation_euler": (0, 0, 0)}},
    })
    make_action(rig, "Pipilabu_Happy", 36, {
        1: {"body": {"scale": (1, 1, 1)}},
        10: {
            "body": {"location": (0, 0, 0.055 * SCALE), "scale": (1.035, 1.035, 0.96)},
            "head": {"rotation_euler": (math.radians(-4), 0, 0)},
            "paw_L": {"rotation_euler": (math.radians(-16), 0, math.radians(-4))},
            "paw_R": {"rotation_euler": (math.radians(-16), 0, math.radians(4))},
        },
        22: {
            "body": {"location": (0, 0, -0.018 * SCALE), "scale": (0.98, 0.99, 1.025)},
            "ear_L": {"rotation_euler": (0, math.radians(-7), math.radians(-6))},
            "ear_R": {"rotation_euler": (0, math.radians(7), math.radians(6))},
        },
        36: {"body": {"scale": (1, 1, 1)}},
    })
    make_action(rig, "Pipilabu_Stressed", 44, {
        1: {"head": {"rotation_euler": (0, 0, math.radians(-4))}},
        12: {
            "head": {"rotation_euler": (math.radians(2), 0, math.radians(5))},
            "ear_L": {"rotation_euler": (math.radians(12), 0, math.radians(-12))},
            "ear_R": {"rotation_euler": (math.radians(12), 0, math.radians(12))},
        },
        24: {"head": {"rotation_euler": (math.radians(-2), 0, math.radians(-5))}},
        34: {"head": {"rotation_euler": (math.radians(2), 0, math.radians(4))}},
        44: {"head": {"rotation_euler": (0, 0, math.radians(-4))}},
    })
    reset_pose(rig)


def build_customer_actions_v4(rig: bpy.types.Object) -> None:
    """Author compact customer reactions plus an in-place, bouncy little run."""
    rig.animation_data_create()
    make_action(rig, "Pipilabu_Idle", 48, {
        1: {
            "body": {"scale": (1, 1, 1)},
            "head": {"rotation_euler": (0, 0, math.radians(-2))},
            "tail": {"rotation_euler": (0, math.radians(5), math.radians(-7))},
        },
        24: {
            "body": {"location": (0, 0, 0.018 * SCALE), "scale": (1.008, 1.012, 0.989)},
            "head": {"rotation_euler": (math.radians(1.5), 0, math.radians(2))},
            "ear_L": {"rotation_euler": (0, math.radians(-3), math.radians(-2))},
            "ear_R": {"rotation_euler": (0, math.radians(3), math.radians(2))},
            "tail": {"rotation_euler": (0, math.radians(-5), math.radians(7))},
        },
        48: {
            "body": {"scale": (1, 1, 1)},
            "head": {"rotation_euler": (0, 0, math.radians(-2))},
            "tail": {"rotation_euler": (0, math.radians(5), math.radians(-7))},
        },
    })
    make_action(rig, "Pipilabu_Receive", 30, {
        1: {
            "body": {"scale": (1, 1, 1)},
            "paw_L": {"rotation_euler": (0, 0, 0)},
            "paw_R": {"rotation_euler": (0, 0, 0)},
        },
        11: {
            "body": {"rotation_euler": (math.radians(-4), 0, 0), "scale": (1.025, 1.025, 0.975)},
            "head": {"rotation_euler": (math.radians(5), 0, 0)},
            "paw_L": {"rotation_euler": (math.radians(-30), 0, math.radians(-7)), "location": (0, -0.11 * SCALE, 0.10 * SCALE)},
            "paw_R": {"rotation_euler": (math.radians(-30), 0, math.radians(7)), "location": (0, -0.11 * SCALE, 0.10 * SCALE)},
            "ear_L": {"rotation_euler": (0, 0, math.radians(-5))},
            "ear_R": {"rotation_euler": (0, 0, math.radians(5))},
        },
        20: {
            "body": {"location": (0, 0, 0.045 * SCALE), "scale": (1.045, 1.04, 0.95)},
            "paw_L": {"rotation_euler": (math.radians(-40), 0, math.radians(-9)), "location": (0, -0.16 * SCALE, 0.13 * SCALE)},
            "paw_R": {"rotation_euler": (math.radians(-40), 0, math.radians(9)), "location": (0, -0.16 * SCALE, 0.13 * SCALE)},
            "tail": {"rotation_euler": (0, math.radians(-11), math.radians(13))},
        },
        30: {
            "body": {"scale": (1, 1, 1)},
            "paw_L": {"rotation_euler": (math.radians(-34), 0, math.radians(-7)), "location": (0, -0.12 * SCALE, 0.10 * SCALE)},
            "paw_R": {"rotation_euler": (math.radians(-34), 0, math.radians(7)), "location": (0, -0.12 * SCALE, 0.10 * SCALE)},
        },
    })
    make_action(rig, "Pipilabu_Hold", 40, {
        1: {
            "paw_L": {"rotation_euler": (math.radians(-34), 0, math.radians(-7)), "location": (0, -0.12 * SCALE, 0.10 * SCALE)},
            "paw_R": {"rotation_euler": (math.radians(-34), 0, math.radians(7)), "location": (0, -0.12 * SCALE, 0.10 * SCALE)},
            "head": {"rotation_euler": (math.radians(2), 0, math.radians(-2))},
        },
        20: {
            "body": {"location": (0, 0, 0.015 * SCALE), "scale": (1.008, 1.01, 0.992)},
            "paw_L": {"rotation_euler": (math.radians(-37), 0, math.radians(-7)), "location": (0, -0.13 * SCALE, 0.105 * SCALE)},
            "paw_R": {"rotation_euler": (math.radians(-37), 0, math.radians(7)), "location": (0, -0.13 * SCALE, 0.105 * SCALE)},
            "head": {"rotation_euler": (0, 0, math.radians(2))},
            "tail": {"rotation_euler": (0, math.radians(-8), math.radians(11))},
        },
        40: {
            "paw_L": {"rotation_euler": (math.radians(-34), 0, math.radians(-7)), "location": (0, -0.12 * SCALE, 0.10 * SCALE)},
            "paw_R": {"rotation_euler": (math.radians(-34), 0, math.radians(7)), "location": (0, -0.12 * SCALE, 0.10 * SCALE)},
            "head": {"rotation_euler": (math.radians(2), 0, math.radians(-2))},
        },
    })
    make_action(rig, "Pipilabu_Happy", 30, {
        1: {"body": {"scale": (1, 1, 1)}},
        9: {
            "body": {"location": (0, 0, 0.075 * SCALE), "scale": (1.055, 1.055, 0.94)},
            "head": {"rotation_euler": (math.radians(-5), 0, 0)},
            "paw_L": {"rotation_euler": (math.radians(-18), 0, math.radians(-6))},
            "paw_R": {"rotation_euler": (math.radians(-18), 0, math.radians(6))},
        },
        18: {
            "body": {"location": (0, 0, -0.015 * SCALE), "scale": (0.98, 0.99, 1.03)},
            "ear_L": {"rotation_euler": (0, math.radians(-9), math.radians(-8))},
            "ear_R": {"rotation_euler": (0, math.radians(9), math.radians(8))},
            "tail": {"rotation_euler": (0, math.radians(-13), math.radians(16))},
        },
        30: {"body": {"scale": (1, 1, 1)}},
    })
    make_action(rig, "Pipilabu_TurnLeave", 48, {
        1: {"root": {"location": (0, 0, 0), "rotation_euler": (0, 0, 0)}},
        12: {
            "root": {"rotation_euler": (0, 0, math.radians(38))},
            "body": {"location": (0, 0, 0.05 * SCALE), "rotation_euler": (0, 0, math.radians(-5))},
            "head": {"rotation_euler": (0, 0, math.radians(-10))},
        },
        24: {
            "root": {"location": (0.42 * SCALE, 0, 0), "rotation_euler": (0, 0, math.radians(90))},
            "body": {"location": (0, 0, 0.02 * SCALE), "rotation_euler": (0, 0, math.radians(5))},
            "paw_L": {"rotation_euler": (math.radians(13), 0, math.radians(-6))},
            "paw_R": {"rotation_euler": (math.radians(-13), 0, math.radians(6))},
        },
        36: {
            "root": {"location": (0.88 * SCALE, 0, 0), "rotation_euler": (0, 0, math.radians(90))},
            "body": {"location": (0, 0, 0.065 * SCALE), "rotation_euler": (0, 0, math.radians(-5))},
            "paw_L": {"rotation_euler": (math.radians(-13), 0, math.radians(-6))},
            "paw_R": {"rotation_euler": (math.radians(13), 0, math.radians(6))},
        },
        48: {
            "root": {"location": (1.35 * SCALE, 0, 0), "rotation_euler": (0, 0, math.radians(90))},
            "body": {"location": (0, 0, 0.02 * SCALE), "rotation_euler": (0, 0, math.radians(5))},
        },
    })
    make_action(rig, "Pipilabu_Run", 24, {
        1: {
            "body": {"location": (0, 0, 0.025 * SCALE), "rotation_euler": (0, 0, math.radians(-4)), "scale": (1.015, 1.01, 0.985)},
            "paw_L": {"rotation_euler": (math.radians(16), 0, math.radians(-5))},
            "paw_R": {"rotation_euler": (math.radians(-16), 0, math.radians(5))},
            "tail": {"rotation_euler": (0, math.radians(8), math.radians(-11))},
        },
        7: {
            "body": {"location": (0, 0, 0.085 * SCALE), "rotation_euler": (0, 0, 0), "scale": (1.035, 1.025, 0.96)},
            "head": {"rotation_euler": (math.radians(-3), 0, 0)},
            "paw_L": {"rotation_euler": (math.radians(-8), 0, math.radians(-5))},
            "paw_R": {"rotation_euler": (math.radians(8), 0, math.radians(5))},
        },
        13: {
            "body": {"location": (0, 0, 0.025 * SCALE), "rotation_euler": (0, 0, math.radians(4)), "scale": (1.015, 1.01, 0.985)},
            "paw_L": {"rotation_euler": (math.radians(-16), 0, math.radians(-5))},
            "paw_R": {"rotation_euler": (math.radians(16), 0, math.radians(5))},
            "tail": {"rotation_euler": (0, math.radians(-8), math.radians(11))},
        },
        19: {
            "body": {"location": (0, 0, 0.085 * SCALE), "rotation_euler": (0, 0, 0), "scale": (1.035, 1.025, 0.96)},
            "head": {"rotation_euler": (math.radians(-3), 0, 0)},
            "paw_L": {"rotation_euler": (math.radians(8), 0, math.radians(-5))},
            "paw_R": {"rotation_euler": (math.radians(-8), 0, math.radians(5))},
        },
        24: {
            "body": {"location": (0, 0, 0.025 * SCALE), "rotation_euler": (0, 0, math.radians(-4)), "scale": (1.015, 1.01, 0.985)},
            "paw_L": {"rotation_euler": (math.radians(16), 0, math.radians(-5))},
            "paw_R": {"rotation_euler": (math.radians(-16), 0, math.radians(5))},
            "tail": {"rotation_euler": (0, math.radians(8), math.radians(-11))},
        },
    })
    reset_pose(rig)


def collect_metrics(rig: bpy.types.Object) -> dict[str, object]:
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH" and not obj.name.startswith("PREVIEW_")]
    mesh_triangles = {
        obj.name: sum(len(poly.vertices) - 2 for poly in obj.data.polygons)
        for obj in meshes
    }
    if MODEL_VERSION in {"v6", "v7", "v8", "v11"}:
        base_bounds = [1.95, 2.30, 1.05] if VARIANT == "customer" else [2.25, 2.15, 2.35]
    elif MODEL_VERSION == "v5":
        base_bounds = [2.30, 2.55, 1.35] if VARIANT == "customer" else [2.20, 2.05, 2.35]
    elif MODEL_VERSION == "v4":
        base_bounds = [2.25, 2.05, 2.50]
    elif MODEL_VERSION == "v3":
        base_bounds = [1.85, 1.55, 2.55]
    elif MODEL_VERSION == "v2":
        base_bounds = [2.75, 1.18, 1.48] if VARIANT == "customer" else [2.60, 2.10, 2.96]
    else:
        base_bounds = [1.75, 2.05, 3.15]
    body = bpy.context.scene.objects.get("MainFusedBody")
    surface_maps = json.loads(body.get("surface_maps", "{}")) if body else {}
    return {
        "generator_version": SCRIPT_VERSION,
        "model_version": MODEL_VERSION,
        "blender_version": bpy.app.version_string,
        "variant": VARIANT,
        "scale_multiplier": SCALE,
        "mesh_objects": len(meshes),
        "vertices": sum(len(obj.data.vertices) for obj in meshes),
        "triangles": sum(len(poly.vertices) - 2 for obj in meshes for poly in obj.data.polygons),
        "largest_mesh_triangles": max(mesh_triangles.values(), default=0),
        "meshes_over_20000_triangles": sorted(name for name, count in mesh_triangles.items() if count > 20000),
        "bones": len(rig.data.bones),
        "actions": sorted(action.name for action in bpy.data.actions),
        "attachments": sorted(obj.name for obj in bpy.context.scene.objects if obj.name.startswith("ATTACH_")),
        "collision_marker": "COLLISION_ROOT",
        "bounds_meters_approx": [round(value * SCALE, 3) for value in base_bounds],
        "surface_maps": surface_maps,
    }


def render_preview() -> Path:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 768
    scene.render.resolution_y = 768
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False

    world = bpy.data.worlds.new("PipilabuPreviewWorld") if not scene.world else scene.world
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.38, 0.31, 0.24, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.48
    scene.view_settings.exposure = -0.10
    try:
        scene.view_settings.look = "AgX - Medium High Contrast"
    except TypeError:
        pass

    if MODEL_VERSION in {"v5", "v6", "v7", "v8", "v11"} and VARIANT == "customer":
        target = Vector((0, -0.25, 0.58 * SCALE))
        beauty_location = Vector((3.15, -5.8, 1.65)) * SCALE
    elif MODEL_VERSION in {"v5", "v6", "v7", "v8", "v11"}:
        target = Vector((0, -0.10, 1.08 * SCALE))
        beauty_location = Vector((3.45, -6.6, 2.65)) * SCALE
    elif MODEL_VERSION == "v4":
        target = Vector((0, -0.10, 1.12 * SCALE))
        beauty_location = Vector((3.45, -6.6, 2.70)) * SCALE
    elif MODEL_VERSION == "v3":
        target = Vector((0, -0.05, 1.28 * SCALE))
        beauty_location = Vector((3.6, -6.6, 2.75)) * SCALE
    elif MODEL_VERSION == "v2" and VARIANT == "customer":
        target = Vector((0, -0.20, 0.68 * SCALE))
        beauty_location = Vector((3.2, -5.7, 1.55)) * SCALE
    elif MODEL_VERSION == "v2":
        target = Vector((0, -0.20, 1.55 * SCALE))
        beauty_location = Vector((3.8, -7.3, 2.75)) * SCALE
    else:
        target = Vector((0, 0, 1.52 * SCALE))
        beauty_location = Vector((4.2, -7.8, 3.8)) * SCALE
    camera_data = bpy.data.cameras.new("PREVIEW_Camera")
    camera = bpy.data.objects.new("PREVIEW_Camera", camera_data)
    bpy.context.collection.objects.link(camera)
    camera.location = beauty_location
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera_data.lens = 64
    scene.camera = camera

    ground_material = make_material("PREVIEW_GroundMaterial", (0.52, 0.42, 0.32, 1.0), 0.98)
    bpy.ops.mesh.primitive_plane_add(size=20 * SCALE, location=(0, 0, 0))
    ground = bpy.context.object
    ground.name = "PREVIEW_Ground"
    ground.data.materials.append(ground_material)
    if MODEL_VERSION in {"v4", "v5", "v6", "v7", "v8", "v11"} and VARIANT == "owner":
        counter_material = make_material("PREVIEW_CounterMaterial", (0.33, 0.19, 0.10, 1.0), 0.86)
        bpy.ops.mesh.primitive_cube_add(location=(0, -1.28 * SCALE, 0.07 * SCALE))
        counter = bpy.context.object
        counter.name = "PREVIEW_Counter"
        counter.scale = (1.58 * SCALE, 0.72 * SCALE, 0.07 * SCALE)
        counter.data.materials.append(counter_material)

    for name, location, energy, size, color in (
        ("PREVIEW_Key", (-4.5, -4.0, 6.2), 650, 4.5, (1.0, 0.76, 0.54)),
        ("PREVIEW_Fill", (4.8, -2.2, 4.2), 360, 4.0, (0.76, 0.82, 1.0)),
        ("PREVIEW_Rim", (0, 4.5, 5.0), 450, 3.5, (1.0, 0.60, 0.36)),
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

    views = {
        "preview": beauty_location,
        "front": Vector((0, -7.0, 2.25)) * SCALE,
        "side": Vector((7.0, 0, 2.25)) * SCALE,
        "back": Vector((0, 7.0, 2.25)) * SCALE,
    }
    preview_path = OUTPUT_DIR / f"{STEM}.preview.png"
    for label, location in views.items():
        camera.location = location
        camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
        output_path = preview_path if label == "preview" else OUTPUT_DIR / f"{STEM}.{label}.png"
        scene.render.filepath = str(output_path)
        bpy.ops.render.render(write_still=True)
    if MODEL_VERSION in {"v4", "v5", "v6", "v7", "v8"} and VARIANT == "customer":
        rig = next(obj for obj in scene.objects if obj.type == "ARMATURE")
        for label, action_name, frame in (
            ("happy", "Pipilabu_Happy", 9),
            ("receive", "Pipilabu_Receive", 20),
            ("hold", "Pipilabu_Hold", 20),
            ("run", "Pipilabu_Run", 1),
        ):
            rig.animation_data.action = None
            reset_pose(rig)
            rig.animation_data.action = bpy.data.actions[action_name]
            scene.frame_set(frame)
            camera.location = beauty_location
            camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
            scene.render.filepath = str(OUTPUT_DIR / f"{STEM}.{label}.png")
            bpy.ops.render.render(write_still=True)
        rig.animation_data.action = None
        scene.frame_set(1)
        reset_pose(rig)
    elif MODEL_VERSION in {"v5", "v6", "v7", "v8", "v11"} and VARIANT == "owner":
        rig = next(obj for obj in scene.objects if obj.type == "ARMATURE")
        for label, action_name, frame in (
            ("talk", "Pipilabu_Talk", 12),
            ("serve", "Pipilabu_Serve", 11),
            ("happy", "Pipilabu_Happy", 10),
            ("stressed", "Pipilabu_Stressed", 8),
        ):
            rig.animation_data.action = None
            reset_pose(rig)
            rig.animation_data.action = bpy.data.actions[action_name]
            scene.frame_set(frame)
            camera.location = beauty_location
            camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
            scene.render.filepath = str(OUTPUT_DIR / f"{STEM}.{label}.png")
            bpy.ops.render.render(write_still=True)
        rig.animation_data.action = None
        scene.frame_set(1)
        reset_pose(rig)
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
    scene["pipilabu_model_version"] = MODEL_VERSION
    scene["asset_rights"] = "Original procedural geometry; no external meshes"
    scene["variant_usage"] = (
        "v11 owner=reel-driven room-orb owner reconstruction candidate"
        if MODEL_VERSION == "v11"
        else "v8 customer=regular-topology belly-low Shiba queue NPC"
        if MODEL_VERSION == "v8" and VARIANT == "customer"
        else "v8 owner=regular-topology giant Shiba seller behind counter"
        if MODEL_VERSION == "v8"
        else "v7 customer=approved-turnaround belly-low Shiba queue NPC"
        if MODEL_VERSION == "v7" and VARIANT == "customer"
        else "v7 owner=approved-turnaround giant Shiba seller behind counter"
        if MODEL_VERSION == "v7"
        else "v6 customer=video-turnaround belly-low Shiba queue NPC"
        if MODEL_VERSION == "v6" and VARIANT == "customer"
        else "v6 owner=video-turnaround giant Shiba seller behind counter"
        if MODEL_VERSION == "v6"
        else "v5 customer=tiny low quadruped market-video Shiba queue NPC"
        if MODEL_VERSION == "v5" and VARIANT == "customer"
        else "v5 owner=huge market-video Shiba seller behind counter"
        if MODEL_VERSION == "v5"
        else "v4 customer=small Peepilabu queue NPC; normal Roblox player"
        if MODEL_VERSION == "v4" and VARIANT == "customer"
        else "v4 owner=Peepilabu hero counter NPC; normal Roblox player"
    )

    blend_path = OUTPUT_DIR / f"{STEM}.blend"
    fbx_path = OUTPUT_DIR / f"{STEM}.fbx"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))

    bpy.ops.object.select_all(action="DESELECT")
    export_objects = [
        obj for obj in bpy.context.scene.objects
        if not obj.name.startswith("PREVIEW_") and obj.type in {"ARMATURE", "MESH", "EMPTY"}
    ]
    for obj in export_objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = rig
    common_export = dict(
        use_selection=True,
        object_types={"ARMATURE", "MESH", "EMPTY"},
        apply_scale_options="FBX_SCALE_UNITS",
        use_space_transform=True,
        axis_forward="-Z",
        axis_up="Y",
        add_leaf_bones=False,
        use_armature_deform_only=True,
    )
    animation_files = []
    if MODEL_VERSION in {"v5", "v6", "v7", "v8", "v11"}:
        bpy.ops.export_scene.fbx(
            filepath=str(fbx_path),
            **common_export,
            use_tspace=True,
            bake_anim=False,
            path_mode="COPY",
            embed_textures=True,
        )
        rig.animation_data_create()
        for action in sorted(bpy.data.actions, key=lambda item: item.name):
            rig.animation_data.action = action
            action_path = OUTPUT_DIR / f"{STEM}.{action.name.removeprefix('Pipilabu_').lower()}.fbx"
            bpy.ops.export_scene.fbx(
                filepath=str(action_path),
                **common_export,
                use_tspace=True,
                bake_anim=True,
                bake_anim_use_all_bones=True,
                bake_anim_use_nla_strips=False,
                bake_anim_use_all_actions=False,
                bake_anim_force_startend_keying=True,
                bake_anim_simplify_factor=0.0,
                path_mode="COPY",
                embed_textures=True,
            )
            animation_files.append(action_path.name)
        rig.animation_data.action = None
    else:
        bpy.ops.export_scene.fbx(
            filepath=str(fbx_path),
            **common_export,
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
    metrics["animation_fbx_files"] = animation_files
    preview_path = OUTPUT_DIR / f"{STEM}.preview.png"
    if preview_path.is_file():
        metrics["preview_file"] = preview_path.name
        metrics["preview_bytes"] = preview_path.stat().st_size
    metrics["validation_renders"] = [
        path.name for path in sorted(OUTPUT_DIR.glob(f"{STEM}.*.png"))
        if path.name not in set(metrics.get("surface_maps", {}).values())
    ]
    if MODEL_VERSION in {"v6", "v7", "v8", "v11"} and metrics["meshes_over_20000_triangles"]:
        offenders = ", ".join(metrics["meshes_over_20000_triangles"])
        raise ValueError(f"Roblox mesh triangle budget exceeded: {offenders}")
    metrics_path = OUTPUT_DIR / f"{STEM}.metrics.json"
    metrics_path.write_text(json.dumps(metrics, indent=2) + "\n", encoding="utf-8")
    return metrics


def main() -> None:
    reset_scene()
    if MODEL_VERSION == "v11":
        if VARIANT != "owner":
            raise ValueError("v11 supports the reel-driven room-orb owner only")
        rig = build_owner_armature_v4()
        rig["art_direction"] = "Leo-selected room-frame giant orb; reel-driven low eyes and crescent grin; no ear or tail geometry"
        build_owner_meshes_v11(rig)
        build_markers_v4(rig)
        build_actions_v4(rig)
    elif MODEL_VERSION == "v8":
        if VARIANT not in {"owner", "customer"}:
            raise ValueError("v8 supports the Studio-equivalent owner/customer family only")
        rig = build_owner_armature_v4()
        rig["art_direction"] = "Original-video Shiba family; fully rounded crown; regular topology; no top-ear geometry"
        build_video_turnaround_meshes_v8(rig)
        build_markers_v4(rig)
        if VARIANT == "customer":
            build_customer_actions_v4(rig)
        else:
            build_actions_v4(rig)
    elif MODEL_VERSION in {"v6", "v7"}:
        if VARIANT not in {"owner", "customer"}:
            raise ValueError(f"{MODEL_VERSION} supports the video-turnaround owner/customer family only")
        rig = build_owner_armature_v4()
        rig["art_direction"] = "Approved video-turnaround owner/customer family; natural Shiba face; swallowed ears; distinct body plans"
        build_video_turnaround_meshes_v6(rig)
        build_markers_v4(rig)
        if VARIANT == "customer":
            build_customer_actions_v4(rig)
        else:
            build_actions_v4(rig)
    elif MODEL_VERSION == "v5":
        if VARIANT not in {"owner", "customer"}:
            raise ValueError("v5 supports the market-video owner/customer family only")
        rig = build_owner_armature_v4()
        rig["art_direction"] = "Leo 2026-08-09 market-video Shiba family; swallowed ears; no half measures"
        build_market_video_meshes_v5(rig)
        build_markers_v4(rig)
        if VARIANT == "customer":
            build_customer_actions_v4(rig)
        else:
            build_actions_v4(rig)
    elif MODEL_VERSION == "v4":
        if VARIANT not in {"owner", "customer"}:
            raise ValueError("v4 supports Peepilabu owner/customer NPCs; the player remains a normal Roblox avatar")
        rig = build_owner_armature_v4()
        build_owner_meshes_v4(rig)
        build_markers_v4(rig)
        build_actions_v4(rig)
    elif MODEL_VERSION == "v3":
        if VARIANT not in {"player", "owner"}:
            raise ValueError("v3 currently defines the anthropomorphic player/owner body plan; customer v3 follows its separate orthographic gate")
        rig = build_biped_armature_v3()
        build_player_meshes_v3(rig)
        build_markers_v3(rig)
        build_actions_v3(rig)
    elif MODEL_VERSION == "v2":
        rig = build_armature_v2()
        build_meshes_v2(rig)
        build_markers_v2(rig)
        build_actions_v2(rig)
    else:
        rig = build_armature()
        build_meshes(rig)
        build_markers(rig)
        build_actions(rig)
    render_preview()
    metrics = save_and_export(rig)
    print("PIPILABU_EXPORT_OK " + json.dumps(metrics, sort_keys=True))


try:
    main()
except Exception:
    (OUTPUT_DIR / f"{STEM}.error.log").write_text(traceback.format_exc(), encoding="utf-8")
    raise
