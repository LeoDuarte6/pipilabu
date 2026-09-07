"""Generate a deterministic Pipi Labu baby-customer cast review sheet.

The sheet is purpose-built from the local role contract with Pillow. It does
not read, edit, or bake pixels from any canonical character asset or reference
video. The existing v4 side-ear customer candidate remains the future geometry
source of truth; this ticket is a bounded cast-direction study.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import textwrap
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFilter, ImageFont


SCRIPT_VERSION = "1.0.0"
CANVAS_SIZE = (1600, 1000)

COLORS = {
    "board": "#55514E",
    "board_deep": "#403D3B",
    "board_line": "#8F8A82",
    "paper": "#F4E7CE",
    "paper_soft": "#D9CBB5",
    "ink": "#332B27",
    "ink_soft": "#A59A8D",
    "coat": "#C9782B",
    "coat_light": "#D98B39",
    "coat_shadow": "#A95E26",
    "muzzle": "#E9D3AB",
    "muzzle_shadow": "#C8AA83",
    "paw": "#EAD8B8",
    "paw_shadow": "#B9956D",
    "eye": "#191616",
    "eye_glint": "#FFF7E6",
    "ruby": "#C44438",
    "honeygold": "#E1A543",
    "shy": "#9BA69C",
    "hurry": "#F0C476",
    "leaf": "#66855B",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate-dir", required=True)
    return parser.parse_args()


def load_font(size: int, bold: bool = False) -> ImageFont.ImageFont:
    candidates = [
        Path("C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf"),
        Path("C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf"),
    ]
    for candidate in candidates:
        if candidate.is_file():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default()


def draw_text(draw: ImageDraw.ImageDraw, xy: tuple[float, float], text: str, size: int, fill: str, bold: bool = False, anchor: str | None = None) -> None:
    draw.text(xy, text, font=load_font(size, bold), fill=fill, anchor=anchor)


def draw_wrapped_text(draw: ImageDraw.ImageDraw, xy: tuple[float, float], text: str, size: int, fill: str, width: int, bold: bool = False, line_gap: int = 4) -> None:
    font = load_font(size, bold)
    lines = textwrap.wrap(text, width=width, break_long_words=False, break_on_hyphens=False)
    draw.multiline_text(xy, "\n".join(lines), font=font, fill=fill, spacing=line_gap)


def ellipse_box(cx: float, cy: float, width: float, height: float) -> tuple[float, float, float, float]:
    return (cx - width / 2, cy - height / 2, cx + width / 2, cy + height / 2)


def line_width(scale: float) -> int:
    return max(1, int(round(2.0 * scale)))


def add_shadow(canvas: Image.Image, box: tuple[float, float, float, float], alpha: int = 100, blur: int = 10) -> None:
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    shadow_box = (box[0], box[1] + 12, box[2], box[3] + 18)
    draw.ellipse(shadow_box, fill=(17, 13, 12, alpha))
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    canvas.alpha_composite(layer)


def draw_paw(draw: ImageDraw.ImageDraw, cx: float, cy: float, scale: float, lifted: bool = False) -> None:
    width = 62 * scale
    height = 38 * scale
    if lifted:
        cy -= 28 * scale
    draw.ellipse(ellipse_box(cx, cy, width, height), fill=COLORS["paw"], outline=COLORS["paw_shadow"], width=line_width(scale))
    toe_y = cy + 8 * scale
    for offset in (-13, 0, 13):
        draw.arc(ellipse_box(cx + offset * scale, toe_y, 11 * scale, 14 * scale), 8, 172, fill=COLORS["paw_shadow"], width=line_width(scale))


def draw_apple(draw: ImageDraw.ImageDraw, cx: float, cy: float, scale: float, color: str) -> None:
    radius = 18 * scale
    draw.ellipse(ellipse_box(cx, cy + 2 * scale, radius * 2.0, radius * 1.8), fill=color, outline=COLORS["ink"], width=line_width(scale))
    draw.line((cx, cy - radius * 0.75, cx + 2 * scale, cy - radius * 1.55), fill=COLORS["ink"], width=max(1, int(2 * scale)))
    draw.ellipse(ellipse_box(cx + 9 * scale, cy - radius * 1.35, 13 * scale, 6 * scale), fill=COLORS["leaf"])
    draw.ellipse(ellipse_box(cx - radius * 0.45, cy - radius * 0.2, 5 * scale, 4 * scale), fill=(255, 242, 210))


def draw_eye(draw: ImageDraw.ImageDraw, cx: float, cy: float, width: float, height: float, glint_offset: tuple[float, float] = (-4, -2)) -> None:
    draw.ellipse(ellipse_box(cx, cy, width, height), fill=COLORS["eye"])
    gx = cx + glint_offset[0]
    gy = cy + glint_offset[1]
    draw.ellipse(ellipse_box(gx, gy, max(3, width * 0.24), max(2, height * 0.20)), fill=COLORS["eye_glint"])
    draw.ellipse(ellipse_box(cx + width * 0.22, cy + height * 0.16, max(2, width * 0.11), max(2, height * 0.10)), fill=COLORS["honeygold"])


def draw_customer(canvas: Image.Image, center: tuple[float, float], scale: float, role_id: str = "SharedBase", role: dict[str, Any] | None = None) -> None:
    draw = ImageDraw.Draw(canvas)
    cx, cy = center
    body_scale = float(role.get("body_scale", 1.0) if role else 1.0)
    head_scale = float(role.get("head_scale", 1.0) if role else 1.0)
    lean = -8 * scale if role_id == "HurryWaddle" else 0.0
    body_width = 176 * scale * body_scale
    body_height = 136 * scale * (0.90 if role_id == "ShyLoaf" else 1.0)
    body_center = (cx + lean, cy + 96 * scale)
    body_box = ellipse_box(body_center[0], body_center[1], body_width, body_height)
    add_shadow(canvas, (body_box[0], body_box[1] + 14 * scale, body_box[2], body_box[3] + 16 * scale), alpha=90, blur=max(4, int(10 * scale)))

    draw.ellipse(body_box, fill=COLORS["coat"], outline=COLORS["coat_shadow"], width=line_width(scale))
    belly_box = ellipse_box(body_center[0], body_center[1] + body_height * 0.28, body_width * 0.62, body_height * 0.70)
    draw.ellipse(belly_box, fill=COLORS["muzzle"], outline=COLORS["muzzle_shadow"], width=max(1, line_width(scale) - 1))

    head_radius = 105 * scale * head_scale
    head_center = (cx + lean, cy)
    # Tiny lateral hints are drawn behind the head and never rise above its crown.
    ear_height = 20 * scale
    ear_width = 22 * scale
    for side in (-1, 1):
        ear_x = head_center[0] + side * head_radius * 0.93
        ear_y = head_center[1] + 7 * scale
        draw.ellipse(ellipse_box(ear_x, ear_y, ear_width, ear_height), fill=COLORS["coat_shadow"], outline=COLORS["coat_shadow"], width=1)
    head_box = ellipse_box(head_center[0], head_center[1], head_radius * 2.0, head_radius * 2.0)
    draw.ellipse(head_box, fill=COLORS["coat_light"], outline=COLORS["coat_shadow"], width=line_width(scale))
    # The cream transition stays below the eyes; there is no cream forehead mask.
    lower_face_box = (head_box[0] + 5 * scale, head_center[1] + head_radius * 0.18, head_box[2] - 5 * scale, head_box[3] - 4 * scale)
    draw.ellipse(lower_face_box, fill=COLORS["muzzle"], outline=None)

    muzzle_y = head_center[1] + 26 * scale
    muzzle_width = 106 * scale
    muzzle_height = 63 * scale
    draw.ellipse(ellipse_box(head_center[0] - 31 * scale, muzzle_y, muzzle_width, muzzle_height), fill=COLORS["muzzle"])
    draw.ellipse(ellipse_box(head_center[0] + 31 * scale, muzzle_y, muzzle_width, muzzle_height), fill=COLORS["muzzle"])
    draw.ellipse(ellipse_box(head_center[0], muzzle_y + 13 * scale, 34 * scale, 25 * scale), fill=COLORS["eye"])
    draw.line((head_center[0], muzzle_y + 24 * scale, head_center[0], muzzle_y + 40 * scale), fill=COLORS["ink"], width=line_width(scale))
    draw.arc(ellipse_box(head_center[0] - 18 * scale, muzzle_y + 26 * scale, 36 * scale, 24 * scale), 0, 170, fill=COLORS["ink"], width=line_width(scale))
    draw.arc(ellipse_box(head_center[0] + 18 * scale, muzzle_y + 26 * scale, 36 * scale, 24 * scale), 10, 180, fill=COLORS["ink"], width=line_width(scale))

    eyes_y = head_center[1] + 6 * scale
    eye_offset = 42 * scale
    if role_id == "HoneygoldHugger":
        for side in (-1, 1):
            eye_box = ellipse_box(head_center[0] + side * eye_offset, eyes_y, 35 * scale, 16 * scale)
            draw.arc(eye_box, 200, 340, fill=COLORS["eye"], width=max(2, line_width(scale)))
    elif role_id == "ShyLoaf":
        draw_eye(draw, head_center[0] - eye_offset, eyes_y + 5 * scale, 35 * scale, 14 * scale, (3 * scale, 2 * scale))
        draw_eye(draw, head_center[0] + eye_offset, eyes_y + 7 * scale, 35 * scale, 12 * scale, (5 * scale, 2 * scale))
    elif role_id == "HurryWaddle":
        draw_eye(draw, head_center[0] - eye_offset, eyes_y, 39 * scale, 24 * scale)
        draw_eye(draw, head_center[0] + eye_offset, eyes_y, 39 * scale, 24 * scale)
    else:
        draw_eye(draw, head_center[0] - eye_offset, eyes_y, 36 * scale, 20 * scale)
        draw_eye(draw, head_center[0] + eye_offset, eyes_y, 36 * scale, 20 * scale)

    paw_y = body_center[1] + body_height * 0.42
    if role_id == "RubySprout":
        draw_paw(draw, body_center[0] - 54 * scale, paw_y - 4 * scale, scale, lifted=True)
        draw_paw(draw, body_center[0] + 59 * scale, paw_y + 4 * scale, scale)
    elif role_id == "HoneygoldHugger":
        draw_apple(draw, body_center[0], paw_y - 12 * scale, scale, COLORS["honeygold"])
        draw_paw(draw, body_center[0] - 52 * scale, paw_y - 10 * scale, scale, lifted=True)
        draw_paw(draw, body_center[0] + 52 * scale, paw_y - 10 * scale, scale, lifted=True)
    elif role_id == "ShyLoaf":
        draw_paw(draw, body_center[0] - 36 * scale, paw_y + 10 * scale, scale * 0.82)
        draw_paw(draw, body_center[0] + 36 * scale, paw_y + 10 * scale, scale * 0.82)
    elif role_id == "HurryWaddle":
        draw_paw(draw, body_center[0] - 52 * scale, paw_y + 5 * scale, scale)
        draw_paw(draw, body_center[0] + 57 * scale, paw_y - 18 * scale, scale, lifted=True)
        for offset in (0, 16, 32):
            draw.arc(ellipse_box(body_center[0] - 102 * scale - offset * scale, paw_y - 10 * scale, 32 * scale, 46 * scale), 270, 80, fill=COLORS["hurry"], width=line_width(scale))
    else:
        draw_paw(draw, body_center[0] - 58 * scale, paw_y + 4 * scale, scale)
        draw_paw(draw, body_center[0] + 58 * scale, paw_y + 4 * scale, scale)


def make_sheet(contract: dict[str, Any]) -> Image.Image:
    canvas = Image.new("RGBA", CANVAS_SIZE, COLORS["board"])
    draw = ImageDraw.Draw(canvas)
    draw.rectangle((46, 42, 1554, 954), outline=COLORS["board_line"], width=2)
    draw.line((74, 148, 1524, 148), fill=COLORS["board_line"], width=1)
    draw_text(draw, (74, 74), "PIPI LABU", 42, COLORS["paper"], bold=True)
    draw_text(draw, (77, 118), "BABY CUSTOMER CAST / V1", 15, COLORS["paper_soft"], bold=True)
    draw_text(draw, (1524, 82), "ART-002", 18, COLORS["honeygold"], bold=True, anchor="ra")
    draw_text(draw, (1524, 112), "REVIEW CANDIDATE", 13, COLORS["paper_soft"], anchor="ra")

    draw_text(draw, (78, 202), "SHARED BASE", 18, COLORS["honeygold"], bold=True)
    draw_text(draw, (78, 228), "one circular crown / one material language / four queue roles", 15, COLORS["paper"], bold=False)
    draw_customer(canvas, (280, 370), 1.12, "SharedBase")
    draw.line((100, 630, 458, 630), fill=COLORS["board_line"], width=1)
    draw_text(draw, (100, 662), "CARAMEL CROWN", 12, COLORS["paper_soft"], bold=True)
    draw_text(draw, (100, 686), "CREAM URAJIRO", 12, COLORS["paper_soft"], bold=True)
    draw_text(draw, (100, 710), "LOW OVAL EYES / TINY PAWS", 12, COLORS["paper_soft"], bold=True)
    draw_text(draw, (100, 756), "EAR RULE", 12, COLORS["honeygold"], bold=True)
    draw_text(draw, (100, 779), "lateral hints swallowed by contour", 13, COLORS["paper"], bold=False)

    # An authored diagonal of studies keeps the board from reading as a generic equal-card grid.
    role_centers = {
        "RubySprout": (675, 420),
        "HoneygoldHugger": (920, 390),
        "ShyLoaf": (1168, 452),
        "HurryWaddle": (1410, 386),
    }
    role_colors = {"RubySprout": "ruby", "HoneygoldHugger": "honeygold", "ShyLoaf": "shy", "HurryWaddle": "hurry"}
    label_x_by_role = {"RubySprout": 545, "HoneygoldHugger": 790, "ShyLoaf": 1035, "HurryWaddle": 1280}
    for role in contract["roles"]:
        role_id = role["id"]
        draw_customer(canvas, role_centers[role_id], 0.76, role_id, role)
        label_x, label_y = label_x_by_role[role_id], 730
        draw.ellipse((label_x, label_y, label_x + 16, label_y + 16), fill=COLORS[role_colors[role_id]])
        draw_text(draw, (label_x + 26, label_y - 3), role["display_name"].upper(), 15, COLORS["paper"], bold=True)
        draw_text(draw, (label_x + 26, label_y + 22), role["primary_emotion"], 13, COLORS["paper_soft"])
        draw_wrapped_text(draw, (label_x, label_y + 54), role["queue_read"], 11, COLORS["paper_soft"], width=29, line_gap=3)

    draw.line((530, 828, 1518, 828), fill=COLORS["board_line"], width=1)
    draw_text(draw, (530, 850), "REVIEW QUESTION", 12, COLORS["honeygold"], bold=True)
    draw_text(draw, (530, 875), "Can four babies feel different in the line without becoming four unrelated mascots?", 15, COLORS["paper"], bold=True)
    draw_text(draw, (530, 903), "The apple contact and received hold remain the sensory center.", 13, COLORS["paper_soft"])
    draw_text(draw, (78, 924), "NO TOP EARS  ·  NO PLAYER REPLACEMENT  ·  NO GAMEPLAY INTEGRATION  ·  NO HUMAN APPROVAL CLAIMED", 12, COLORS["paper_soft"], bold=True)
    return canvas.convert("RGB")


def main() -> None:
    args = parse_args()
    candidate_dir = Path(args.candidate_dir).resolve()
    contract = json.loads((candidate_dir / "baby_customer_cast_contract.json").read_text(encoding="utf-8"))
    image = make_sheet(contract)
    image_path = candidate_dir / contract["review_artifact"]["file"]
    image.save(image_path, format="PNG", optimize=False, compress_level=9)
    digest = hashlib.sha256(image_path.read_bytes()).hexdigest()
    report = {
        "generator_version": SCRIPT_VERSION,
        "candidate_id": contract["candidate_id"],
        "file": image_path.name,
        "width": image.width,
        "height": image.height,
        "sha256": digest,
        "role_ids": [role["id"] for role in contract["roles"]],
        "source_pixels": "procedural Pillow drawing only",
        "studio_imported": False,
        "human_approved": False,
    }
    (candidate_dir / "generation_report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print("PIPILABU_BABY_CAST_GENERATED " + json.dumps(report, sort_keys=True))


if __name__ == "__main__":
    main()
