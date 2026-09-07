#!/usr/bin/env python3
"""Prepare an approved Pipi Labu character turnaround for Meshy input."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image


PRESETS = {
    "v11": {
        "size": (1536, 1024),
        "prefix": "pipi_labu_owner_v11",
        "crops": {
            "front": (0, 260, 379, 775),
            "profile_left": (383, 260, 760, 775),
            "rear": (764, 260, 1140, 775),
            "three_quarter": (1145, 260, 1536, 775),
        },
    },
    "liked_furry": {
        "size": (1858, 846),
        "prefix": "pipi_labu_owner_liked_furry",
        "crops": {
            "front": (0, 45, 455, 790),
            "profile_left": (470, 45, 915, 790),
            "rear": (930, 45, 1380, 790),
            "profile_right": (1400, 45, 1858, 790),
        },
    },
    "rig_ready_v12": {
        "size": (1859, 846),
        "prefix": "pipi_labu_owner_rig_ready_v12",
        "crops": {
            "front": (0, 45, 465, 790),
            "profile_left": (465, 45, 930, 790),
            "rear": (930, 45, 1395, 790),
            "profile_right": (1395, 45, 1859, 790),
        },
    },
    "owner_frog_v13": {
        "size": (1857, 847),
        "prefix": "pipi_labu_owner_frog_v13",
        "crops": {
            "front": (0, 45, 455, 790),
            "profile_left": (470, 45, 915, 790),
            "rear": (930, 45, 1378, 790),
            "profile_right": (1400, 45, 1857, 790),
        },
    },
    "customer_frog_v13": {
        "size": (1858, 846),
        "prefix": "pipi_labu_customer_frog_v13",
        "crops": {
            "front": (0, 45, 455, 790),
            "profile_left": (470, 45, 915, 790),
            "rear": (930, 45, 1380, 790),
            "profile_right": (1400, 45, 1858, 790),
        },
    },
    "owner_canine_v14": {
        "size": (1755, 896),
        "prefix": "pipi_labu_owner_canine_v14",
        "crops": {
            "front": (0, 120, 430, 850),
            "profile_left": (430, 120, 875, 850),
            "rear": (875, 120, 1310, 850),
            "profile_right": (1310, 120, 1755, 850),
        },
    },
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--preset",
        choices=sorted(PRESETS),
        default="v11",
    )
    parser.add_argument(
        "--source",
        type=Path,
        default=Path("assets/concepts/pipi-labu-owner-reconstruction-sheet-v11.png"),
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("assets/candidates/pipi_labu_owner_meshy_v11_inputs"),
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    source = args.source.resolve()
    output_dir = args.output_dir.resolve()
    preset = PRESETS[args.preset]
    output_dir.mkdir(parents=True, exist_ok=True)

    with Image.open(source) as source_image:
        image = source_image.convert("RGB")
        expected_size = preset["size"]
        if image.size != expected_size:
            raise ValueError(
                f"Expected {args.preset} sheet at {expected_size}, got {image.size}"
            )

        outputs: list[dict[str, object]] = []
        for name, crop_box in preset["crops"].items():
            crop = image.crop(crop_box)
            output_width = 1024
            output_height = round(crop.height * output_width / crop.width)
            prepared = crop.resize(
                (output_width, output_height), Image.Resampling.LANCZOS
            )

            output = output_dir / f"{preset['prefix']}_{name}.png"
            prepared.save(output, format="PNG", optimize=True)
            outputs.append(
                {
                    "view": name,
                    "crop_box": crop_box,
                    "output": output.name,
                    "dimensions": [output_width, output_height],
                    "sha256": sha256(output),
                }
            )

    manifest = {
        "contract": "PIPI_LABU_MESHY_CHARACTER_INPUTS_V3",
        "preset": args.preset,
        "source": str(source),
        "source_sha256": sha256(source),
        "rights": "Original project-authored concept; no marketplace mesh or reel frame included.",
        "views": outputs,
    }
    (output_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )
    print(f"PIPI_LABU_MESHY_INPUTS_OK views={len(outputs)} dir={output_dir}")


if __name__ == "__main__":
    main()
