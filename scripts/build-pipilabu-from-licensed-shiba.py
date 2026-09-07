"""Build an unapproved Pipi Labu deformation from a licensed Shiba base mesh.

The source model is Pat Siefring's "Shiba Inu", distributed by Poly Pizza
under CC BY. This script preserves attribution inside the .blend and exports a
local GLB for visual review. It does not upload or promote the result.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


ATTRIBUTION = (
    'Base mesh: "Shiba Inu" by Pat Siefring, via Poly Pizza, CC BY. '
    "Source: https://poly.pizza/m/1sr1MDt9db5"
)


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--role", choices=("owner", "customer"), default="owner")
    return parser.parse_args(argv)


def deform_point(point: Vector, role: str) -> Vector:
    """Turn the tall base dog into a low, heavy Pipi Labu study."""
    source_x, source_y, source_z = point

    if role == "customer":
        y = source_y * 0.54
        if source_y < -3.15:
            y -= 0.12
        if source_z < -0.70:
            z = -0.70 + (source_z + 0.70) * 0.07
        else:
            z = -0.70 + (source_z + 0.70) * 0.48
        x = source_x * (1.52 if source_y > -1.90 else 1.58)
        if source_y > -1.90 and -1.10 < source_z < 0.80:
            z -= 0.48 * max(0.0, 1.0 - abs(source_x) / 1.35)
        if source_y < -2.30 and source_z > 2.45 and abs(source_x) > 0.28:
            z = 0.82 + (source_z - 2.45) * 0.04
            x = math.copysign(max(abs(x), 0.94), x)
            y += 0.08
        return Vector((x, y, z))

    # The base faces -Y. Compress the long torso and bring the skull into the
    # body so the silhouette reads as one heavy animal rather than a normal dog.
    y = source_y * 0.42
    if source_y < -3.15:
        y -= 0.16  # retain a short but readable Shiba muzzle

    # Remove most leg height while retaining planted feet. Upper-body height is
    # reduced more gently so the cheeks and chest stay substantial.
    if source_z < -0.70:
        z = -0.70 + (source_z + 0.70) * 0.20
    else:
        z = -0.70 + (source_z + 0.70) * 0.80

    # Broad torso and shoulder mass; the head is even wider so the cheeks melt
    # into the body instead of sitting on a visible neck.
    if source_y > -1.90:
        x = source_x * 1.78
        if source_z > -0.80:
            z += 0.26 * max(0.0, 1.0 - abs(source_y) / 4.4)
        if -1.10 < source_z < 0.80:
            z -= 0.62 * max(0.0, 1.0 - abs(source_x) / 1.35)
    else:
        x = source_x * 1.62
        if source_z > 0.25:
            z -= 0.12

    # Explicitly collapse the original upright ear towers. Their inner-ear
    # objects are removed separately; these are the crown vertices fused into
    # the main body mesh.
    if source_y < -2.30 and source_z > 2.45 and abs(source_x) > 0.28:
        z = 1.92 + (source_z - 2.45) * 0.06
        x = math.copysign(max(abs(x), 0.98), x)
        y += 0.10

    return Vector((x, y, z))


def deform_mesh_object(obj: bpy.types.Object, role: str) -> None:
    inverse = obj.matrix_world.inverted()
    for vertex in obj.data.vertices:
        world = obj.matrix_world @ vertex.co
        vertex.co = inverse @ deform_point(world, role)


def apply_subdivision(obj: bpy.types.Object, levels: int) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    # The source GLB preserves flat-shaded facets by duplicating coincident
    # vertices. Subdivision before welding makes every polygon shrink into a
    # separate scale instead of producing a continuous animal surface.
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.remove_doubles(threshold=0.0001)
    bpy.ops.object.mode_set(mode="OBJECT")
    modifier = obj.modifiers.new("PipiLabuSmooth", type="SUBSURF")
    modifier.subdivision_type = "CATMULL_CLARK"
    modifier.levels = levels
    modifier.render_levels = levels
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True


def main() -> None:
    args = parse_args()
    source = args.source.resolve()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    if not source.is_file():
        raise FileNotFoundError(source)

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(source))

    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    body = next((obj for obj in meshes if obj.name == "Shiba"), None)
    if body is None:
        raise RuntimeError("Expected the licensed source to contain mesh 'Shiba'")

    for obj in list(meshes):
        lowered = obj.name.lower()
        if "ear" in lowered or "tail" in lowered:
            bpy.data.objects.remove(obj, do_unlink=True)
            continue
        deform_mesh_object(obj, args.role)

    apply_subdivision(body, levels=2)
    for obj in [obj for obj in bpy.context.scene.objects if obj.type == "MESH" and obj is not body]:
        apply_subdivision(obj, levels=1)

    role_title = args.role.title()
    body.name = f"PipiLabu{role_title}_LicensedBase_V2_UNAPPROVED"
    body["approved"] = False
    body["gameplay_replacement"] = False
    body["status"] = "UNAPPROVED_DEFORMATION_STUDY"
    body["source_attribution"] = ATTRIBUTION
    body["visual_target"] = f"Original Pipi Labu market-video {args.role}; rounded crown and visually swallowed ears"

    attribution = bpy.data.texts.new("ATTRIBUTION_CC_BY")
    attribution.write(ATTRIBUTION + "\n")
    attribution.write("This deformation study is not approved for gameplay or presentation.\n")

    # Normalize the complete visible set to a stable origin and two-meter review
    # height without destroying the relative eye/body placement.
    visible = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    corners = [obj.matrix_world @ Vector(corner) for obj in visible for corner in obj.bound_box]
    minimum = Vector(tuple(min(v[i] for v in corners) for i in range(3)))
    maximum = Vector(tuple(max(v[i] for v in corners) for i in range(3)))
    scale = 2.0 / (maximum.z - minimum.z)
    center = (minimum + maximum) * 0.5
    for obj in visible:
        obj.location -= Vector((center.x, center.y, minimum.z))
        obj.scale *= scale
    bpy.context.view_layer.update()

    blend_path = output / f"pipi-labu-{args.role}-licensed-base-v2.blend"
    glb_path = output / f"pipi-labu-{args.role}-licensed-base-v2.glb"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))

    bpy.ops.object.select_all(action="DESELECT")
    for obj in visible:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.export_scene.gltf(
        filepath=str(glb_path),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_materials="EXPORT",
    )

    stats = {
        "source": str(source),
        "role": args.role,
        "attribution": ATTRIBUTION,
        "objects": len(visible),
        "vertices": sum(len(obj.data.vertices) for obj in visible),
        "triangles": sum(sum(len(poly.vertices) - 2 for poly in obj.data.polygons) for obj in visible),
        "approved": False,
        "gameplay_replacement": False,
        "blend": str(blend_path),
        "glb": str(glb_path),
    }
    (output / "build-stats.json").write_text(json.dumps(stats, indent=2), encoding="utf-8")
    print("PIPILABU_LICENSED_BASE_BUILD_OK", json.dumps(stats))


if __name__ == "__main__":
    main()
