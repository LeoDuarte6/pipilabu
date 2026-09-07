# Pipi Labu image-to-3D pipeline research

Date: 2026-08-09
Scope: a materially higher-fidelity replacement for the rejected procedural Blender v8 models, using the supplied Pipi Labu single-view and turnaround references, with editable Blender output and a private Roblox import target.

## Decision

Do not make another procedural ellipsoid character and do not treat a pleasant front render as proof of a usable model. The best-quality, license-clean route is:

1. Run **Microsoft TRELLIS.2-4B** on a Linux NVIDIA machine with at least 24 GB VRAM to produce several high-fidelity, fully textured PBR GLB candidates from the strongest isolated reference image. TRELLIS.2 is MIT-licensed, outputs a mesh with PBR materials, and is explicitly designed for high-fidelity image-to-3D generation. Its official limitation is single-image input, and raw meshes can contain small holes, so it is a candidate generator rather than the finished game asset. [Official model card](https://huggingface.co/microsoft/TRELLIS.2-4B), [official repository](https://github.com/microsoft/TRELLIS.2).
2. In parallel, use **Microsoft TRELLIS v1 multi-image** on a 16 GB+ Linux GPU for front/side/back consistency. Its official `run_multi_image()` path accepts separate views and exports a textured GLB, but Microsoft calls this tuning-free multi-image mode experimental and warns that inconsistent poses/details can degrade results. [Official multi-image example](https://github.com/microsoft/TRELLIS/blob/main/example_multi_image.py), [official app warning and GLB exporter](https://github.com/microsoft/TRELLIS/blob/main/app.py).
3. Bring the best outputs into Blender. Preserve the best generated surface as a sculpt/reference, then perform deliberate topology cleanup, silhouette correction, UV/PBR bake, rigging, and Roblox-budget reduction. The generation model must not own ear placement, facial expression, paws, or the final topology.
4. Only import a private Studio candidate after a front/side/back review confirms the no-top-ear rule, round swallowed crown, eye/nose spacing, owner/customer proportions, and absence of holes or detached parts.

This route needs a temporary 24 GB+ Linux GPU or a future GPU upgrade. The desktop's current **GTX 1080 has 8 GB VRAM**, so TRELLIS/TRELLIS.2 cannot run locally within their documented requirements. No paid GPU should be started without approval.

The best no-spend local experiment is **Hunyuan3D-2mv shape generation**: it officially supports Windows, accepts one to four named views, and documents 6 GB VRAM for shape generation. However, its Tencent license excludes use/display in the EU, UK, and South Korea, which is a serious mismatch for a globally accessible Roblox release. Treat any output as a private evaluation candidate until that distribution issue is resolved. [Official repository](https://github.com/Tencent-Hunyuan/Hunyuan3D-2), [official multiview model card](https://huggingface.co/tencent/Hunyuan3D-2mv), [official license](https://github.com/Tencent-Hunyuan/Hunyuan3D-2/blob/main/LICENSE).

## Actual desktop capacity

Read-only inspection on 2026-08-09:

| Component | Detected | Consequence |
| --- | --- | --- |
| GPU | NVIDIA GeForce GTX 1080 | CUDA-capable, but old Pascal hardware |
| VRAM | 8 GB | Fits documented 6 GB Hunyuan3D-2 shape, SF3D, or TripoSR runs; does not fit TRELLIS 16 GB, TRELLIS.2 24 GB, or Hunyuan3D-2.1 texture generation 21 GB |
| CPU | Intel i7-7700K | Adequate for orchestration and Blender cleanup; not a practical substitute for high-end GPU inference |
| RAM | 31.9 GB | Adequate for local model tooling, with limited headroom during Blender + inference |
| `C:` free | 4.5 GB | Insufficient for model environments and weight caches |
| `D:` free | 287.3 GB | Put Git checkout, virtual environments, Hugging Face cache, and outputs here |
| `F:` free | 163.8 GB | Viable secondary cache/output location |

Use an explicit cache path such as `HF_HOME=D:\AI\hf-cache`; do not allow weights to fill `C:`.

## Candidate comparison

| Pipeline | Input / strengths | Official compute requirement | Output | License and Roblox-use consequence | Verdict |
| --- | --- | --- | --- | --- | --- |
| **TRELLIS.2-4B** | Single image; 512³–1536³ generation; arbitrary topology; base color, roughness, metallic, opacity | Linux only; NVIDIA GPU **24 GB minimum**; verified on A100/H100; CUDA 12.4 recommended; Python 3.8+ | PBR GLB; official example uses a 1,000,000-face decimation target and 4K texture, so it still needs Roblox reduction | Model and repo are MIT. Commercial use is permitted subject to retaining the MIT notice. Input-image rights remain the user's responsibility. | **Best final-candidate generator.** Highest advertised fidelity/PBR of the compared open pipelines and cleanest license, but not local on this PC. |
| **TRELLIS v1** | Single image or experimental multi-image; mesh + Gaussian + radiance field | Linux tested; NVIDIA GPU **16 GB minimum**; verified on A100/A6000; CUDA 11.8 or 12.2; Python 3.8+ | Textured GLB and optional Gaussian PLY | Models and majority of code are MIT; inspect licenses of bundled renderer submodules if redistributing the software. Generated asset use is substantially simpler than Hunyuan's territorial license. | **Best geometry cross-check from turnarounds.** Use beside TRELLIS.2, not instead of Blender art direction. |
| **Hunyuan3D-2.1** | Single-image 3.3B shape model + 2B PBR paint model; texture can be applied to an existing mesh | Windows/macOS/Linux; **10 GB shape**, **21 GB texture**, **29 GB combined**; official test stack Python 3.10, PyTorch 2.5.1 + CUDA 12.4 | Textured mesh; API default is GLB | Tencent community license excludes EU/UK/South Korea, restricts worldwide display, requires notices when distributing the model/software, and requires a separate license above the specified 1M-MAU threshold. Tencent claims no rights in generated outputs, but the geographic restriction applies to outputs too. | Excellent PBR candidate on a 24–32 GB GPU, but **not the default for a global Roblox game** without license review. |
| **Hunyuan3D-2mv / 2.0** | Dedicated 1.1B multiview shape model; front/back/left/right; Blender add-on/API available | Windows/macOS/Linux; **6 GB shape**, **16 GB shape+texture** | `trimesh` object exportable to GLB/OBJ; API emits GLB | Same Tencent territory/MAU constraints. Tencent claims no rights in outputs. | **Best local silhouette experiment on the GTX 1080**, but license prevents assuming it is shippable worldwide. |
| **Stable Fast 3D (SF3D)** | Single 512×512 image; fast feed-forward mesh; UV unwrap, delighting, roughness and metallic prediction; triangle/quad remesh options | Python 3.8+; Windows support is experimental and requires VS 2022; default single-image run uses about **6 GB VRAM**; CPU fallback exists | Textured GLB | Stability AI Community License: commercial use requires registration; free commercial use only while annual revenue is at most $1M; over that requires enterprise license. Outputs are owned by the user to the extent permitted by law. Distribution of model materials/derivatives adds license/notice/"Powered by" obligations. | **Local textured fallback**, but it is single-view and Stability explicitly points TripoSR users to SF3D as the improved/game-ready successor—not a top-fidelity character solution. |
| **TripoSR** | Single-image, very fast reconstruction; texture bake optional | Python 3.8+; default single-image run uses about **6 GB VRAM**; A100 inference reported under 0.5 s | OBJ or GLB; optional 2K texture atlas | Code and official model are MIT. | **Diagnostic fallback only.** Clean license and fits locally, but older/lower fidelity than SF3D and unlikely to meet the Pipi Labu face standard. |

Primary specifications: [TRELLIS.2 model card](https://huggingface.co/microsoft/TRELLIS.2-4B), [TRELLIS repository](https://github.com/microsoft/TRELLIS), [Hunyuan3D-2.1 repository](https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1), [Hunyuan3D-2 repository](https://github.com/Tencent-Hunyuan/Hunyuan3D-2), [SF3D repository](https://github.com/Stability-AI/stable-fast-3d), [SF3D license](https://github.com/Stability-AI/stable-fast-3d/blob/main/LICENSE.md), [TripoSR repository](https://github.com/VAST-AI-Research/TripoSR), [TripoSR model card](https://huggingface.co/stabilityai/TripoSR).

## Exact runnable entry points

These are the official entry points, adapted only to keep large files on `D:`. They are not installation results from this research pass.

### A. Highest-fidelity candidate: TRELLIS.2 on a 24 GB+ Linux NVIDIA machine

```bash
git clone -b main https://github.com/microsoft/TRELLIS.2.git --recursive
cd TRELLIS.2
. ./setup.sh --new-env --basic --flash-attn --nvdiffrast --nvdiffrec --cumesh --o-voxel --flexgemm
conda activate trellis2
python app.py
```

The scripted API is `Trellis2ImageTo3DPipeline.from_pretrained("microsoft/TRELLIS.2-4B")`, followed by `pipeline.run(image)` and `o_voxel.postprocess.to_glb(...)`. [Official setup and example](https://github.com/microsoft/TRELLIS.2#%EF%B8%8F-installation).

Use 512³ first to fan out seeds, then 1024³ for finalists. The H100 timings in the model card are approximately 3 seconds at 512³, 17 seconds at 1024³, and 60 seconds at 1536³; consumer 24 GB GPUs will be slower. Do not use the default million-face export as the Roblox mesh.

### B. Turnaround consistency: TRELLIS v1 multi-image on a 16 GB+ Linux NVIDIA machine

```bash
git clone --recurse-submodules https://github.com/microsoft/TRELLIS.git
cd TRELLIS
. ./setup.sh --new-env --basic --xformers --flash-attn --diffoctreerast --spconv --mipgaussian --kaolin --nvdiffrast
conda activate trellis
python app.py
```

Programmatic core:

```python
images = [Image.open(front), Image.open(side), Image.open(back)]
outputs = pipeline.run_multi_image(images, seed=seed)
glb = postprocessing_utils.to_glb(
    outputs["gaussian"][0], outputs["mesh"][0],
    simplify=0.95, texture_size=1024,
)
glb.export("pipi_candidate.glb")
```

Use only mutually consistent views. The official app explicitly warns that the multi-image algorithm is experimental and performs poorly when poses or details differ. [Official source](https://github.com/microsoft/TRELLIS/blob/main/app.py#L237-L255).

### C. Local 8 GB experiment: Hunyuan3D-2mv shape only

PowerShell outline based on the official Windows-support and installation instructions:

```powershell
$env:HF_HOME = 'D:\AI\hf-cache'
git clone https://github.com/Tencent-Hunyuan/Hunyuan3D-2.git D:\AI\Hunyuan3D-2
py -3.10 -m venv D:\AI\venvs\hunyuan3d2
D:\AI\venvs\hunyuan3d2\Scripts\Activate.ps1
# Install the CUDA-enabled PyTorch build selected from pytorch.org for this machine.
pip install -r D:\AI\Hunyuan3D-2\requirements.txt
pip install -e D:\AI\Hunyuan3D-2
Set-Location D:\AI\Hunyuan3D-2
python gradio_app.py --model_path tencent/Hunyuan3D-2mv --subfolder hunyuan3d-dit-v2-mv --low_vram_mode
```

The official multiview API accepts:

```python
mesh = pipeline(
    image={
        "front": "front.png",
        "left": "left.png",
        "back": "back.png",
    },
    num_inference_steps=30,
    octree_resolution=380,
    num_chunks=20000,
    generator=torch.manual_seed(12345),
    output_type="trimesh",
)[0]
mesh.export("pipi_mv.glb")
```

Use the non-Turbo path initially; the GTX 1080 is old enough that optional accelerated kernels should not be assumed compatible. The 8 GB card has only ~2 GB of documented headroom over the 6 GB shape requirement. Texture generation does not fit locally.

### D. Local textured fallback: Stable Fast 3D

```powershell
$env:HF_HOME = 'D:\AI\hf-cache'
git clone https://github.com/Stability-AI/stable-fast-3d D:\AI\stable-fast-3d
py -3.10 -m venv D:\AI\venvs\sf3d
D:\AI\venvs\sf3d\Scripts\Activate.ps1
# Install the matching CUDA-enabled PyTorch build first.
pip install -U setuptools==69.5.1
pip install wheel
pip install -r D:\AI\stable-fast-3d\requirements.txt
Set-Location D:\AI\stable-fast-3d
python run.py D:\AI\inputs\pipi-front.png --output-dir D:\AI\outputs\sf3d --texture-resolution 1024 --remesh_option triangle --target_vertex_count 18000
```

The official runner writes `mesh.glb`. Access to the model weights is gated behind accepting Stability's license on Hugging Face. [Official runner](https://github.com/Stability-AI/stable-fast-3d/blob/main/run.py), [official model card](https://huggingface.co/stabilityai/stable-fast-3d).

### E. Simplest MIT fallback: TripoSR

```powershell
$env:HF_HOME = 'D:\AI\hf-cache'
git clone https://github.com/VAST-AI-Research/TripoSR D:\AI\TripoSR
py -3.10 -m venv D:\AI\venvs\triposr
D:\AI\venvs\triposr\Scripts\Activate.ps1
# Install the matching CUDA-enabled PyTorch build first.
pip install --upgrade setuptools
pip install -r D:\AI\TripoSR\requirements.txt
Set-Location D:\AI\TripoSR
python run.py D:\AI\inputs\pipi-front.png --output-dir D:\AI\outputs\triposr --model-save-format glb --bake-texture --texture-resolution 1024
```

The official runner supports OBJ/GLB and defaults to a 2K baked texture when requested. [Official runner](https://github.com/VAST-AI-Research/TripoSR/blob/main/run.py).

## Reference preparation is a quality gate

The model input should be a clean asset sheet, not a phone screenshot or email UI capture:

- Crop the dog only and remove Instagram/Gmail UI, tables, crates, hands, apples, and background clutter.
- Put front, left, right, and back views on transparent or uniform backgrounds.
- Make every view the same character, scale, neutral stance, eye direction, and lighting. Do not mix owner and customer proportions.
- Preserve the actual rule: customer has no visible top ears; owner may have only low lateral/swallowed folds that do not break the crown.
- Run several fixed seeds and render every candidate from front, 45°, side, and back before selecting. A good front projection with a malformed back is a rejection.

This is especially important because TRELLIS v1 explicitly warns that its tuning-free multi-image path is sensitive to inconsistent views, while TRELLIS.2 explicitly warns that it is not aligned to a particular aesthetic and may require input experimentation. [TRELLIS app](https://github.com/microsoft/TRELLIS/blob/main/app.py#L237-L255), [TRELLIS.2 limitations](https://huggingface.co/microsoft/TRELLIS.2-4B#known-limitations).

## Blender-to-Roblox finishing contract

No compared pipeline emits a Roblox-ready animated character rig. Their documented outputs are static OBJ/GLB/trimesh/PBR assets. The selected candidate still needs:

1. Import GLB into Blender and inspect actual geometry with flat lighting and matcap, not only the texture render.
2. Repair holes, non-manifold edges, floaters, fused paws, asymmetry, and hollow/hidden geometry.
3. Sculpt the exact face and silhouette against the approved reference. Keep eyes, muzzle, nose, paws, and tail readable at Roblox gameplay distance.
4. Retopologize or remesh for deformation; use consistent quads around limbs/mouth rather than accepting diffusion topology.
5. UV to one 0–1 set per component; bake albedo, OpenGL tangent-space normal, roughness, and metallic maps.
6. Rig and skin in Blender. Roblox requires no more than four bone influences per vertex, a root at the origin, and frozen transforms. Export each animation as a separate FBX track.
7. Split geometry so **each MeshPart is at most 20,000 triangles**. Each mesh object can have only one material. For a non-avatar NPC, use multiple MeshParts under one Model where necessary.
8. Export FBX with `Apply Scalings = FBX Unit Scale`, `Add Leaf Bones` off, and embedded/copied textures; import privately through Studio's 3D Importer.

Roblox primary references: [general mesh/rig/animation specifications](https://create.roblox.com/docs/art/modeling/specifications), [FBX export settings](https://create.roblox.com/docs/art/modeling/export-requirements), [PBR texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications), [supported third-party formats](https://create.roblox.com/docs/art/overview-dcc).

## License boundary

- A model license never grants rights to the input character, meme images, Roblox Marketplace items, or third-party reference art. Only use images Leo/Jon own or are authorized to adapt. The four linked Roblox catalog/bundle assets are visual references/placeholders, not source meshes to download, copy, or redistribute without their asset terms and creator permission.
- Keep all generated/imported candidates private until the visual and rights gates pass.
- **TRELLIS/TRELLIS.2 and TripoSR:** MIT is the cleanest option for eventual commercial Roblox use; retain required copyright/license notices if distributing the software or substantial code.
- **SF3D:** register for commercial use and track the $1M annual-revenue threshold and attribution/distribution requirements. [Official license](https://github.com/Stability-AI/stable-fast-3d/blob/main/LICENSE.md).
- **Hunyuan:** do not assume a Roblox upload is globally shippable. Its license says the model and outputs may not be used, reproduced, distributed, or displayed in the EU, UK, or South Korea. It also adds a 1M-MAU licensing gate. [Official 2.0 license](https://github.com/Tencent-Hunyuan/Hunyuan3D-2/blob/main/LICENSE), [official 2.1 license](https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1/blob/main/LICENSE).

## Recommended next execution pass

1. Produce clean transparent owner and customer reference sets from the approved sheets.
2. Use a 24 GB+ Linux GPU for 8–12 TRELLIS.2 seeds per character at 512³; retain the best two per character and regenerate those at 1024³.
3. Run one TRELLIS v1 multi-image batch per character as the turnaround-consistency control.
4. Build a contact sheet containing flat-shaded geometry and PBR renders from four angles. Reject before rigging if the crown, ears, muzzle, body height, or paws are wrong.
5. Finish one owner model in Blender end-to-end before producing a customer family. This prevents multiplying a bad base mesh.
6. Private Studio import only after Blender geometry verification; do not replace gameplay characters until Jon/Leo approve the actual Studio render.

If no 16–24 GB GPU is authorized, use Hunyuan3D-2mv locally only to test whether the supplied turnaround is coherent enough to reconstruct. Use SF3D/TripoSR as quick controls, not as the promised final Pipi Labu model.

## Local execution results — 2026-08-09

- Installed and ran the official TripoSR path locally on the GTX 1080 using CUDA. The owner and customer front views reconstructed, but neutral four-angle Blender inspection exposed flat wedge profiles, invented backs, and non-production topology. The owner was `75,863` vertices / `151,698` faces over seven components; the customer was `60,081` / `120,158` in one component. Both are rejected controls and were not imported into Studio.
- Roblox `GenerateMesh` also failed as a control: despite an explicit swallowed-ear, low-bodied prompt, it generated a generic upright Shiba with large top ears. It is quarantined in ServerStorage and cannot become gameplay art.
- Downloaded Pat Siefring's CC-BY Poly Pizza Shiba as a legally attributable low-poly base and built a real Blender deformation pipeline around it. Welding before Catmull-Clark repaired its split flat-shaded topology; tail/ear removal and role-specific deformation produced continuous `12,912`-triangle owner/customer controls. Four-angle inspection still rejects them for exact likeness: the owner remains too conventional/bear-like and the customer too seal/sausage-like.
- Empirical conclusion: neither single-view TripoSR nor prompt-only Roblox generation can satisfy the character bar. A low-detail licensed base is useful for proving the Blender/Roblox mechanics, not for final likeness. Final work should begin with higher-detail multi-view geometry (TRELLIS.2/TRELLIS v1 or an appropriately licensed detailed mesh), then receive deliberate Blender sculpt, retopology, UV/PBR, and rigging passes.
