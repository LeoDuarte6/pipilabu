[CmdletBinding()]
param(
    [string]$RuntimeRoot = "D:\CodexTemp\pipilabu-3d"
)

$ErrorActionPreference = "Stop"
$triposrRoot = Join-Path $RuntimeRoot "TripoSR"
$venvRoot = Join-Path $RuntimeRoot "triposr-venv"
$cacheRoot = Join-Path $RuntimeRoot "cache"
$tempRoot = Join-Path $RuntimeRoot "temp"
$python = Join-Path $venvRoot "Scripts\python.exe"

New-Item -ItemType Directory -Force -Path $RuntimeRoot, $cacheRoot, $tempRoot | Out-Null
$env:PIP_CACHE_DIR = $cacheRoot
$env:HF_HOME = Join-Path $cacheRoot "huggingface"
$env:TEMP = $tempRoot
$env:TMP = $tempRoot

if (-not (Test-Path -LiteralPath (Join-Path $triposrRoot ".git"))) {
    git clone --filter=blob:none --depth 1 https://github.com/VAST-AI-Research/TripoSR.git $triposrRoot
}

$fallbackPatch = Join-Path $PSScriptRoot "triposr-skimage-fallback.patch"
if (-not (Select-String -LiteralPath (Join-Path $triposrRoot "tsr\models\isosurface.py") -SimpleMatch "skimage_marching_cubes" -Quiet)) {
    git -C $triposrRoot apply $fallbackPatch
}

if (-not (Test-Path -LiteralPath $python)) {
    py -3.10 -m venv $venvRoot
}

& $python -m pip install --upgrade pip setuptools wheel
$torchWheel = Join-Path $RuntimeRoot "wheels\torch-2.1.2+cu118-cp310-cp310-win_amd64.whl"
if (Test-Path -LiteralPath $torchWheel) {
    & $python -m pip install $torchWheel
} else {
    & $python -m pip install torch==2.1.2 --index-url https://download.pytorch.org/whl/cu118
}
& $python -m pip install torchvision==0.16.2 --index-url https://download.pytorch.org/whl/cu118
& $python -m pip install `
    numpy==1.26.4 omegaconf==2.3.0 Pillow==10.1.0 einops==0.7.0 transformers==4.35.0 `
    trimesh==4.0.5 rembg onnxruntime huggingface-hub "imageio[ffmpeg]" `
    xatlas==0.0.9 moderngl==5.10.0 scikit-image

& $python -c "import json, torch; print(json.dumps({'torch': torch.__version__, 'cuda_available': torch.cuda.is_available(), 'gpu': torch.cuda.get_device_name(0) if torch.cuda.is_available() else None}))"
