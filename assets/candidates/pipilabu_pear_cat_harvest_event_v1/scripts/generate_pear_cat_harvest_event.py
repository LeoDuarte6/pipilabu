"""Generate the deterministic ART-006 pear-cat harvest-event review artifacts.

This is an authored concept/mechanic study. It does not read or bake pixels
from the local Pipi Labu models, references, Studio, or gameplay source.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont


SCRIPT_VERSION = "1.0.0"
SHEET_SIZE = (1800, 1120)
MOBILE_SIZE = (960, 420)

COLORS = {
    "ink": "#2F3028",
    "ink_soft": "#596055",
    "board": "#46534A",
    "board_deep": "#324138",
    "board_line": "#899487",
    "paper": "#F3E7CF",
    "paper_soft": "#E4D1AC",
    "paper_deep": "#C8B082",
    "cat_base": "#C99658",
    "cat_light": "#E2B66F",
    "cat_shadow": "#94613D",
    "cat_deep": "#674334",
    "cat_ear_inner": "#B87557",
    "cat_blush": "#D88D6C",
    "hand": "#DDA477",
    "hand_shadow": "#A9684A",
    "leaf_shadow": "#5D764D",
    "leaf": "#708A55",
    "stem": "#76553A",
    "plum": "#403447",
    "eye_glint": "#FFF5D8",
    "ruby": "#C7483E",
    "ruby_dark": "#8F302F",
    "gold": "#E3A747",
    "bark": "#75553C",
    "basket": "#B57945",
    "basket_dark": "#70462F",
    "cream": "#F8EDCF",
    "white": "#FFF9EB",
    "olive": "#A6B38D",
    "red_line": "#D36A52",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate-dir", required=True)
    return parser.parse_args()


def load_font(size: int, bold: bool = False) -> tuple[ImageFont.ImageFont, str]:
    candidates = [
        Path("C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf"),
        Path("C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf"),
    ]
    for candidate in candidates:
        if candidate.is_file():
            return ImageFont.truetype(str(candidate), size), candidate.as_posix()
    return ImageFont.load_default(), "Pillow default bitmap font"


def draw_text(
    draw: ImageDraw.ImageDraw,
    xy: tuple[float, float],
    text: str,
    size: int,
    fill: str,
    *,
    bold: bool = False,
    anchor: str | None = None,
) -> str:
    font, font_path = load_font(size, bold)
    draw.text(xy, text, font=font, fill=fill, anchor=anchor)
    return font_path


def text_width(text: str, size: int, bold: bool = False) -> int:
    font, _ = load_font(size, bold)
    return int(font.getlength(text))


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def stable_json_write(path: Path, payload: Any) -> None:
    with path.open("w", encoding="utf-8", newline="\n") as handle:
        json.dump(payload, handle, indent=2, sort_keys=True)
        handle.write("\n")


def read_contract(candidate_dir: Path) -> dict[str, Any]:
    contract_path = candidate_dir / "pear_cat_harvest_event_contract.json"
    with contract_path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def ellipse_box(cx: float, cy: float, width: float, height: float) -> tuple[float, float, float, float]:
    return (cx - width / 2, cy - height / 2, cx + width / 2, cy + height / 2)


def rounded_box(cx: float, cy: float, width: float, height: float) -> tuple[float, float, float, float]:
    return (cx - width / 2, cy - height / 2, cx + width / 2, cy + height / 2)


def arrow(draw: ImageDraw.ImageDraw, start: tuple[float, float], end: tuple[float, float], fill: str, width: int = 5) -> None:
    draw.line([start, end], fill=fill, width=width)
    angle = math.atan2(end[1] - start[1], end[0] - start[0])
    head = 16
    left = (end[0] - head * math.cos(angle - math.pi / 6), end[1] - head * math.sin(angle - math.pi / 6))
    right = (end[0] - head * math.cos(angle + math.pi / 6), end[1] - head * math.sin(angle + math.pi / 6))
    draw.polygon([end, left, right], fill=fill)


def draw_leaf(draw: ImageDraw.ImageDraw, cx: float, cy: float, scale: float, fill: str = COLORS["leaf"]) -> None:
    points = [
        (cx, cy),
        (cx + 30 * scale, cy - 18 * scale),
        (cx + 58 * scale, cy - 12 * scale),
        (cx + 34 * scale, cy + 7 * scale),
    ]
    draw.polygon(points, fill=fill)
    draw.line([(cx + 4 * scale, cy - 1 * scale), (cx + 47 * scale, cy - 9 * scale)], fill=COLORS["leaf"], width=max(1, int(2 * scale)))


def draw_apple(draw: ImageDraw.ImageDraw, cx: float, cy: float, scale: float, *, fill: str = COLORS["ruby"]) -> None:
    radius = 23 * scale
    draw.ellipse(ellipse_box(cx, cy + 4 * scale, radius * 2, radius * 1.75), fill=fill, outline=COLORS["ruby_dark"], width=max(1, int(2 * scale)))
    draw.ellipse(ellipse_box(cx - 9 * scale, cy - 5 * scale, radius * 0.55, radius * 0.42), fill="#E4775A")
    draw.line([(cx, cy - 17 * scale), (cx + 2 * scale, cy - 34 * scale)], fill=COLORS["stem"], width=max(1, int(3 * scale)))
    draw_leaf(draw, cx + 1 * scale, cy - 28 * scale, 0.42 * scale, fill=COLORS["leaf"])


def draw_basket(draw: ImageDraw.ImageDraw, cx: float, cy: float, scale: float, *, small: bool = False) -> None:
    width = 160 * scale
    height = 76 * scale
    draw.rounded_rectangle(rounded_box(cx, cy, width, height), radius=max(3, int(14 * scale)), fill=COLORS["basket"], outline=COLORS["basket_dark"], width=max(1, int(4 * scale)))
    draw.arc(rounded_box(cx, cy - 20 * scale, width * 0.78, 90 * scale), 180, 360, fill=COLORS["basket_dark"], width=max(1, int(5 * scale)))
    for offset in (-0.28, 0, 0.28):
        x = cx + width * offset
        draw.line([(x, cy - height * 0.38), (x - 5 * scale, cy + height * 0.38)], fill=COLORS["basket_dark"], width=max(1, int(3 * scale)))
    draw_apple(draw, cx - width * 0.2, cy - height * 0.25, 0.55 * scale)
    draw_apple(draw, cx + width * 0.16, cy - height * 0.21, 0.48 * scale, fill=COLORS["gold"])
    if not small:
        draw_text(draw, (cx, cy + height * 0.76), "BASKET / CONTEXT", 16, COLORS["ink_soft"], bold=True, anchor="mm")


def draw_tree(draw: ImageDraw.ImageDraw, cx: float, cy: float, scale: float) -> None:
    trunk_width = 82 * scale
    trunk_height = 300 * scale
    draw.rounded_rectangle(rounded_box(cx, cy + trunk_height * 0.24, trunk_width, trunk_height), radius=max(3, int(18 * scale)), fill=COLORS["bark"])
    draw.line([(cx, cy + trunk_height * 0.34), (cx - 120 * scale, cy - 42 * scale)], fill=COLORS["bark"], width=max(2, int(16 * scale)))
    draw.line([(cx + 8 * scale, cy + trunk_height * 0.2), (cx + 118 * scale, cy - 28 * scale)], fill=COLORS["bark"], width=max(2, int(14 * scale)))
    canopy = [
        (cx - 122 * scale, cy - 28 * scale, 238 * scale, 168 * scale),
        (cx + 14 * scale, cy - 70 * scale, 250 * scale, 194 * scale),
        (cx + 132 * scale, cy - 20 * scale, 190 * scale, 160 * scale),
        (cx - 16 * scale, cy + 14 * scale, 270 * scale, 155 * scale),
    ]
    for index, (leaf_cx, leaf_cy, width, height) in enumerate(canopy):
        fill = COLORS["leaf_shadow"] if index % 2 else COLORS["leaf"]
        draw.ellipse(ellipse_box(leaf_cx, leaf_cy, width, height), fill=fill)
    for offset in (-88, 12, 100):
        draw_apple(draw, cx + offset * scale, cy - 78 * scale, 0.52 * scale, fill=COLORS["gold"] if offset == 12 else COLORS["ruby"])


def round_cat_body_points(cx: float, cy: float, width: float, height: float) -> list[tuple[float, float]]:
    points: list[tuple[float, float]] = []
    for index in range(41):
        t = index / 40
        y = cy - height * 0.52 + height * 1.04 * t
        sphere = math.sin(math.pi * t) ** 0.52
        half = width * 0.5 * (0.15 + 0.85 * sphere) * (0.98 + 0.02 * t)
        points.append((cx - half, y))
    for index in range(40, -1, -1):
        t = index / 40
        y = cy - height * 0.52 + height * 1.04 * t
        sphere = math.sin(math.pi * t) ** 0.52
        half = width * 0.5 * (0.15 + 0.85 * sphere) * (0.98 + 0.02 * t)
        points.append((cx + half, y))
    return points


def draw_orchard_cat(
    draw: ImageDraw.ImageDraw,
    cx: float,
    cy: float,
    scale: float,
    state: str,
    *,
    shadow: bool = True,
    show_apple: bool = False,
    show_basket: bool = False,
) -> None:
    width = 220 * scale
    height = (195 if state == "HAND_SQUASH" else 215) * scale
    if shadow:
        draw.ellipse(ellipse_box(cx, cy + height * 0.56, width * 0.94, height * 0.18), fill="#27372D")

    if state == "TREE_HANG":
        draw.line([(cx - width * 0.70, cy + height * 0.35), (cx + width * 0.70, cy + height * 0.35)], fill=COLORS["bark"], width=max(2, int(12 * scale)))
        draw.line([(cx - width * 0.36, cy + height * 0.35), (cx - width * 0.52, cy + height * 0.05)], fill=COLORS["bark"], width=max(1, int(6 * scale)))
        draw_apple(draw, cx - width * 0.56, cy + height * 0.02, 0.38 * scale, fill=COLORS["gold"])
        draw_apple(draw, cx + width * 0.58, cy + height * 0.04, 0.34 * scale, fill=COLORS["ruby"])
    elif state == "BASKET_CLUSTER":
        draw_basket(draw, cx, cy + height * 0.43, 0.68 * scale, small=True)
        draw_apple(draw, cx - width * 0.64, cy + height * 0.28, 0.38 * scale, fill=COLORS["ruby"])
        draw_apple(draw, cx + width * 0.64, cy + height * 0.28, 0.36 * scale, fill=COLORS["gold"])

    # The ears are intentionally lateral, folded, and almost swallowed by the
    # round fur silhouette. There is no crown stem, leaf, or upright ear.
    ear_y = cy - height * 0.23
    ear_width = width * 0.13
    ear_height = height * 0.09
    draw.ellipse(ellipse_box(cx - width * 0.48, ear_y, ear_width, ear_height), fill=COLORS["cat_deep"], outline=COLORS["cat_shadow"], width=max(1, int(3 * scale)))
    draw.ellipse(ellipse_box(cx + width * 0.48, ear_y, ear_width, ear_height), fill=COLORS["cat_deep"], outline=COLORS["cat_shadow"], width=max(1, int(3 * scale)))
    draw.ellipse(ellipse_box(cx - width * 0.48, ear_y, ear_width * 0.42, ear_height * 0.40), fill=COLORS["cat_ear_inner"])
    draw.ellipse(ellipse_box(cx + width * 0.48, ear_y, ear_width * 0.42, ear_height * 0.40), fill=COLORS["cat_ear_inner"])

    body = round_cat_body_points(cx, cy, width, height)
    draw.polygon(body, fill=COLORS["cat_base"], outline=COLORS["cat_deep"])
    draw.line(body + [body[0]], fill=COLORS["cat_deep"], width=max(1, int(3 * scale)), joint="curve")

    # A honey forehead highlight and toasted lower shadow describe a hand-
    # squashed fur loaf without turning the body into literal fruit anatomy.
    draw.ellipse(ellipse_box(cx, cy - height * 0.27, width * 0.78, height * 0.24), fill=COLORS["cat_light"])
    draw.ellipse(ellipse_box(cx, cy + height * 0.28, width * 0.77, height * 0.28), fill=COLORS["cat_shadow"])
    draw.ellipse(ellipse_box(cx - width * 0.27, cy + height * 0.04, width * 0.09, height * 0.06), fill=COLORS["cat_blush"])
    draw.ellipse(ellipse_box(cx + width * 0.27, cy + height * 0.04, width * 0.09, height * 0.06), fill=COLORS["cat_blush"])

    # Narrow almond eyes, vertical pupils, and catchlights establish feline
    # identity while staying readable at the mobile review scale.
    eye_y = cy - height * 0.10
    eye_width = width * (0.22 if state == "HARVEST_PEEK" else 0.20)
    eye_height = height * 0.13
    for eye_x in (cx - width * 0.19, cx + width * 0.19):
        if state == "BASKET_GOODBYE":
            draw.arc(ellipse_box(eye_x, eye_y, eye_width, eye_height * 0.82), 20, 160, fill=COLORS["cat_deep"], width=max(1, int(4 * scale)))
        else:
            almond = [
                (eye_x - eye_width * 0.50, eye_y),
                (eye_x - eye_width * 0.13, eye_y - eye_height * 0.50),
                (eye_x + eye_width * 0.50, eye_y),
                (eye_x + eye_width * 0.13, eye_y + eye_height * 0.50),
            ]
            draw.polygon(almond, fill=COLORS["cat_deep"])
            draw.line([(eye_x, eye_y - eye_height * 0.25), (eye_x, eye_y + eye_height * 0.25)], fill=COLORS["ink"], width=max(1, int(3 * scale)))
            draw.ellipse(ellipse_box(eye_x - eye_width * 0.20, eye_y - eye_height * 0.20, eye_width * 0.22, eye_height * 0.26), fill=COLORS["eye_glint"])

    if state == "ORCHARD_REST":
        draw.line([(cx - width * 0.28, eye_y - height * 0.10), (cx - width * 0.10, eye_y - height * 0.13)], fill=COLORS["cat_deep"], width=max(1, int(3 * scale)))
        draw.line([(cx + width * 0.10, eye_y - height * 0.13), (cx + width * 0.28, eye_y - height * 0.10)], fill=COLORS["cat_deep"], width=max(1, int(3 * scale)))

    nose_y = cy + height * 0.045
    draw.polygon([(cx, nose_y + 7 * scale), (cx - 7 * scale, nose_y - 3 * scale), (cx + 7 * scale, nose_y - 3 * scale)], fill=COLORS["cat_deep"])
    mouth_y = cy + height * 0.13
    mouth_box = rounded_box(cx, mouth_y, width * 0.16, height * 0.11)
    if state == "RECEIPT_DELIGHT":
        draw.ellipse(mouth_box, fill=COLORS["cat_deep"])
        inner = rounded_box(cx, mouth_y + height * 0.026, width * 0.08, height * 0.038)
        draw.ellipse(inner, fill=COLORS["ruby"])
    elif state == "BASKET_CLUSTER":
        draw.arc(mouth_box, 15, 165, fill=COLORS["cat_deep"], width=max(1, int(3 * scale)))
    elif state == "TREE_HANG":
        draw.line([(cx, nose_y + 5 * scale), (cx, mouth_y - 5 * scale)], fill=COLORS["cat_deep"], width=max(1, int(2 * scale)))
        draw.arc(mouth_box, 200, 340, fill=COLORS["cat_deep"], width=max(1, int(3 * scale)))
    else:
        draw.line([(cx, nose_y + 5 * scale), (cx, mouth_y - 5 * scale)], fill=COLORS["cat_deep"], width=max(1, int(2 * scale)))
        draw.arc(mouth_box, 15, 165, fill=COLORS["cat_deep"], width=max(1, int(3 * scale)))

    # Whisker fans are intentionally short and quiet so they survive a
    # thumbnail without becoming line noise.
    for side in (-1, 1):
        start_x = cx + side * width * 0.055
        for offset in (-0.045, 0.0, 0.045):
            draw.line([(start_x, nose_y + offset * height), (cx + side * width * 0.34, nose_y + (offset + (0.02 if offset == 0 else 0.0)) * height)], fill=COLORS["cat_deep"], width=max(1, int(2 * scale)))

    if state == "HAND_SQUASH":
        hand_y = cy + height * 0.08
        for side in (-1, 1):
            draw.line([(cx + side * width * 0.78, hand_y - height * 0.17), (cx + side * width * 0.53, hand_y)], fill=COLORS["hand_shadow"], width=max(2, int(11 * scale)))
            draw.ellipse(ellipse_box(cx + side * width * 0.48, hand_y, width * 0.27, height * 0.25), fill=COLORS["hand"], outline=COLORS["hand_shadow"], width=max(1, int(3 * scale)))
            draw.arc(ellipse_box(cx + side * width * 0.49, hand_y - height * 0.03, width * 0.16, height * 0.15), 200 if side < 0 else 340, 340 if side < 0 else 520, fill=COLORS["hand_shadow"], width=max(1, int(2 * scale)))

    paw_fill = COLORS["cat_light"]
    paw_outline = COLORS["cat_deep"]
    if state == "HAND_SQUASH":
        draw.ellipse(ellipse_box(cx - width * 0.28, cy + height * 0.35, width * 0.22, height * 0.14), fill=paw_fill, outline=paw_outline, width=max(1, int(3 * scale)))
        draw.ellipse(ellipse_box(cx + width * 0.28, cy + height * 0.35, width * 0.22, height * 0.14), fill=paw_fill, outline=paw_outline, width=max(1, int(3 * scale)))
    elif state == "TREE_HANG":
        draw.ellipse(ellipse_box(cx - width * 0.28, cy + height * 0.29, width * 0.22, height * 0.14), fill=paw_fill, outline=paw_outline, width=max(1, int(3 * scale)))
        draw.ellipse(ellipse_box(cx + width * 0.28, cy + height * 0.29, width * 0.22, height * 0.14), fill=paw_fill, outline=paw_outline, width=max(1, int(3 * scale)))
    elif state == "BASKET_CLUSTER":
        draw.ellipse(ellipse_box(cx - width * 0.31, cy + height * 0.36, width * 0.22, height * 0.14), fill=paw_fill, outline=paw_outline, width=max(1, int(3 * scale)))
        draw.ellipse(ellipse_box(cx + width * 0.31, cy + height * 0.36, width * 0.22, height * 0.14), fill=paw_fill, outline=paw_outline, width=max(1, int(3 * scale)))
    elif state == "RECEIPT_DELIGHT":
        draw.line([(cx - width * 0.25, cy + height * 0.19), (cx - width * 0.28, cy + height * 0.34)], fill=paw_outline, width=max(2, int(9 * scale)))
        draw.line([(cx + width * 0.25, cy + height * 0.19), (cx + width * 0.28, cy + height * 0.34)], fill=paw_outline, width=max(2, int(9 * scale)))
        draw.ellipse(ellipse_box(cx - width * 0.29, cy + height * 0.35, width * 0.23, height * 0.15), fill=paw_fill, outline=paw_outline, width=max(1, int(3 * scale)))
        draw.ellipse(ellipse_box(cx + width * 0.29, cy + height * 0.35, width * 0.23, height * 0.15), fill=paw_fill, outline=paw_outline, width=max(1, int(3 * scale)))
        draw_apple(draw, cx, cy + height * 0.32, 0.58 * scale)
    else:
        draw.ellipse(ellipse_box(cx - width * 0.28, cy + height * 0.35, width * 0.23, height * 0.15), fill=paw_fill, outline=paw_outline, width=max(1, int(3 * scale)))
        draw.ellipse(ellipse_box(cx + width * 0.28, cy + height * 0.35, width * 0.23, height * 0.15), fill=paw_fill, outline=paw_outline, width=max(1, int(3 * scale)))

    if show_apple and state != "RECEIPT_DELIGHT":
        draw_apple(draw, cx + width * 0.65, cy + height * 0.22, 0.42 * scale)
    if show_basket:
        draw_basket(draw, cx + width * 0.96, cy + height * 0.53, 0.72 * scale)


def draw_callout(draw: ImageDraw.ImageDraw, start: tuple[float, float], end: tuple[float, float], title: str, detail: str, align: str = "left") -> None:
    draw.line([start, end], fill=COLORS["paper_deep"], width=3)
    draw.ellipse(ellipse_box(start[0], start[1], 12, 12), fill=COLORS["gold"])
    if align == "right":
        anchor = "ra"
        x = end[0] - 8
    else:
        anchor = "la"
        x = end[0] + 8
    draw_text(draw, (x, end[1] - 22), title, 20, COLORS["paper"], bold=True, anchor=anchor)
    draw_text(draw, (x, end[1] + 4), detail, 16, COLORS["paper_soft"], anchor=anchor)


def draw_sheet(contract: dict[str, Any]) -> tuple[Image.Image, set[str]]:
    image = Image.new("RGB", SHEET_SIZE, COLORS["board"])
    draw = ImageDraw.Draw(image)
    fonts: set[str] = set()

    draw.rectangle((0, 0, SHEET_SIZE[0], 150), fill=COLORS["board_deep"])
    draw.line([(80, 150), (1720, 150)], fill=COLORS["board_line"], width=2)
    fonts.add(draw_text(draw, (82, 44), "ART-006  /  PIPI LABU", 22, COLORS["gold"], bold=True))
    fonts.add(draw_text(draw, (82, 76), "PEAR-CAT HARVEST EVENT STUDY", 42, COLORS["paper"], bold=True))
    fonts.add(draw_text(draw, (83, 124), "rare orchard encounter  /  same reach-carry-serve language  /  local review candidate", 17, COLORS["paper_soft"]))
    fonts.add(draw_text(draw, (1718, 56), "REVIEW ONLY", 20, COLORS["gold"], bold=True, anchor="ra"))
    fonts.add(draw_text(draw, (1718, 90), "HUMAN APPROVED: NO", 16, COLORS["paper_soft"], anchor="ra"))
    fonts.add(draw_text(draw, (1718, 116), "STUDIO IMPORTED: NO", 16, COLORS["paper_soft"], anchor="ra"))

    # Left side: an orchard vignette with the hero silhouette, not a generic card.
    draw.rounded_rectangle((70, 205, 785, 1010), radius=24, fill=COLORS["board_deep"], outline=COLORS["board_line"], width=2)
    fonts.add(draw_text(draw, (105, 240), "IDENTITY / ORCHARD CUSTOMER", 20, COLORS["gold"], bold=True))
    fonts.add(draw_text(draw, (105, 275), "golden cat-loaf, distinct from the dog cast", 18, COLORS["paper_soft"]))
    draw_tree(draw, 320, 525, 1.32)
    draw_basket(draw, 670, 800, 0.92, small=True)
    draw_orchard_cat(draw, 360, 660, 1.34, "TREE_HANG", show_basket=False, show_apple=False)
    fonts.add(draw_text(draw, (485, 930), "TREE_HANG", 22, COLORS["paper"], bold=True, anchor="ma"))
    fonts.add(draw_text(draw, (485, 962), "resting / watchful  -  branch and apples are context", 17, COLORS["paper_soft"], anchor="ma"))
    draw_callout(draw, (205, 520), (110, 450), "SIDE-FOLDED EAR", "nearly disappears into fur")
    draw_callout(draw, (445, 490), (610, 400), "CAT CROWN", "round loaf, no stem / leaf")
    draw_callout(draw, (455, 635), (640, 575), "FELINE EYES", "narrow almond / catchlights", align="right")
    draw_callout(draw, (515, 777), (720, 895), "HEAVY SQUASH", "broad lower mass", align="right")

    # A compact mobile proof inset inside the vignette.
    draw.rounded_rectangle((100, 840, 355, 1000), radius=16, fill=COLORS["paper"], outline=COLORS["paper_deep"], width=2)
    fonts.add(draw_text(draw, (122, 848), "GAMEPLAY THUMBNAIL", 14, COLORS["ink"], bold=True))
    draw_orchard_cat(draw, 190, 916, 0.34, "RECEIPT_DELIGHT", shadow=False)
    draw_apple(draw, 285, 925, 0.5)
    fonts.add(draw_text(draw, (272, 870), "2.35 stud cat body", 14, COLORS["ink_soft"], anchor="ma"))
    fonts.add(draw_text(draw, (272, 956), "body first / receipt stays visible", 13, COLORS["ink_soft"], anchor="ma"))

    # Right side: a diagonal event path keeps the four states connected.
    fonts.add(draw_text(draw, (870, 220), "HARVEST BEAT / FOUR READABLE STATES", 20, COLORS["gold"], bold=True))
    fonts.add(draw_text(draw, (870, 253), "contact is the sensory peak; no new sourcing or economy rules", 17, COLORS["paper_soft"]))
    path_points = [(975, 438), (1192, 636), (1410, 438), (1624, 636)]
    for start, end in zip(path_points, path_points[1:]):
        arrow(draw, start, end, COLORS["paper_deep"], width=4)
    states = [
        ("TREE_HANG", "resting / watchful", path_points[0], 0.63, COLORS["leaf"]),
        ("HAND_SQUASH", "held / surprised", path_points[1], 0.63, COLORS["gold"]),
        ("BASKET_CLUSTER", "clustered / cozy", path_points[2], 0.63, COLORS["cat_light"]),
        ("RECEIPT_DELIGHT", "delight / receives", path_points[3], 0.72, COLORS["ruby"]),
    ]
    for state, emotion, (cx, cy), scale, accent in states:
        draw.ellipse(ellipse_box(cx, cy, 184, 184), fill=COLORS["board"], outline=accent, width=5)
        draw_orchard_cat(draw, cx, cy - 12, scale, state, shadow=False)
        fonts.add(draw_text(draw, (cx, cy + 118), state.replace("_", " "), 18 if state != "CONTACT_DELIGHT" else 19, COLORS["paper"], bold=True, anchor="ma"))
        fonts.add(draw_text(draw, (cx, cy + 146), emotion, 16, accent, bold=True, anchor="ma"))
    fonts.add(draw_text(draw, (870, 790), "SAME VERBS", 19, COLORS["gold"], bold=True))
    verbs = "REACH  ->  CARRY  ->  SERVE  ->  CONTACT  ->  HOLD / RECEIPT"
    fonts.add(draw_text(draw, (870, 824), verbs, 22, COLORS["paper"], bold=True))
    fonts.add(draw_text(draw, (870, 860), "The apple remains the legible receipt. The golden cat is the authored response, not a new system.", 17, COLORS["paper_soft"]))

    draw.rounded_rectangle((870, 910, 1725, 1010), radius=18, fill=COLORS["paper"], outline=COLORS["paper_deep"], width=2)
    fonts.add(draw_text(draw, (900, 935), "FAMILY BOUNDARY", 17, COLORS["ink"], bold=True))
    fonts.add(draw_text(draw, (900, 966), "distinct orchard encounter  /  not owner  /  not baby  /  not player", 19, COLORS["ink"], bold=True))
    fonts.add(draw_text(draw, (900, 992), "flat sheet = cast + pose decision surface; approved rendered v4 material quality stays the production bar", 14, COLORS["ink_soft"]))

    return image, fonts


def draw_mobile_strip(contract: dict[str, Any]) -> tuple[Image.Image, set[str]]:
    image = Image.new("RGB", MOBILE_SIZE, COLORS["paper"])
    draw = ImageDraw.Draw(image)
    fonts: set[str] = set()
    fonts.add(draw_text(draw, (24, 20), "ART-006 MOBILE READ STRIP", 22, COLORS["ink"], bold=True))
    fonts.add(draw_text(draw, (936, 24), "BODY FIRST / RECEIPT VISIBLE / NO TOP EARS", 14, COLORS["ink_soft"], bold=True, anchor="ra"))
    state_specs = [
        ("TREE_HANG", "RESTING / WATCHFUL", COLORS["leaf"]),
        ("HAND_SQUASH", "HELD / SURPRISED", COLORS["gold"]),
        ("BASKET_CLUSTER", "CLUSTERED / COZY", COLORS["cat_light"]),
        ("RECEIPT_DELIGHT", "DELIGHT / RECEIVES", COLORS["ruby"]),
    ]
    cell_width = 232
    start_y = 70
    for index, (state, emotion, accent) in enumerate(state_specs):
        left = index * cell_width
        if index:
            draw.line([(left, 65), (left, 390)], fill=COLORS["paper_deep"], width=2)
        draw.ellipse(ellipse_box(left + cell_width / 2, 172, 170, 170), fill="#E9D9B9", outline=accent, width=4)
        draw_orchard_cat(draw, left + cell_width / 2, 160, 0.58, state, shadow=False)
        fonts.add(draw_text(draw, (left + cell_width / 2, 274), state.replace("_", " "), 17 if state != "CONTACT_DELIGHT" else 15, COLORS["ink"], bold=True, anchor="ma"))
        fonts.add(draw_text(draw, (left + cell_width / 2, 302), emotion, 16, accent, bold=True, anchor="ma"))
        if state == "RECEIPT_DELIGHT":
            draw_apple(draw, left + cell_width / 2, 349, 0.5)
            fonts.add(draw_text(draw, (left + cell_width / 2, 392), "RUBY RECEIPT", 13, COLORS["ink_soft"], bold=True, anchor="ma"))
        else:
            context_label = {
                "TREE_HANG": "branch + apples + cat loaf",
                "HAND_SQUASH": "hands + compressed loaf",
                "BASKET_CLUSTER": "basket + gathered apples",
            }[state]
            fonts.add(draw_text(draw, (left + cell_width / 2, 366), context_label, 13, COLORS["ink_soft"], anchor="ma"))
    return image, fonts


def source_records(repo_root: Path, contract: dict[str, Any]) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for reference in contract["source"]["local_doctrine_refs"]:
        relative = reference["path"]
        path = repo_root / relative
        if not path.is_file():
            raise FileNotFoundError(f"Missing doctrine source: {relative}")
        records.append({
            "path": relative,
            "reason": reference["reason"],
            "bytes": path.stat().st_size,
            "sha256": sha256_file(path),
        })
    return records


def artifact_record(candidate_dir: Path, relative: str, dimensions: tuple[int, int] | None = None) -> dict[str, Any]:
    path = candidate_dir / relative
    record: dict[str, Any] = {
        "path": relative,
        "bytes": path.stat().st_size,
        "sha256": sha256_file(path),
    }
    if dimensions is not None:
        record["dimensions"] = list(dimensions)
        record["mode"] = "RGB"
    return record


def body_palette_audit(image: Image.Image) -> dict[str, Any]:
    crop_box = (200, 500, 520, 830)
    pixels = list(image.crop(crop_box).getdata())
    warm_pixels = sum(1 for red, green, blue in pixels if red > green * 1.08 and green > blue * 1.10 and red > 120)
    green_pixels = sum(1 for red, green, blue in pixels if green > red * 1.15 and green > blue * 1.05 and green > 85)
    return {
        "crop_box": list(crop_box),
        "warm_tan_or_golden_pixels": warm_pixels,
        "greenish_pixels": green_pixels,
        "green_dominant_body": green_pixels >= warm_pixels,
        "body_tone": "warm tan/golden",
        "fruit_context_only": True,
    }


def main() -> None:
    args = parse_args()
    candidate_dir = Path(args.candidate_dir).resolve()
    repo_root = candidate_dir.parents[2]
    contract = read_contract(candidate_dir)
    if contract["ticket"] != "ART-006":
        raise ValueError("Candidate contract is not ART-006")

    sheet, sheet_fonts = draw_sheet(contract)
    mobile, mobile_fonts = draw_mobile_strip(contract)
    sheet_path = candidate_dir / contract["artifacts"]["review_sheet"]
    mobile_path = candidate_dir / contract["artifacts"]["mobile_strip"]
    sheet.save(sheet_path, format="PNG", optimize=False, compress_level=9)
    mobile.save(mobile_path, format="PNG", optimize=False, compress_level=9)

    fallback_brief = contract["source"]["fallback_brief"]
    report = {
        "candidate_id": contract["candidate_id"],
        "ticket": "ART-006",
        "script_version": SCRIPT_VERSION,
        "contract": {
            "path": "pear_cat_harvest_event_contract.json",
            "bytes": (candidate_dir / "pear_cat_harvest_event_contract.json").stat().st_size,
            "sha256": sha256_file(candidate_dir / "pear_cat_harvest_event_contract.json"),
        },
        "render": {
            "review_sheet": {"dimensions": list(SHEET_SIZE), "mode": "RGB"},
            "mobile_strip": {"dimensions": list(MOBILE_SIZE), "mode": "RGB"},
            "font_paths": sorted({path.replace("\\", "/") for path in sheet_fonts | mobile_fonts}),
            "identity_palette_audit": body_palette_audit(sheet),
        },
        "source_scan": {
            "raw_attachment_status": contract["source"]["raw_attachment_status"],
            "raw_reference_matches": contract["source"]["raw_reference_matches"],
            "fallback_brief_used": contract["source"]["fallback_brief_used"],
            "fallback_brief": {
                "path": "<user-supplied ART-006 fallback brief>",
                "sha256": hashlib.sha256(fallback_brief.encode("utf-8")).hexdigest(),
                "characters": len(fallback_brief),
            },
            "local_doctrine_refs": source_records(repo_root, contract),
        },
        "approval": contract["approval"],
        "runtime_mutation": {
            "gameplay_luau_changed": False,
            "studio_changed": False,
            "rojo_changed": False,
            "canonical_assets_changed": False,
            "cloud_touched": False,
            "uploaded": False,
            "published": False,
        },
        "artifacts": [
            artifact_record(candidate_dir, contract["artifacts"]["review_sheet"], SHEET_SIZE),
            artifact_record(candidate_dir, contract["artifacts"]["mobile_strip"], MOBILE_SIZE),
        ],
    }
    stable_json_write(candidate_dir / contract["artifacts"]["generation_report"], report)
    print(f"PIPILABU_PEAR_CAT_GENERATED sheet={SHEET_SIZE[0]}x{SHEET_SIZE[1]} mobile={MOBILE_SIZE[0]}x{MOBILE_SIZE[1]}")


if __name__ == "__main__":
    main()
