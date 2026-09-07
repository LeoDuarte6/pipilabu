"""Generate the isolated ART-003 apple and serving-prop review candidate.

The mesh lane is dependency-free OBJ/MTL so it can be inspected without
Blender. The review board is procedural Pillow drawing: no gameplay capture,
reference-video pixels, or canonical asset pixels are baked into the output.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFilter, ImageFont


SCRIPT_VERSION = "1.0.0"
CANVAS_SIZE = (1800, 1100)

COLORS: dict[str, tuple[int, int, int]] = {
    "AppleSkin_Ruby": (210, 49, 42),
    "AppleSkin_Honeygold": (239, 181, 54),
    "Stem_Wood": (82, 53, 31),
    "Leaf_Muted": (62, 112, 62),
    "Crate_WarmWood": (118, 78, 52),
    "Crate_DarkWood": (66, 46, 34),
    "Tray_Cream": (240, 226, 200),
    "Marker_Paper": (244, 231, 206),
    "RaritySeam_Reserved": (240, 196, 108),
    "CollisionProxy": (100, 100, 100),
}

MATERIAL_ROUGHNESS = {
    "AppleSkin_Ruby": 0.34,
    "AppleSkin_Honeygold": 0.34,
    "Stem_Wood": 0.78,
    "Leaf_Muted": 0.57,
    "Crate_WarmWood": 0.72,
    "Crate_DarkWood": 0.78,
    "Tray_Cream": 0.82,
    "Marker_Paper": 0.88,
    "RaritySeam_Reserved": 0.40,
    "CollisionProxy": 1.0,
}


class Mesh:
    def __init__(self) -> None:
        self.vertices: list[tuple[float, float, float]] = []
        self.faces: list[tuple[tuple[int, ...], str]] = []

    def vertex(self, point: tuple[float, float, float]) -> int:
        self.vertices.append(tuple(float(value) for value in point))
        return len(self.vertices) - 1

    def face(self, indices: tuple[int, ...], material: str) -> None:
        self.faces.append((indices, material))

    def bounds(self) -> tuple[list[float], list[float]]:
        if not self.vertices:
            return [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]
        minimum = [min(vertex[index] for vertex in self.vertices) for index in range(3)]
        maximum = [max(vertex[index] for vertex in self.vertices) for index in range(3)]
        return [round(value, 6) for value in minimum], [round(value, 6) for value in maximum]

    def triangles(self) -> int:
        return sum(max(0, len(indices) - 2) for indices, _ in self.faces)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate-dir", required=True)
    return parser.parse_args()


def add_box(mesh: Mesh, center: tuple[float, float, float], size: tuple[float, float, float], material: str) -> None:
    cx, cy, cz = center
    sx, sy, sz = (value / 2.0 for value in size)
    corners = [
        (cx - sx, cy - sy, cz - sz),
        (cx + sx, cy - sy, cz - sz),
        (cx + sx, cy + sy, cz - sz),
        (cx - sx, cy + sy, cz - sz),
        (cx - sx, cy - sy, cz + sz),
        (cx + sx, cy - sy, cz + sz),
        (cx + sx, cy + sy, cz + sz),
        (cx - sx, cy + sy, cz + sz),
    ]
    indices = [mesh.vertex(corner) for corner in corners]
    mesh.face((indices[0], indices[1], indices[2], indices[3]), material)
    mesh.face((indices[4], indices[7], indices[6], indices[5]), material)
    mesh.face((indices[0], indices[4], indices[5], indices[1]), material)
    mesh.face((indices[1], indices[5], indices[6], indices[2]), material)
    mesh.face((indices[2], indices[6], indices[7], indices[3]), material)
    mesh.face((indices[4], indices[0], indices[3], indices[7]), material)


def add_cylinder_y(mesh: Mesh, center: tuple[float, float, float], radius: float, height: float, material: str, sides: int = 10) -> None:
    cx, cy, cz = center
    bottom = [mesh.vertex((cx + math.cos(2.0 * math.pi * index / sides) * radius, cy - height / 2.0, cz + math.sin(2.0 * math.pi * index / sides) * radius)) for index in range(sides)]
    top = [mesh.vertex((cx + math.cos(2.0 * math.pi * index / sides) * radius, cy + height / 2.0, cz + math.sin(2.0 * math.pi * index / sides) * radius)) for index in range(sides)]
    bottom_center = mesh.vertex((cx, cy - height / 2.0, cz))
    top_center = mesh.vertex((cx, cy + height / 2.0, cz))
    for index in range(sides):
        next_index = (index + 1) % sides
        mesh.face((bottom_center, bottom[next_index], bottom[index]), material)
        mesh.face((top_center, top[index], top[next_index]), material)
        mesh.face((bottom[index], bottom[next_index], top[next_index], top[index]), material)


def add_apple(mesh: Mesh, skin_material: str) -> None:
    rings = [(-0.52, 0.28), (-0.42, 0.52), (-0.12, 0.62), (0.22, 0.625), (0.42, 0.50), (0.48, 0.22)]
    sides = 16
    ring_indices: list[list[int]] = []
    for y, radius in rings:
        ring: list[int] = []
        for index in range(sides):
            angle = 2.0 * math.pi * index / sides
            lobe = 1.0 + 0.04 * math.cos(4.0 * angle)
            ring.append(mesh.vertex((math.cos(angle) * radius * lobe, y, math.sin(angle) * radius * lobe)))
        ring_indices.append(ring)

    bottom_center = mesh.vertex((0.0, -0.52, 0.0))
    top_center = mesh.vertex((0.0, 0.46, 0.0))
    for index in range(sides):
        next_index = (index + 1) % sides
        mesh.face((bottom_center, ring_indices[0][next_index], ring_indices[0][index]), skin_material)
        mesh.face((ring_indices[-1][index], ring_indices[-1][next_index], top_center), skin_material)
    for ring_index in range(len(ring_indices) - 1):
        lower = ring_indices[ring_index]
        upper = ring_indices[ring_index + 1]
        for index in range(sides):
            next_index = (index + 1) % sides
            mesh.face((lower[index], lower[next_index], upper[next_index], upper[index]), skin_material)

    add_cylinder_y(mesh, (0.0, 0.64, 0.0), 0.06, 0.32, "Stem_Wood", sides=10)
    leaf = [
        mesh.vertex((0.08, 0.64, -0.07)),
        mesh.vertex((0.45, 0.69, 0.0)),
        mesh.vertex((0.28, 0.72, 0.13)),
        mesh.vertex((0.08, 0.67, 0.07)),
    ]
    mesh.face((leaf[0], leaf[1], leaf[2]), "Leaf_Muted")
    mesh.face((leaf[0], leaf[2], leaf[3]), "Leaf_Muted")


def add_crate(mesh: Mesh, accent_material: str) -> None:
    add_box(mesh, (0.0, 0.12, 0.0), (6.0, 0.24, 5.0), "Crate_WarmWood")
    add_box(mesh, (0.0, 0.55, -2.38), (6.0, 0.66, 0.24), "Crate_DarkWood")
    add_box(mesh, (0.0, 0.55, 2.38), (6.0, 0.66, 0.24), "Crate_DarkWood")
    add_box(mesh, (-2.88, 0.55, 0.0), (0.24, 0.66, 4.52), "Crate_DarkWood")
    add_box(mesh, (2.88, 0.55, 0.0), (0.24, 0.66, 4.52), "Crate_DarkWood")
    for x in (-2.84, 2.84):
        for z in (-2.34, 2.34):
            add_box(mesh, (x, 1.25, z), (0.32, 2.5, 0.32), "Crate_WarmWood")
    for y in (1.0, 1.48, 1.96):
        add_box(mesh, (0.0, y, 2.47), (5.55, 0.14, 0.06), "Crate_DarkWood")
        add_box(mesh, (0.0, y, -2.47), (5.55, 0.14, 0.06), "Crate_DarkWood")
    add_box(mesh, (0.0, 1.42, 2.49), (4.8, 0.62, 0.02), accent_material)


def add_tray(mesh: Mesh) -> None:
    add_box(mesh, (0.0, 0.07, 0.0), (3.2, 0.14, 1.6), "Crate_WarmWood")
    add_box(mesh, (0.0, 0.16, -0.72), (3.2, 0.32, 0.16), "Crate_DarkWood")
    add_box(mesh, (-1.52, 0.11, 0.0), (0.16, 0.22, 1.44), "Crate_DarkWood")
    add_box(mesh, (1.52, 0.11, 0.0), (0.16, 0.22, 1.44), "Crate_DarkWood")
    add_box(mesh, (0.0, 0.04, 0.72), (3.2, 0.08, 0.16), "Crate_DarkWood")
    add_box(mesh, (0.0, 0.15, 0.0), (2.4, 0.03, 0.04), "Tray_Cream")


def add_marker(mesh: Mesh, accent_material: str) -> None:
    add_box(mesh, (0.0, 0.375, 0.0), (1.0, 0.75, 0.12), "Marker_Paper")
    add_box(mesh, (0.0, 0.43, 0.0575), (0.34, 0.25, 0.005), accent_material)
    add_box(mesh, (0.0, 0.63, 0.0575), (0.07, 0.12, 0.005), "Stem_Wood")


def build_module(module_id: str) -> Mesh:
    mesh = Mesh()
    if module_id == "APPLE_RUBY_HANDOFF_1_3":
        add_apple(mesh, "AppleSkin_Ruby")
    elif module_id == "APPLE_HONEYGOLD_HANDOFF_1_3":
        add_apple(mesh, "AppleSkin_Honeygold")
    elif module_id == "CRATE_RUBY_6X2_5":
        add_crate(mesh, "AppleSkin_Ruby")
    elif module_id == "CRATE_HONEYGOLD_6X2_5":
        add_crate(mesh, "AppleSkin_Honeygold")
    elif module_id == "COUNTER_TRAY_3X1_6":
        add_tray(mesh)
    elif module_id == "PRICE_MARKER_RUBY_1X0_75":
        add_marker(mesh, "AppleSkin_Ruby")
    elif module_id == "PRICE_MARKER_HONEYGOLD_1X0_75":
        add_marker(mesh, "AppleSkin_Honeygold")
    else:
        raise ValueError(f"Unknown module id: {module_id}")
    return mesh


def build_collision() -> Mesh:
    mesh = Mesh()
    add_box(mesh, (0.0, 1.25, 0.0), (6.0, 2.5, 5.0), "CollisionProxy")
    return mesh


def merge_mesh(target: Mesh, source: Mesh, offset: tuple[float, float, float]) -> None:
    index_offset = len(target.vertices)
    target.vertices.extend((vertex[0] + offset[0], vertex[1] + offset[1], vertex[2] + offset[2]) for vertex in source.vertices)
    target.faces.extend((tuple(index + index_offset for index in indices), material) for indices, material in source.faces)


def material_names(mesh: Mesh) -> list[str]:
    return sorted({material for _, material in mesh.faces})


def write_mtl(path: Path, names: list[str]) -> None:
    lines: list[str] = ["# ART-003 authored material roles; review-only OBJ/MTL output."]
    for name in names:
        color = COLORS[name]
        red, green, blue = (component / 255.0 for component in color)
        specular = 0.16 if name.startswith("AppleSkin") else 0.04
        lines.extend([
            f"newmtl {name}",
            f"Kd {red:.6f} {green:.6f} {blue:.6f}",
            f"Ks {specular:.6f} {specular:.6f} {specular:.6f}",
            f"Ns {max(1, int(round((1.0 - MATERIAL_ROUGHNESS[name]) * 180.0)))}",
            "d 1.000000",
            "illum 2",
            "",
        ])
    path.write_text("\n".join(lines), encoding="utf-8", newline="\n")


def write_obj(path: Path, mesh: Mesh, material_file: str) -> dict[str, Any]:
    names = material_names(mesh)
    lines = [f"mtllib {material_file}", "o ART003_PROP"]
    lines.extend(f"v {vertex[0]:.6f} {vertex[1]:.6f} {vertex[2]:.6f}" for vertex in mesh.vertices)
    current_material = ""
    for indices, material in mesh.faces:
        if material != current_material:
            lines.append(f"usemtl {material}")
            current_material = material
        lines.append("f " + " ".join(str(index + 1) for index in indices))
    path.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    bounds_min, bounds_max = mesh.bounds()
    return {
        "file": path.name,
        "vertices": len(mesh.vertices),
        "faces": len(mesh.faces),
        "triangles": mesh.triangles(),
        "bounds_min": bounds_min,
        "bounds_max": bounds_max,
        "materials": names,
    }


def font(size: int, bold: bool = False) -> ImageFont.ImageFont:
    candidates = [
        Path("C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf"),
        Path("C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf"),
    ]
    for candidate in candidates:
        if candidate.is_file():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default()


def text(draw: ImageDraw.ImageDraw, xy: tuple[float, float], value: str, size: int, fill: tuple[int, int, int], bold: bool = False, anchor: str | None = None) -> None:
    draw.text(xy, value, font=font(size, bold), fill=fill, anchor=anchor)


def arrow(draw: ImageDraw.ImageDraw, start: tuple[float, float], end: tuple[float, float], fill: tuple[int, int, int], width: int = 4) -> None:
    draw.line((*start, *end), fill=fill, width=width)
    angle = math.atan2(end[1] - start[1], end[0] - start[0])
    size = 15
    left = (end[0] - math.cos(angle - 0.55) * size, end[1] - math.sin(angle - 0.55) * size)
    right = (end[0] - math.cos(angle + 0.55) * size, end[1] - math.sin(angle + 0.55) * size)
    draw.polygon([end, left, right], fill=fill)


def draw_apple_icon(draw: ImageDraw.ImageDraw, center: tuple[float, float], scale: float, color: tuple[int, int, int], shadow: tuple[int, int, int] = (120, 40, 32), contact_ring: bool = False) -> None:
    cx, cy = center
    if contact_ring:
        draw.ellipse((cx - 72 * scale, cy - 72 * scale, cx + 72 * scale, cy + 72 * scale), outline=(240, 196, 108), width=max(2, int(5 * scale)))
    draw.ellipse((cx - 42 * scale, cy - 40 * scale, cx + 8 * scale, cy + 42 * scale), fill=color, outline=shadow, width=max(1, int(2 * scale)))
    draw.ellipse((cx - 8 * scale, cy - 40 * scale, cx + 42 * scale, cy + 42 * scale), fill=color, outline=shadow, width=max(1, int(2 * scale)))
    draw.ellipse((cx - 28 * scale, cy - 20 * scale, cx - 14 * scale, cy - 8 * scale), fill=(255, 236, 210))
    draw.line((cx, cy - 38 * scale, cx + 3 * scale, cy - 70 * scale), fill=COLORS["Stem_Wood"], width=max(2, int(5 * scale)))
    draw.ellipse((cx + 4 * scale, cy - 66 * scale, cx + 35 * scale, cy - 52 * scale), fill=COLORS["Leaf_Muted"], outline=COLORS["Stem_Wood"], width=max(1, int(2 * scale)))


def draw_paw(draw: ImageDraw.ImageDraw, center: tuple[float, float], scale: float, fill: tuple[int, int, int] = (238, 220, 187)) -> None:
    cx, cy = center
    draw.ellipse((cx - 43 * scale, cy - 27 * scale, cx + 43 * scale, cy + 27 * scale), fill=fill, outline=(175, 143, 103), width=max(1, int(2 * scale)))
    for offset in (-17, 0, 17):
        draw.arc((cx + (offset - 8) * scale, cy - 2 * scale, cx + (offset + 8) * scale, cy + 15 * scale), 10, 170, fill=(175, 143, 103), width=max(1, int(2 * scale)))


def draw_crate(draw: ImageDraw.ImageDraw, center: tuple[float, float], scale: float, accent: tuple[int, int, int]) -> None:
    cx, cy = center
    width, height = 360 * scale, 148 * scale
    x0, y0 = cx - width / 2, cy - height / 2
    draw.rounded_rectangle((x0, y0, x0 + width, y0 + height), radius=int(10 * scale), fill=COLORS["Crate_WarmWood"], outline=COLORS["Crate_DarkWood"], width=max(2, int(4 * scale)))
    draw.rectangle((x0 + 18 * scale, y0 + 26 * scale, x0 + width - 18 * scale, y0 + 48 * scale), fill=COLORS["Crate_DarkWood"])
    draw.rectangle((x0 + 18 * scale, y0 + height - 48 * scale, x0 + width - 18 * scale, y0 + height - 26 * scale), fill=COLORS["Crate_DarkWood"])
    draw.rectangle((cx - 116 * scale, y0 + 58 * scale, cx + 116 * scale, y0 + 90 * scale), fill=accent)
    for apple_x in (-115, -38, 38, 115):
        draw_apple_icon(draw, (cx + apple_x * scale, y0 + 10 * scale), 0.48 * scale, accent)


def draw_tray(draw: ImageDraw.ImageDraw, center: tuple[float, float], scale: float, apple_color: tuple[int, int, int]) -> None:
    cx, cy = center
    width, height = 228 * scale, 116 * scale
    x0, y0 = cx - width / 2, cy - height / 2
    draw.rounded_rectangle((x0, y0, x0 + width, y0 + height), radius=int(8 * scale), fill=COLORS["Crate_WarmWood"], outline=COLORS["Crate_DarkWood"], width=max(2, int(4 * scale)))
    draw.rectangle((x0 + 10 * scale, y0 + 12 * scale, x0 + width - 10 * scale, y0 + 26 * scale), fill=COLORS["Crate_DarkWood"])
    draw.rectangle((x0 + 12 * scale, y0 + height - 19 * scale, x0 + width - 12 * scale, y0 + height - 8 * scale), fill=COLORS["Crate_DarkWood"])
    draw_apple_icon(draw, (cx, cy - 12 * scale), 0.66 * scale, apple_color)


def draw_review_sheet(contract: dict[str, Any]) -> Image.Image:
    board = (78, 74, 70)
    paper = (244, 231, 206)
    soft = (210, 198, 178)
    gold = (240, 196, 108)
    ink = (48, 39, 33)
    canvas = Image.new("RGB", CANVAS_SIZE, board)
    draw = ImageDraw.Draw(canvas)
    draw.rectangle((44, 40, 1756, 1060), outline=(150, 140, 126), width=2)
    draw.line((74, 146, 1724, 146), fill=(150, 140, 126), width=1)
    text(draw, (76, 70), "PIPI LABU", 44, paper, bold=True)
    text(draw, (78, 118), "APPLE / SERVING PROP KIT  /  V1", 16, soft, bold=True)
    text(draw, (1720, 77), "ART-003", 20, gold, bold=True, anchor="ra")
    text(draw, (1720, 110), "REVIEW CANDIDATE", 13, soft, anchor="ra")

    text(draw, (84, 198), "FAMILY MODULES", 18, gold, bold=True)
    text(draw, (84, 228), "Ruby baseline / Honeygold contrast / one quiet contact language", 15, paper)
    draw_crate(draw, (300, 372), 1.0, COLORS["AppleSkin_Ruby"])
    draw_crate(draw, (700, 372), 1.0, COLORS["AppleSkin_Honeygold"])
    text(draw, (300, 494), "RUBY CRATE", 15, paper, bold=True, anchor="ma")
    text(draw, (300, 520), "6 × 2.5 × 5 studs / proxy only", 12, soft, anchor="ma")
    text(draw, (700, 494), "HONEYGOLD CRATE", 15, paper, bold=True, anchor="ma")
    text(draw, (700, 520), "same scale / one current color variable", 12, soft, anchor="ma")
    draw_tray(draw, (345, 675), 1.0, COLORS["AppleSkin_Ruby"])
    text(draw, (345, 760), "COUNTER TRAY", 14, paper, bold=True, anchor="ma")
    text(draw, (345, 785), "front 0.65 studs kept open", 12, soft, anchor="ma")
    draw.rounded_rectangle((620, 620, 780, 740), radius=8, fill=COLORS["Marker_Paper"], outline=COLORS["Crate_DarkWood"], width=4)
    draw.rectangle((682, 678, 718, 708), fill=COLORS["AppleSkin_Honeygold"], outline=COLORS["Crate_DarkWood"], width=2)
    draw.line((700, 678, 704, 655), fill=COLORS["Stem_Wood"], width=4)
    text(draw, (700, 772), "SMALL MARKER", 14, paper, bold=True, anchor="ma")
    text(draw, (700, 797), "display label / no economy", 12, soft, anchor="ma")
    draw.line((90, 850, 900, 850), fill=(150, 140, 126), width=1)
    text(draw, (90, 878), "NON-COLLIDING", 12, gold, bold=True)
    text(draw, (90, 906), "apple / stem / leaf / tray / marker", 13, paper)
    text(draw, (90, 940), "ONLY THE CRATE PROXY OWNS MOVEMENT COLLISION", 12, soft, bold=True)

    text(draw, (1030, 198), "SERVING IS THE PEAK", 18, gold, bold=True)
    text(draw, (1030, 228), "The board enlarges contact and receipt; pickup stays quiet.", 15, paper)
    draw.line((1082, 470, 1668, 470), fill=(150, 140, 126), width=2)
    arrow(draw, (1135, 470), (1290, 470), gold, width=3)
    arrow(draw, (1380, 470), (1535, 470), gold, width=3)

    # Carry: a small visible prop in a simple player-hand silhouette.
    draw.ellipse((1060, 382, 1180, 520), fill=(116, 84, 59), outline=(66, 46, 34), width=3)
    draw_paw(draw, (1120, 420), 0.72, fill=(218, 174, 129))
    draw_apple_icon(draw, (1120, 325), 0.72, COLORS["AppleSkin_Ruby"])
    text(draw, (1120, 548), "CARRY", 15, paper, bold=True, anchor="ma")
    text(draw, (1120, 578), "visible / functional", 12, soft, anchor="ma")

    # Contact: the largest authored beat, with both target paws visible.
    draw_paw(draw, (1308, 410), 0.82, fill=(218, 174, 129))
    draw_paw(draw, (1442, 410), 0.82)
    draw.arc((1278, 274, 1472, 468), 200, 340, fill=gold, width=4)
    draw_apple_icon(draw, (1375, 350), 1.24, COLORS["AppleSkin_Ruby"], contact_ring=True)
    text(draw, (1375, 548), "CONTACT", 16, gold, bold=True, anchor="ma")
    text(draw, (1375, 578), "largest / clearest / no clutter", 12, paper, anchor="ma")

    # Receipt: apple nests between customer paws, smaller than contact but still clear.
    draw_paw(draw, (1572, 418), 0.78)
    draw_paw(draw, (1682, 418), 0.78)
    draw_apple_icon(draw, (1627, 348), 1.02, COLORS["AppleSkin_Honeygold"])
    text(draw, (1627, 548), "CUSTOMER HOLD", 15, paper, bold=True, anchor="ma")
    text(draw, (1627, 578), "receipt stays visible", 12, soft, anchor="ma")

    draw.rounded_rectangle((1030, 650, 1718, 925), radius=14, outline=(150, 140, 126), width=1)
    text(draw, (1060, 682), "MOBILE READ", 13, gold, bold=True)
    text(draw, (1060, 710), "At thumbnail scale: body first, leaf second, paw gap always open.", 14, paper)
    draw_paw(draw, (1150, 825), 0.62, fill=(218, 174, 129))
    draw_apple_icon(draw, (1260, 770), 0.72, COLORS["AppleSkin_Ruby"])
    draw_paw(draw, (1380, 825), 0.62)
    draw_apple_icon(draw, (1495, 770), 0.72, COLORS["AppleSkin_Honeygold"])
    draw_paw(draw, (1610, 825), 0.62)
    text(draw, (1060, 882), "RUBY / HONEYGOLD", 12, soft, bold=True)
    text(draw, (1060, 908), "same silhouette / different request color", 12, soft)

    text(draw, (78, 1028), "NO NEW MECHANIC  /  NO RARITY GLOW  /  NO PROMPT COLLISION  /  NO HUMAN APPROVAL CLAIMED", 12, soft, bold=True)
    return canvas


def make_layout() -> dict[str, Any]:
    return {
        "schema_version": 1,
        "units": "Roblox studs",
        "coordinate_contract": {"up": "+Y", "service_front": "+Z", "right": "+X"},
        "placements": [
            {"module_id": "CRATE_RUBY_6X2_5", "position": [-4.25, 0.0, 0.0], "state": "source_baseline"},
            {"module_id": "CRATE_HONEYGOLD_6X2_5", "position": [4.25, 0.0, 0.0], "state": "source_contrast"},
            {"module_id": "APPLE_RUBY_HANDOFF_1_3", "position": [-4.25, 2.75, 0.0], "state": "display_only"},
            {"module_id": "APPLE_HONEYGOLD_HANDOFF_1_3", "position": [4.25, 2.75, 0.0], "state": "display_only"},
            {"module_id": "COUNTER_TRAY_3X1_6", "position": [0.0, 2.65, 3.8], "state": "counter_display"},
            {"module_id": "PRICE_MARKER_RUBY_1X0_75", "position": [-1.25, 2.65, 3.8], "state": "display_label"},
            {"module_id": "PRICE_MARKER_HONEYGOLD_1X0_75", "position": [1.25, 2.65, 3.8], "state": "display_label"}
        ],
        "handoff_story": [
            {"state": "carry", "prop_id": "APPLE_RUBY_HANDOFF_1_3", "scale": [1.0, 1.0, 1.0], "collision_mode": "none"},
            {"state": "contact", "prop_id": "APPLE_RUBY_HANDOFF_1_3", "scale": [1.09, 0.89, 1.09], "target": "Paw_R / paired-paw midpoint", "visual_only": True},
            {"state": "customer_hold", "prop_id": "APPLE_HONEYGOLD_HANDOFF_1_3", "scale": [1.0, 1.0, 1.0], "target": "CustomerAppleWeld", "collision_mode": "none"}
        ],
        "rarity_seam": {"status": "reserved_omitted", "runtime": False}
    }


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    args = parse_args()
    candidate_dir = Path(args.candidate_dir).resolve()
    contract_path = candidate_dir / "apple_serving_props_contract.json"
    contract = json.loads(contract_path.read_text(encoding="utf-8"))
    modules_dir = candidate_dir / "modules"
    collision_dir = candidate_dir / "collision"
    modules_dir.mkdir(parents=True, exist_ok=True)
    collision_dir.mkdir(parents=True, exist_ok=True)

    metrics: dict[str, Any] = {}
    for module in contract["modules"]:
        module_id = module["id"]
        mesh = build_module(module_id)
        obj_path = candidate_dir / module["file"]
        mtl_path = candidate_dir / module["material_file"]
        obj_path.parent.mkdir(parents=True, exist_ok=True)
        metrics[module_id] = write_obj(obj_path, mesh, mtl_path.name)
        write_mtl(mtl_path, material_names(mesh))

    collision_mesh = build_collision()
    collision_obj_path = candidate_dir / contract["collision_contract"]["file"]
    collision_mtl_path = collision_obj_path.with_suffix(".mtl")
    collision_metrics = write_obj(collision_obj_path, collision_mesh, collision_mtl_path.name)
    write_mtl(collision_mtl_path, material_names(collision_mesh))
    metrics["COLLISION_CRATE_6X2_5"] = collision_metrics

    layout = make_layout()
    layout_path = candidate_dir / "assembly_layout.json"
    layout_path.write_text(json.dumps(layout, indent=2) + "\n", encoding="utf-8", newline="\n")

    assembly = Mesh()
    for placement in layout["placements"]:
        merge_mesh(assembly, build_module(placement["module_id"]), tuple(placement["position"]))
    assembly_path = candidate_dir / "apple_serving_prop_assembly.obj"
    assembly_mtl_path = candidate_dir / "apple_serving_prop_assembly.mtl"
    assembly_metrics = write_obj(assembly_path, assembly, assembly_mtl_path.name)
    write_mtl(assembly_mtl_path, material_names(assembly))

    review_image = draw_review_sheet(contract)
    review_path = candidate_dir / contract["review_artifact"]["file"]
    review_image.save(review_path, format="PNG", optimize=False, compress_level=9)

    generated_files = [
        Path(module["file"]).as_posix() for module in contract["modules"]
    ] + [
        Path(module["material_file"]).as_posix() for module in contract["modules"]
    ] + [
        Path(contract["collision_contract"]["file"]).as_posix(),
        Path(Path(contract["collision_contract"]["file"]).with_suffix(".mtl")).as_posix(),
        "assembly_layout.json",
        "apple_serving_prop_assembly.obj",
        "apple_serving_prop_assembly.mtl",
        contract["review_artifact"]["file"],
    ]
    report = {
        "generator_version": SCRIPT_VERSION,
        "candidate_id": contract["candidate_id"],
        "ticket": contract["ticket"],
        "module_count": len(contract["modules"]),
        "module_metrics": metrics,
        "collision_metrics": collision_metrics,
        "assembly_metrics": assembly_metrics,
        "review_artifact": {"file": review_path.name, "width": review_image.width, "height": review_image.height, "sha256": sha256(review_path)},
        "generated_files": sorted(generated_files),
        "source_pixels": "procedural Pillow drawing and generated OBJ/MTL only",
        "studio_imported": False,
        "human_approved": False,
    }
    (candidate_dir / "generation_report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8", newline="\n")
    print("PIPILABU_APPLE_PROPS_GENERATED " + json.dumps(report, sort_keys=True))


if __name__ == "__main__":
    main()
