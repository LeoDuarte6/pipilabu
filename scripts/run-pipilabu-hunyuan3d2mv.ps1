param(
    [string]$RuntimeRoot = "D:\CodexTemp\pipilabu-3d",
    [string]$Sheet = "assets\concepts\pipi-labu-owner-reconstruction-sheet-v9.png",
    [string]$OutputDir = "D:\CodexTemp\pipilabu-3d\outputs\hunyuan2mv-owner-v1",
    [string]$VenvName = "triposr-venv",
    [int]$Seed = 29081997,
    [int]$Steps = 40,
    [int]$OctreeResolution = 320
)

$ErrorActionPreference = "Stop"
$python = Join-Path $RuntimeRoot "$VenvName\Scripts\python.exe"
$repo = Join-Path $RuntimeRoot "Hunyuan3D-2"

if (-not (Test-Path $python)) {
    throw "Hunyuan3D-2mv runtime is missing. Run scripts/setup-pipilabu-hunyuan3d2mv.ps1 first."
}

$sheetPath = (Resolve-Path $Sheet).Path
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$env:HF_HOME = Join-Path $RuntimeRoot "hf-cache"
$env:PYTHONPATH = $repo

& $python scripts\run-pipilabu-hunyuan3d2mv.py `
    --sheet $sheetPath `
    --output-dir $OutputDir `
    --seed $Seed `
    --steps $Steps `
    --octree-resolution $OctreeResolution

if ($LASTEXITCODE -ne 0) { throw "Hunyuan3D-2mv owner control failed." }
