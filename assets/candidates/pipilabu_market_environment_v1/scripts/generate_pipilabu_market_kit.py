"""Generate the isolated Pipi Labu market kit.

The normal-Python path emits dependency-free OBJ modules, simplified collision
proxies, an assembled review vignette, and a deterministic layout manifest.
When the same file is run by Blender 4.x, it also builds a native scene with
separate visual/collision collections and saves a .blend review source.

No live Roblox, Rojo, Studio, or existing asset path is touched by this script.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

try:  # Optional: this branch exists only when Blender runs the script.
    import bpy  # type: ignore
except ImportError:  # pragma: no cover - ordinary Python is the default path.
    bpy = None  # type: ignore


SCRIPT_VERSION = "1.0.0"

MATERIALS: dict[str, dict[str, Any]] = {
    "WoodWarm": {"rgb": (0.49, 0.29, 0.17), "roughness": 0.88},
    "WoodDark": {"rgb": (0.25, 0.14, 0.08), "roughness": 0.92},
    "PlasterCream": {"rgb": (0.90, 0.82, 0.68), "roughness": 0.93},
    "CanvasVermilion": {"rgb": (0.78, 0.20, 0.14), "roughness": 0.95},
    "CanvasPaper": {"rgb": (0.95, 0.88, 0.72), "roughness": 0.96},
    "Ink": {"rgb": (0.15, 0.09, 0.06), "roughness": 0.82},
    "MetalDark": {"rgb": (0.18, 0.18, 0.16), "roughness": 0.62},
    "LanternAmber": {"rgb": (1.0, 0.58, 0.15), "roughness": 0.42},
    "Leaf": {"rgb": (0.22, 0.40, 0.20), "roughness": 0.90},
    "FruitRuby": {"rgb": (0.72, 0.12, 0.08), "roughness": 0.46},
    "FruitHoneygold": {"rgb": (0.95, 0.60, 0.12), "roughness": 0.44},
    "StoneWarm": {"rgb": (0.54, 0.48, 0.39), "roughness": 0.97},
    "CollisionProxy": {"rgb": (0.25, 0.25, 0.25), "roughness": 1.0},
}


@dataclass(frozen=True)
class Part:
    name: str
    kind: str
    center: tuple[float, float, float]
    size: tuple[float, float, float]
    material: str
    radius: float | None = None
    segments: int = 12


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else sys.argv[1:]
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", required=True)
    return parser.parse_args(argv)


def box(name: str, center: tuple[float, float, float], size: tuple[float, float, float], material: str) -> Part:
    return Part(name=name, kind="box", center=center, size=size, material=material)


def cylinder(
    name: str,
    center: tuple[float, float, float],
    radius: float,
    depth: float,
    material: str,
    segments: int = 12,
) -> Part:
    return Part(
        name=name,
        kind="cylinder",
        center=center,
        size=(radius * 2.0, depth, radius * 2.0),
        material=material,
        radius=radius,
        segments=segments,
    )


def visual_parts(module_id: str) -> list[Part]:
    if module_id == "STALL_BAY_12X8":
        return [
            box("FloorDeck", (0.0, 0.08, 0.0), (12.0, 0.16, 8.0), "WoodWarm"),
            box("BackWall", (0.0, 2.65, -3.75), (11.4, 5.3, 0.25), "PlasterCream"),
            box("FrontPost_L", (-5.825, 3.0, 3.45), (0.35, 6.0, 0.35), "WoodDark"),
            box("FrontPost_R", (5.825, 3.0, 3.45), (0.35, 6.0, 0.35), "WoodDark"),
            box("BackPost_L", (-5.825, 3.0, -3.45), (0.35, 6.0, 0.35), "WoodDark"),
            box("BackPost_R", (5.825, 3.0, -3.45), (0.35, 6.0, 0.35), "WoodDark"),
            box("CounterBase", (0.0, 0.70, 2.55), (10.7, 1.4, 1.0), "WoodDark"),
            box("CounterTop", (0.0, 1.50, 2.65), (11.0, 0.2, 1.3), "WoodWarm"),
            box("RoofSlab", (0.0, 6.05, -0.20), (12.0, 0.4, 7.6), "PlasterCream"),
            box("FrontHeader", (0.0, 5.60, 3.80), (12.0, 0.35, 0.4), "WoodWarm"),
            box("LeftTrim", (-5.92, 4.2, 0.2), (0.16, 2.4, 6.8), "WoodWarm"),
            box("RightTrim", (5.92, 4.2, 0.2), (0.16, 2.4, 6.8), "WoodWarm"),
        ]
    if module_id == "AWNING_12X3_BAY":
        parts = [
            box("AwningDeck", (0.0, 0.15, 1.6), (12.4, 0.3, 3.2), "CanvasVermilion"),
            box("AwningFrontEdge", (0.0, 0.04, 3.13), (12.4, 0.08, 0.14), "CanvasPaper"),
        ]
        for index, x in enumerate((-5.6, -3.7, -1.8, 0.0, 1.8, 3.7, 5.6)):
            parts.append(
                box(
                    f"Stripe_{index + 1:02d}",
                    (x, 0.315, 1.6),
                    (0.8, 0.01, 3.08),
                    "CanvasPaper" if index % 2 else "CanvasVermilion",
                )
            )
        return parts
    if module_id == "SHELF_WALL_6X2":
        return [
            box("ShelfBack", (0.0, 1.2, 0.30), (5.8, 2.4, 0.30), "WoodDark"),
            box("ShelfLower", (0.0, 0.68, -0.02), (6.0, 0.18, 0.86), "WoodWarm"),
            box("ShelfUpper", (0.0, 1.60, -0.02), (6.0, 0.18, 0.86), "WoodWarm"),
            box("ShelfRail", (0.0, 2.28, -0.02), (6.0, 0.24, 0.86), "WoodDark"),
            box("ShelfSide_L", (-2.88, 1.2, -0.02), (0.24, 2.4, 0.84), "WoodDark"),
            box("ShelfSide_R", (2.88, 1.2, -0.02), (0.24, 2.4, 0.84), "WoodDark"),
        ]
    if module_id == "CRATE_STACK_2X2":
        return [
            box("LowerCrateBody", (0.0, 0.30, 0.0), (2.4, 0.60, 2.0), "WoodWarm"),
            box("LowerRimFront", (0.0, 0.64, -0.94), (2.4, 0.12, 0.12), "WoodDark"),
            box("LowerRimBack", (0.0, 0.64, 0.94), (2.4, 0.12, 0.12), "WoodDark"),
            box("UpperCrateBody", (0.0, 1.00, 0.0), (2.2, 0.40, 1.8), "WoodWarm"),
            box("UpperRimFront", (0.0, 1.35, -0.94), (2.4, 0.12, 0.12), "WoodDark"),
            box("UpperRimBack", (0.0, 1.35, 0.94), (2.4, 0.12, 0.12), "WoodDark"),
            box("TopRim", (0.0, 1.44, 0.0), (2.4, 0.12, 2.0), "WoodDark"),
        ]
    if module_id == "FRUIT_TRAY_3":
        parts = [
            box("TrayBase", (0.0, 0.22, 0.0), (3.2, 0.44, 1.2), "WoodWarm"),
            box("TrayFrontRail", (0.0, 0.70, -0.53), (3.2, 0.14, 0.14), "WoodDark"),
            box("TrayBackRail", (0.0, 0.70, 0.53), (3.2, 0.14, 0.14), "WoodDark"),
            box("TraySide_L", (-1.53, 0.70, 0.0), (0.14, 0.48, 1.0), "WoodDark"),
            box("TraySide_R", (1.53, 0.70, 0.0), (0.14, 0.48, 1.0), "WoodDark"),
        ]
        for index, x in enumerate((-1.15, -0.38, 0.38, 1.15)):
            parts.append(cylinder(f"Fruit_{index + 1:02d}", (x, 0.82, 0.0), 0.23, 0.46, "FruitRuby" if index % 2 else "FruitHoneygold", 12))
        return parts
    if module_id == "LANTERN_POST_4":
        return [
            box("Post", (0.0, 2.0, 0.0), (0.24, 4.0, 0.24), "WoodDark"),
            cylinder("LampBody", (0.0, 4.15, 0.0), 0.35, 0.75, "LanternAmber", 12),
            cylinder("LampCap", (0.0, 4.625, 0.0), 0.45, 0.15, "WoodDark", 12),
        ]
    if module_id == "STREET_EDGE_CURB_4":
        return [
            box("CurbBody", (0.0, 0.225, 0.0), (4.0, 0.45, 0.65), "StoneWarm"),
            box("CurbTop", (0.0, 0.44, 0.0), (3.84, 0.02, 0.56), "PlasterCream"),
        ]
    if module_id == "STREET_EDGE_DRAIN_4":
        return [
            box("DrainBody", (0.0, 0.08, 0.0), (4.0, 0.16, 0.30), "MetalDark"),
            box("DrainInset", (0.0, 0.145, 0.0), (3.70, 0.03, 0.12), "Ink"),
        ]
    if module_id == "FACADE_PANEL_6":
        return [
            box("Panel", (0.0, 2.70, 0.0), (6.0, 5.4, 0.30), "PlasterCream"),
            box("LowerPlinth", (0.0, 0.18, 0.0), (6.0, 0.36, 0.30), "WoodDark"),
            box("TopBeam", (0.0, 5.15, 0.0), (6.0, 0.50, 0.30), "WoodWarm"),
        ]
    if module_id == "SIGNBOARD_3":
        return [
            box("SignFace", (0.0, 0.50, 0.0), (3.2, 1.0, 0.18), "CanvasPaper"),
            box("SignTopRail", (0.0, 0.91, -0.0), (3.2, 0.08, 0.18), "WoodDark"),
            box("SignBottomRail", (0.0, 0.09, -0.0), (3.2, 0.08, 0.18), "WoodDark"),
        ]
    if module_id == "PLANTER_2":
        return [
            box("PlanterBody", (0.0, 0.38, 0.0), (2.0, 0.76, 0.90), "StoneWarm"),
            box("PlanterRim", (0.0, 0.80, 0.0), (2.0, 0.14, 0.90), "WoodDark"),
            cylinder("PlantCluster", (0.0, 0.90, 0.0), 0.38, 0.10, "Leaf", 12),
        ]
    if module_id == "BOLLARD_05":
        return [
            cylinder("BollardBody", (0.0, 0.55, 0.0), 0.25, 1.10, "WoodDark", 12),
            cylinder("BollardCap", (0.0, 1.07, 0.0), 0.21, 0.06, "LanternAmber", 12),
        ]
    raise KeyError(f"Unknown module: {module_id}")


def collision_parts(module_id: str) -> list[Part]:
    proxy = "CollisionProxy"
    if module_id == "STALL_BAY_12X8":
        return [
            box("COLLISION_Floor", (0.0, 0.08, 0.0), (12.0, 0.16, 8.0), proxy),
            box("COLLISION_BackWall", (0.0, 2.65, -3.75), (11.4, 5.3, 0.25), proxy),
            box("COLLISION_Counter", (0.0, 0.70, 2.55), (10.7, 1.4, 1.0), proxy),
            box("COLLISION_Post_L", (-5.825, 3.0, 3.45), (0.35, 6.0, 0.35), proxy),
            box("COLLISION_Post_R", (5.825, 3.0, 3.45), (0.35, 6.0, 0.35), proxy),
            box("COLLISION_Roof", (0.0, 6.05, -0.20), (12.0, 0.4, 7.6), proxy),
        ]
    if module_id == "AWNING_12X3_BAY":
        return [box("COLLISION_Awning", (0.0, 0.15, 1.6), (12.4, 0.3, 3.2), proxy)]
    if module_id == "SHELF_WALL_6X2":
        return [box("COLLISION_Shelf", (0.0, 1.2, 0.0), (6.0, 2.4, 0.9), proxy)]
    if module_id == "CRATE_STACK_2X2":
        return [box("COLLISION_CrateStack", (0.0, 0.75, 0.0), (2.4, 1.5, 2.0), proxy)]
    if module_id == "LANTERN_POST_4":
        return [
            box("COLLISION_Post", (0.0, 2.0, 0.0), (0.24, 4.0, 0.24), proxy),
            cylinder("COLLISION_Lamp", (0.0, 4.15, 0.0), 0.35, 0.75, proxy, 12),
        ]
    if module_id == "STREET_EDGE_CURB_4":
        return [box("COLLISION_Curb", (0.0, 0.225, 0.0), (4.0, 0.45, 0.65), proxy)]
    if module_id == "STREET_EDGE_DRAIN_4":
        return [box("COLLISION_Drain", (0.0, 0.08, 0.0), (4.0, 0.16, 0.30), proxy)]
    if module_id == "FACADE_PANEL_6":
        return [box("COLLISION_Facade", (0.0, 2.70, 0.0), (6.0, 5.4, 0.30), proxy)]
    if module_id == "PLANTER_2":
        return [box("COLLISION_Planter", (0.0, 0.38, 0.0), (2.0, 0.76, 0.90), proxy)]
    if module_id == "BOLLARD_05":
        return [cylinder("COLLISION_Bollard", (0.0, 0.70, 0.0), 0.25, 0.80, proxy, 12)]
    return []


LAYOUT_INSTANCES: list[dict[str, Any]] = [
    {"name": "StallBay", "module": "STALL_BAY_12X8", "position": [0.0, 0.0, 0.0]},
    {"name": "Awning", "module": "AWNING_12X3_BAY", "position": [0.0, 5.75, 0.0]},
    {"name": "BackShelf", "module": "SHELF_WALL_6X2", "position": [0.0, 0.0, -3.00]},
    {"name": "NeighborFacade", "module": "FACADE_PANEL_6", "position": [-9.00, 0.0, 0.0]},
    {"name": "AppleCrates", "module": "CRATE_STACK_2X2", "position": [-3.50, 1.50, 2.25]},
    {"name": "FruitTray", "module": "FRUIT_TRAY_3", "position": [2.50, 1.50, 2.50]},
    {"name": "Sign", "module": "SIGNBOARD_3", "position": [0.0, 4.50, -4.00]},
    {"name": "Lantern", "module": "LANTERN_POST_4", "position": [7.25, 0.0, 8.75]},
    {"name": "Planter", "module": "PLANTER_2", "position": [-7.25, 0.0, 8.75]},
    {"name": "Drain", "module": "STREET_EDGE_DRAIN_4", "position": [0.0, 0.0, 11.75]},
    {"name": "Curb", "module": "STREET_EDGE_CURB_4", "position": [0.0, 0.0, 12.50]},
    {"name": "EdgeBollard", "module": "BOLLARD_05", "position": [7.25, 0.0, 10.75]},
]


def add_box_geometry(vertices: list[tuple[float, float, float]], faces: list[tuple[int, ...]], part: Part) -> None:
    cx, cy, cz = part.center
    sx, sy, sz = part.size
    hx, hy, hz = sx / 2.0, sy / 2.0, sz / 2.0
    start = len(vertices)
    vertices.extend(
        [
            (cx - hx, cy - hy, cz - hz),
            (cx + hx, cy - hy, cz - hz),
            (cx + hx, cy + hy, cz - hz),
            (cx - hx, cy + hy, cz - hz),
            (cx - hx, cy - hy, cz + hz),
            (cx + hx, cy - hy, cz + hz),
            (cx + hx, cy + hy, cz + hz),
            (cx - hx, cy + hy, cz + hz),
        ]
    )
    faces.extend(
        [
            (start + 1, start + 2, start + 3, start + 4),
            (start + 5, start + 8, start + 7, start + 6),
            (start + 1, start + 5, start + 6, start + 2),
            (start + 2, start + 6, start + 7, start + 3),
            (start + 3, start + 7, start + 8, start + 4),
            (start + 5, start + 1, start + 4, start + 8),
        ]
    )


def add_cylinder_geometry(vertices: list[tuple[float, float, float]], faces: list[tuple[int, ...]], part: Part) -> None:
    assert part.radius is not None
    cx, cy, cz = part.center
    half_depth = part.size[1] / 2.0
    start = len(vertices)
    for ring_y in (cy - half_depth, cy + half_depth):
        for index in range(part.segments):
            angle = (math.tau * index) / part.segments
            vertices.append((cx + math.cos(angle) * part.radius, ring_y, cz + math.sin(angle) * part.radius))
    bottom = start + 1
    top = start + 1 + part.segments
    faces.append(tuple(bottom + index for index in reversed(range(part.segments))))
    faces.append(tuple(top + index for index in range(part.segments)))
    for index in range(part.segments):
        next_index = (index + 1) % part.segments
        faces.append((bottom + index, bottom + next_index, top + next_index, top + index))


def write_obj(path: Path, objects: list[tuple[str, list[Part]]], material_override: str | None = None) -> dict[str, Any]:
    path.parent.mkdir(parents=True, exist_ok=True)
    object_records: list[dict[str, Any]] = []
    total_vertices = 0
    total_faces = 0
    total_triangles = 0
    all_materials: set[str] = set()
    mtl_name = f"{path.stem}.mtl"
    with path.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write(f"# Pipi Labu market kit candidate {SCRIPT_VERSION}\nmtllib {mtl_name}\n")
        vertex_cursor = 0
        for object_name, parts in objects:
            handle.write(f"o {object_name}\n")
            part_vertices: list[tuple[float, float, float]] = []
            part_faces: list[tuple[int, ...]] = []
            part_materials: list[str] = []
            for part in parts:
                local_start = len(part_vertices)
                if part.kind == "box":
                    add_box_geometry(part_vertices, part_faces, part)
                else:
                    add_cylinder_geometry(part_vertices, part_faces, part)
                part_materials.extend([material_override or part.material] * (len(part_faces) - len(part_materials)))
            for vertex in part_vertices:
                handle.write("v %.6f %.6f %.6f\n" % vertex)
            current_material: str | None = None
            for face, material in zip(part_faces, part_materials):
                if material != current_material:
                    handle.write(f"usemtl {material}\n")
                    current_material = material
                handle.write("f " + " ".join(str(vertex_cursor + index) for index in face) + "\n")
            vertex_cursor += len(part_vertices)
            total_vertices += len(part_vertices)
            total_faces += len(part_faces)
            total_triangles += sum(max(0, len(face) - 2) for face in part_faces)
            all_materials.update(part_materials)
            object_records.append({"name": object_name, "vertices": len(part_vertices), "faces": len(part_faces)})
    with path.with_suffix(".mtl").open("w", encoding="utf-8", newline="\n") as handle:
        handle.write(f"# Pipi Labu market kit material roles {SCRIPT_VERSION}\n")
        selected = [material_override] if material_override else list(MATERIALS)
        for material in selected:
            data = MATERIALS[material]
            r, g, b = data["rgb"]
            handle.write(f"newmtl {material}\nKd {r:.4f} {g:.4f} {b:.4f}\n")
            handle.write(f"# roughness {data['roughness']:.3f}\nillum 2\n\n")
    return {
        "path": path.as_posix(),
        "vertices": total_vertices,
        "faces": total_faces,
        "triangles": total_triangles,
        "objects": object_records,
        "materials": sorted(all_materials),
    }


def translate_parts(parts: list[Part], position: list[float]) -> list[Part]:
    px, py, pz = position
    return [
        Part(
            name=part.name,
            kind=part.kind,
            center=(part.center[0] + px, part.center[1] + py, part.center[2] + pz),
            size=part.size,
            material=part.material,
            radius=part.radius,
            segments=part.segments,
        )
        for part in parts
    ]


def generate_obj_artifacts(output_dir: Path, contract: dict[str, Any]) -> dict[str, Any]:
    modules_dir = output_dir / "modules"
    collision_dir = output_dir / "collision"
    modules_dir.mkdir(parents=True, exist_ok=True)
    collision_dir.mkdir(parents=True, exist_ok=True)
    reports: dict[str, Any] = {"script_version": SCRIPT_VERSION, "modules": {}, "collision": {}, "assembly": None}
    for module in contract["modules"]:
        module_id = module["id"]
        visual_report = write_obj(modules_dir / f"{module_id}.obj", [(module_id, visual_parts(module_id))])
        reports["modules"][module_id] = visual_report
        proxies = collision_parts(module_id)
        if proxies:
            collision_report = write_obj(collision_dir / f"COLLISION_{module_id}.obj", [(f"COLLISION_{module_id}", proxies)], "CollisionProxy")
            reports["collision"][module_id] = collision_report
    assembly_objects: list[tuple[str, list[Part]]] = []
    collision_objects: list[tuple[str, list[Part]]] = []
    for instance in LAYOUT_INSTANCES:
        module_id = instance["module"]
        position = instance["position"]
        assembly_objects.append((instance["name"], translate_parts(visual_parts(module_id), position)))
        proxies = collision_parts(module_id)
        if proxies:
            collision_objects.append((f"COLLISION_{instance['name']}", translate_parts(proxies, position)))
    reports["assembly"] = write_obj(output_dir / "market_kit_assembly.obj", assembly_objects)
    reports["assembly_collision"] = write_obj(output_dir / "market_kit_assembly_collision.obj", collision_objects, "CollisionProxy")
    layout = {
        "candidate_id": contract["candidate_id"],
        "layout_name": "single_stall_review_vignette",
        "front_axis": "+Z",
        "instances": LAYOUT_INSTANCES,
        "service_corridor": {"min": [-6.0, 0.0, 4.0], "max": [6.0, 4.25, 12.0], "width": 8.0},
        "notes": [
            "The corridor is a review keepout, not gameplay navigation or an active world layout.",
            "Lantern, planter, and bollard sit outside the central service sightline; display fruit stays behind the counter.",
            "The existing DogeAppleShop and PipilabuMarketVillagePrototype coordinates are not imported or modified by this layout."
        ],
    }
    (output_dir / "assembly_layout.json").write_text(json.dumps(layout, indent=2) + "\n", encoding="utf-8")
    (output_dir / "generation_report.json").write_text(json.dumps(reports, indent=2) + "\n", encoding="utf-8")
    return reports


def blender_materials() -> dict[str, Any]:
    assert bpy is not None
    result: dict[str, Any] = {}
    for name, data in MATERIALS.items():
        material = bpy.data.materials.get(name) or bpy.data.materials.new(name)
        material.diffuse_color = (*data["rgb"], 1.0)
        material.use_nodes = True
        node = material.node_tree.nodes.get("Principled BSDF")
        if node:
            node.inputs["Base Color"].default_value = (*data["rgb"], 1.0)
            node.inputs["Roughness"].default_value = data["roughness"]
            if "Metallic" in node.inputs:
                node.inputs["Metallic"].default_value = 0.0
        result[name] = material
    return result


def blender_link(obj: Any, collection: Any) -> None:
    assert bpy is not None
    for owner in list(obj.users_collection):
        owner.objects.unlink(obj)
    collection.objects.link(obj)


def build_blender_scene(output_dir: Path, contract: dict[str, Any]) -> None:
    """Build a review .blend when Blender, rather than Python, runs this file."""
    assert bpy is not None
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene["candidate_id"] = contract["candidate_id"]
    scene["candidate_status"] = contract["status"]
    scene["ApprovedForPresentation"] = False
    scene["StudioImported"] = False
    visual_collection = bpy.data.collections.new("PipilabuMarketKitV1_VISUAL")
    collision_collection = bpy.data.collections.new("PipilabuMarketKitV1_COLLISION")
    scene.collection.children.link(visual_collection)
    scene.collection.children.link(collision_collection)
    materials = blender_materials()

    def make_part(part: Part, position: list[float], collection: Any, object_name: str) -> Any:
        px, py, pz = position
        location = (part.center[0] + px, part.center[1] + py, part.center[2] + pz)
        if part.kind == "box":
            bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
            obj = bpy.context.object
            obj.dimensions = part.size
            bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        else:
            assert part.radius is not None
            bpy.ops.mesh.primitive_cylinder_add(vertices=part.segments, radius=part.radius, depth=part.size[1], location=location)
            obj = bpy.context.object
        obj.name = object_name
        obj.data.materials.append(materials[part.material])
        blender_link(obj, collection)
        return obj

    for instance in LAYOUT_INSTANCES:
        module_id = instance["module"]
        position = instance["position"]
        root = bpy.data.objects.new(instance["name"], None)
        root.empty_display_type = "PLAIN_AXES"
        root["ModuleId"] = module_id
        root["PivotType"] = next(item["pivot"]["type"] for item in contract["modules"] if item["id"] == module_id)
        visual_collection.objects.link(root)
        for part in visual_parts(module_id):
            obj = make_part(part, position, visual_collection, f"{instance['name']}__{part.name}")
            obj.parent = root
            obj["Layer"] = "Visual"
            obj["CanCollide"] = False
            obj["CanTouch"] = False
            obj["CanQuery"] = False
        for part in collision_parts(module_id):
            obj = make_part(part, position, collision_collection, f"{instance['name']}__{part.name}")
            obj["Layer"] = "Collision"
            obj["CanCollide"] = True
            obj["CanTouch"] = False
            obj["CanQuery"] = True
    output = output_dir / "blender"
    output.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(output / "PipilabuMarketKitV1.blend"))


def main() -> None:
    args = parse_args()
    output_dir = Path(args.output_dir).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    contract_path = output_dir / "market_kit_contract.json"
    contract = json.loads(contract_path.read_text(encoding="utf-8"))
    reports = generate_obj_artifacts(output_dir, contract)
    if bpy is not None:
        build_blender_scene(output_dir, contract)
        reports["blender_scene"] = "blender/PipilabuMarketKitV1.blend"
    else:
        reports["blender_scene"] = None
    (output_dir / "generation_report.json").write_text(json.dumps(reports, indent=2) + "\n", encoding="utf-8")
    print("PIPILABU_MARKET_KIT_GENERATED " + json.dumps({"output_dir": str(output_dir), "blender_scene": reports["blender_scene"]}, sort_keys=True))


if __name__ == "__main__":
    main()
