"""Import one reconstruction mesh into Blender and render an honest gate set.

Run with Blender, not system Python:
  blender --background --python inspect-triposr-in-blender.py -- \
    --mesh path/to/mesh.obj --texture path/to/texture.png --output path/to/review

The output includes registered orthographic beauty, neutral-clay, and pure
silhouette views plus contact sheets. This is an inspection step only. It does
not retopologize, rig, approve, or upload the mesh to Roblox.
"""

from __future__ import annotations

import argparse
import json
import math
import shutil
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--mesh", type=Path, required=True)
    parser.add_argument("--texture", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args(argv)


def look_at(camera: bpy.types.Object, target: Vector) -> None:
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()


def make_principled_material(name: str, color: tuple[float, float, float, float]) -> bpy.types.Material:
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    shader = material.node_tree.nodes.get("Principled BSDF")
    if shader is None:
        raise RuntimeError(f"{name} is missing Principled BSDF")
    shader.inputs["Base Color"].default_value = color
    shader.inputs["Roughness"].default_value = 0.92
    shader.inputs["Metallic"].default_value = 0.0
    return material


def make_silhouette_material() -> bpy.types.Material:
    material = bpy.data.materials.new("InspectionSilhouette")
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    nodes.clear()
    output = nodes.new("ShaderNodeOutputMaterial")
    emission = nodes.new("ShaderNodeEmission")
    emission.inputs["Color"].default_value = (0.0, 0.0, 0.0, 1.0)
    emission.inputs["Strength"].default_value = 1.0
    links.new(emission.outputs["Emission"], output.inputs["Surface"])
    return material


def make_contact_sheet(image_paths: list[Path], output_path: Path) -> None:
    loaded = [bpy.data.images.load(str(path), check_existing=False) for path in image_paths]
    try:
        if not loaded:
            raise RuntimeError("No images supplied for contact sheet")
        width = loaded[0].size[0]
        height = loaded[0].size[1]
        if any(image.size[0] != width or image.size[1] != height for image in loaded):
            raise RuntimeError("Inspection images are not registered to one resolution")

        sheet = bpy.data.images.new(
            output_path.stem,
            width=width * len(loaded),
            height=height,
            alpha=True,
        )
        pixels = [1.0] * (width * len(loaded) * height * 4)
        for index, image in enumerate(loaded):
            source = list(image.pixels[:])
            for row in range(height):
                source_start = row * width * 4
                destination_start = (row * width * len(loaded) + index * width) * 4
                pixels[destination_start : destination_start + width * 4] = source[
                    source_start : source_start + width * 4
                ]
        sheet.pixels = pixels
        sheet.filepath_raw = str(output_path)
        sheet.file_format = "PNG"
        sheet.save()
        bpy.data.images.remove(sheet)
    finally:
        for image in loaded:
            if image.name in bpy.data.images:
                bpy.data.images.remove(image)


def main() -> None:
    args = parse_args()
    mesh_path = args.mesh.resolve()
    texture_path = args.texture.resolve() if args.texture else None
    output_dir = args.output.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    beauty_dir = output_dir / "beauty"
    clay_dir = output_dir / "neutral-clay"
    silhouette_dir = output_dir / "silhouette"
    for directory in (beauty_dir, clay_dir, silhouette_dir):
        directory.mkdir(parents=True, exist_ok=True)

    if not mesh_path.is_file():
        raise FileNotFoundError(mesh_path)
    if texture_path and not texture_path.is_file():
        raise FileNotFoundError(texture_path)

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    if mesh_path.suffix.lower() == ".glb":
        bpy.ops.import_scene.gltf(filepath=str(mesh_path))
    elif mesh_path.suffix.lower() == ".obj":
        bpy.ops.wm.obj_import(filepath=str(mesh_path))
    else:
        raise ValueError(f"Unsupported diagnostic mesh format: {mesh_path.suffix}")
    mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not mesh_objects:
        raise RuntimeError(f"No mesh objects imported from {mesh_path}")

    for obj in mesh_objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = mesh_objects[0]
    if len(mesh_objects) > 1:
        bpy.ops.object.join()
    subject = bpy.context.view_layer.objects.active
    subject.name = "PipiLabu_TripoSR_Diagnostic"

    world_corners = [subject.matrix_world @ Vector(corner) for corner in subject.bound_box]
    minimum = Vector(tuple(min(v[i] for v in world_corners) for i in range(3)))
    maximum = Vector(tuple(max(v[i] for v in world_corners) for i in range(3)))
    dimensions = maximum - minimum
    if dimensions.z <= 0:
        raise RuntimeError("Imported mesh has invalid height")
    uniform_scale = 2.0 / dimensions.z
    subject.scale *= uniform_scale
    bpy.context.view_layer.update()

    world_corners = [subject.matrix_world @ Vector(corner) for corner in subject.bound_box]
    minimum = Vector(tuple(min(v[i] for v in world_corners) for i in range(3)))
    maximum = Vector(tuple(max(v[i] for v in world_corners) for i in range(3)))
    center = (minimum + maximum) * 0.5
    subject.location -= Vector((center.x, center.y, minimum.z))
    bpy.context.view_layer.update()

    fitted_corners = [subject.matrix_world @ Vector(corner) for corner in subject.bound_box]
    fitted_minimum = Vector(tuple(min(v[i] for v in fitted_corners) for i in range(3)))
    fitted_maximum = Vector(tuple(max(v[i] for v in fitted_corners) for i in range(3)))
    fitted_dimensions = fitted_maximum - fitted_minimum

    if texture_path:
        material = bpy.data.materials.new("DiagnosticTexture")
        material.use_nodes = True
        nodes = material.node_tree.nodes
        links = material.node_tree.links
        shader = nodes.get("Principled BSDF")
        texture = nodes.new("ShaderNodeTexImage")
        texture.image = bpy.data.images.load(str(texture_path), check_existing=True)
        links.new(texture.outputs["Color"], shader.inputs["Base Color"])
        shader.inputs["Roughness"].default_value = 0.72
        subject.data.materials.clear()
        subject.data.materials.append(material)

    floor_material = bpy.data.materials.new("ReviewFloor")
    floor_material.diffuse_color = (0.21, 0.16, 0.12, 1.0)
    bpy.ops.mesh.primitive_plane_add(size=20, location=(0, 0, -0.01))
    floor = bpy.context.object
    floor.data.materials.append(floor_material)

    world = bpy.context.scene.world or bpy.data.worlds.new("ReviewWorld")
    bpy.context.scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.055, 0.04, 0.03, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.45

    for name, location, energy, size in (
        ("Key", (4.0, -5.0, 5.0), 900.0, 4.0),
        ("Fill", (-4.0, -2.0, 3.0), 500.0, 3.0),
        ("Rim", (2.0, 4.0, 4.0), 700.0, 2.5),
    ):
        light_data = bpy.data.lights.new(name, type="AREA")
        light_data.energy = energy
        light_data.shape = "DISK"
        light_data.size = size
        light = bpy.data.objects.new(name, light_data)
        bpy.context.collection.objects.link(light)
        light.location = location
        light.rotation_euler = (Vector((0, 0, 0.9)) - light.location).to_track_quat("-Z", "Y").to_euler()

    camera_data = bpy.data.cameras.new("InspectionCamera")
    camera = bpy.data.objects.new("InspectionCamera", camera_data)
    bpy.context.collection.objects.link(camera)
    bpy.context.scene.camera = camera
    camera.data.type = "ORTHO"

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 640
    scene.render.resolution_y = 640
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.view_settings.look = "AgX - Medium High Contrast"

    target = Vector((0, 0, 0.9))
    radius = max(4.4, fitted_dimensions.x * 1.7, fitted_dimensions.y * 1.7)
    camera.data.ortho_scale = max(fitted_dimensions.x, fitted_dimensions.y, fitted_dimensions.z) * 1.18
    views = {
        "front": -90,
        "three-quarter": -45,
        "left": 0,
        "back": 90,
        "right": 180,
    }

    clay_material = make_principled_material("InspectionNeutralClay", (0.48, 0.50, 0.52, 1.0))
    silhouette_material = make_silhouette_material()
    background = world.node_tree.nodes["Background"]
    original_materials = [slot.material for slot in subject.material_slots]
    original_material_indices = [polygon.material_index for polygon in subject.data.polygons]

    camera_poses: dict[str, tuple[Vector, tuple[float, float, float]]] = {}
    for label, degrees in views.items():
        radians = math.radians(degrees)
        camera.location = Vector((radius * math.cos(radians), radius * math.sin(radians), 1.55))
        look_at(camera, target)
        camera_poses[label] = (camera.location.copy(), tuple(camera.rotation_euler))

    def render_registered_set(
        destination: Path,
        material_override: bpy.types.Material | None,
        background_color: tuple[float, float, float, float],
        hide_floor: bool,
    ) -> list[Path]:
        if material_override is not None:
            subject.data.materials.clear()
            subject.data.materials.append(material_override)
            for polygon in subject.data.polygons:
                polygon.material_index = 0
        background.inputs["Color"].default_value = background_color
        floor.hide_render = hide_floor
        paths: list[Path] = []
        for label in views:
            location, rotation = camera_poses[label]
            camera.location = location
            camera.rotation_euler = rotation
            path = destination / f"{label}.png"
            scene.render.filepath = str(path)
            bpy.ops.render.render(write_still=True)
            paths.append(path)
        if material_override is not None:
            subject.data.materials.clear()
            for material in original_materials:
                subject.data.materials.append(material)
            for polygon, material_index in zip(subject.data.polygons, original_material_indices, strict=True):
                polygon.material_index = material_index
        return paths

    beauty_paths = render_registered_set(
        beauty_dir,
        material_override=None,
        background_color=(0.055, 0.04, 0.03, 1.0),
        hide_floor=False,
    )
    for legacy_label in ("front", "left", "back", "right"):
        shutil.copy2(beauty_dir / f"{legacy_label}.png", output_dir / f"{legacy_label}.png")

    clay_paths = render_registered_set(
        clay_dir,
        material_override=clay_material,
        background_color=(0.055, 0.055, 0.055, 1.0),
        hide_floor=False,
    )
    silhouette_paths = render_registered_set(
        silhouette_dir,
        material_override=silhouette_material,
        background_color=(1.0, 1.0, 1.0, 1.0),
        hide_floor=True,
    )
    floor.hide_render = False

    make_contact_sheet(beauty_paths, output_dir / "contact-sheet-beauty.png")
    make_contact_sheet(clay_paths, output_dir / "contact-sheet-neutral-clay.png")
    make_contact_sheet(silhouette_paths, output_dir / "contact-sheet-silhouette.png")

    polygons = len(subject.data.polygons)
    vertices = len(subject.data.vertices)
    edges = len(subject.data.edges)
    stats = {
        "source_mesh": str(mesh_path),
        "source_texture": str(texture_path) if texture_path else None,
        "vertices": vertices,
        "edges": edges,
        "triangles": sum(len(poly.vertices) - 2 for poly in subject.data.polygons),
        "polygons": polygons,
        "inspection_views": list(views),
        "orthographic_scale": camera.data.ortho_scale,
        "registered_contact_sheets": [
            "contact-sheet-beauty.png",
            "contact-sheet-neutral-clay.png",
            "contact-sheet-silhouette.png",
        ],
        "manifold_ready_for_roblox": False,
        "rigged": False,
        "approved": False,
        "note": "Diagnostic reconstruction only; visual and topology review required.",
    }
    (output_dir / "mesh-stats.json").write_text(json.dumps(stats, indent=2), encoding="utf-8")
    bpy.ops.wm.save_as_mainfile(filepath=str(output_dir / "diagnostic.blend"))
    print("PIPILABU_BLENDER_INSPECTION_OK", json.dumps(stats))


if __name__ == "__main__":
    main()
