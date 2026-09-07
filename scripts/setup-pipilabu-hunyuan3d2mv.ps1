param(
    [string]$RuntimeRoot = "D:\CodexTemp\pipilabu-3d",
    [string]$VenvName = "triposr-venv"
)

$ErrorActionPreference = "Stop"

$repo = Join-Path $RuntimeRoot "Hunyuan3D-2"
$venv = Join-Path $RuntimeRoot $VenvName
$python = Join-Path $venv "Scripts\python.exe"
$hfHome = Join-Path $RuntimeRoot "hf-cache"

New-Item -ItemType Directory -Force -Path $RuntimeRoot, $hfHome | Out-Null

if (-not (Test-Path (Join-Path $repo ".git"))) {
    git clone --depth 1 https://github.com/Tencent-Hunyuan/Hunyuan3D-2.git $repo
    if ($LASTEXITCODE -ne 0) { throw "Hunyuan3D-2 clone failed." }
}

if (-not (Test-Path $python)) {
    py -3.10 -m venv $venv
    if ($LASTEXITCODE -ne 0) { throw "Python 3.10 virtual environment creation failed." }
}

& $python -m pip install --upgrade pip setuptools wheel
if ($LASTEXITCODE -ne 0) { throw "Base Python tooling installation failed." }

# Reuse the adjacent TripoSR environment by default: its CUDA 11.8 build is already
# verified on this GTX 1080 and avoids downloading another 2.7 GB wheel.
& $python -c "import torch, torchvision; assert torch.cuda.is_available()"
if ($LASTEXITCODE -ne 0) {
    & $python -m pip install torch==2.1.2 torchvision==0.16.2 --index-url https://download.pytorch.org/whl/cu118
    if ($LASTEXITCODE -ne 0) { throw "CUDA PyTorch installation failed." }
}

# This runtime is shape-only. The adjacent TripoSR environment already contains
# Torch, Transformers, OpenCV, rembg, ONNX Runtime, trimesh, and xatlas. Avoid the
# full demo dependency set (Gradio/FastAPI and a redundant OpenCV wheel).
& $python -m pip install `
    ninja `
    pybind11 `
    "diffusers==0.35.2" `
    "accelerate==1.4.0" `
    "transformers==4.49.0" `
    "huggingface_hub==0.36.0" `
    pymeshlab `
    pygltflib
if ($LASTEXITCODE -ne 0) { throw "Hunyuan3D shape dependencies installation failed." }

& $python -m pip install -e $repo --no-deps
if ($LASTEXITCODE -ne 0) { throw "Editable Hunyuan3D installation failed." }

$env:HF_HOME = $hfHome
& $python -c "import torch; from hy3dgen.shapegen import Hunyuan3DDiTFlowMatchingPipeline; assert torch.cuda.is_available(); print('HUNYUAN3D2MV_SETUP_OK', torch.__version__, torch.cuda.get_device_name(0))"
if ($LASTEXITCODE -ne 0) { throw "Hunyuan3D import/CUDA verification failed." }
