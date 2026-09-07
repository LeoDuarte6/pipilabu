from __future__ import annotations

import argparse
import json
import time
import types
from pathlib import Path

import torch
from PIL import Image

from hy3dgen.rembg import BackgroundRemover
from hy3dgen.shapegen import Hunyuan3DDiTFlowMatchingPipeline


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run a private, unapproved Hunyuan3D-2mv geometry control for Pipi Labu."
    )
    parser.add_argument("--sheet", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--seed", type=int, default=29081997)
    parser.add_argument("--steps", type=int, default=40)
    parser.add_argument("--octree-resolution", type=int, default=320)
    return parser.parse_args()


def crop_views(sheet_path: Path, output_dir: Path) -> dict[str, Image.Image]:
    sheet = Image.open(sheet_path).convert("RGB")
    width, height = sheet.size
    if width / height < 1.8:
        raise ValueError(f"Expected a horizontal four-view sheet, got {width}x{height}.")

    crop_dir = output_dir / "inputs"
    crop_dir.mkdir(parents=True, exist_ok=True)
    names = ("front", "left", "back", "right")
    images: dict[str, Image.Image] = {}
    remover = BackgroundRemover()

    for index, name in enumerate(names):
        left = round(width * index / 4)
        right = round(width * (index + 1) / 4)
        panel = sheet.crop((left, 0, right, height))
        panel_path = crop_dir / f"{name}.png"
        panel.save(panel_path)
        images[name] = remover(panel.convert("RGBA"))

    return images


def main() -> None:
    args = parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    images = crop_views(args.sheet, args.output_dir)

    pipeline = Hunyuan3DDiTFlowMatchingPipeline.from_pretrained(
        "tencent/Hunyuan3D-2mv",
        subfolder="hunyuan3d-dit-v2-mv",
        variant="fp16",
    )
    # The documented shape-only model fits in 6 GB VRAM. Do not call the
    # repository's optional Diffusers CPU-offload shim here: current Windows
    # builds expose no `components` map on this custom pipeline.

    latent_path = args.output_dir / "final-latent.pt"
    progress_path = args.output_dir / "progress.jsonl"
    original_export = pipeline._export

    def export_with_manual_offload(self, latents, *export_args, **export_kwargs):
        # Preserve the expensive diffusion result before mesh extraction. If the
        # VAE/surface stage fails, the latent can be decoded without resampling.
        torch.save(latents.detach().to("cpu"), latent_path)
        self.model.to("cpu")
        self.conditioner.to("cpu")
        torch.cuda.empty_cache()
        return original_export(latents, *export_args, **export_kwargs)

    pipeline._export = types.MethodType(export_with_manual_offload, pipeline)

    def record_progress(step: int, timestep: torch.Tensor, _outputs) -> None:
        with progress_path.open("a", encoding="utf-8") as progress_file:
            progress_file.write(
                json.dumps(
                    {
                        "step": int(step) + 1,
                        "total": args.steps,
                        "timestep": float(timestep.detach().cpu().item()),
                        "time": time.time(),
                    }
                )
                + "\n"
            )

    progress_path.write_text("", encoding="utf-8")

    started = time.time()
    mesh = pipeline(
        image=images,
        num_inference_steps=args.steps,
        octree_resolution=args.octree_resolution,
        num_chunks=20000,
        generator=torch.manual_seed(args.seed),
        output_type="trimesh",
        callback=record_progress,
        callback_steps=1,
    )[0]
    elapsed = time.time() - started

    mesh_path = args.output_dir / "pipi-labu-owner-hunyuan2mv-unapproved.glb"
    mesh.export(mesh_path)
    metadata = {
        "approved": False,
        "allowedForGameplay": False,
        "allowedForStudioImport": False,
        "licenseWarning": "Private evaluation only. Tencent Hunyuan license territory restrictions are not compatible with an assumed global Roblox release.",
        "sheet": str(args.sheet.resolve()),
        "seed": args.seed,
        "steps": args.steps,
        "octreeResolution": args.octree_resolution,
        "elapsedSeconds": elapsed,
        "vertices": int(len(mesh.vertices)),
        "faces": int(len(mesh.faces)),
        "watertight": bool(mesh.is_watertight),
        "mesh": str(mesh_path.resolve()),
    }
    (args.output_dir / "metadata.json").write_text(
        json.dumps(metadata, indent=2), encoding="utf-8"
    )
    print(json.dumps(metadata, indent=2))


if __name__ == "__main__":
    main()
