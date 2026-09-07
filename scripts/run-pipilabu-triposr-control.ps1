[CmdletBinding()]
param(
    [string]$RuntimeRoot = "D:\CodexTemp\pipilabu-3d",
    [string]$OutputRoot = "D:\CodexTemp\pipilabu-3d\outputs\pipi-labu-control-v1"
)

$ErrorActionPreference = "Stop"
$triposrRoot = Join-Path $RuntimeRoot "TripoSR"
$python = Join-Path $RuntimeRoot "triposr-venv\Scripts\python.exe"
$inputRoot = Join-Path $RuntimeRoot "inputs"
$modelRoot = Join-Path $RuntimeRoot "models\TripoSR"
$ownerInput = Join-Path $inputRoot "owner_front.png"
$customerInput = Join-Path $inputRoot "customer_front.png"

foreach ($required in @($python, (Join-Path $triposrRoot "run.py"), (Join-Path $modelRoot "config.yaml"), (Join-Path $modelRoot "model.ckpt"), $ownerInput, $customerInput)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Missing TripoSR control dependency: $required"
    }
}

$env:HF_HOME = Join-Path $RuntimeRoot "cache\huggingface"
$env:TORCH_HOME = Join-Path $RuntimeRoot "cache\torch"
$env:U2NET_HOME = Join-Path $RuntimeRoot "cache\u2net"
$env:TEMP = Join-Path $RuntimeRoot "temp"
$env:TMP = $env:TEMP
New-Item -ItemType Directory -Force -Path $OutputRoot, $env:HF_HOME, $env:TORCH_HOME, $env:U2NET_HOME, $env:TEMP | Out-Null

Push-Location $triposrRoot
try {
    # Keep the diagnostic on TripoSR's supported vertex-color GLB path. The
    # upstream texture baker mixes CPU UV samples with CUDA triplanes on this
    # Windows build; repairing an atlas for a visually rejected reconstruction
    # would add no useful evidence.
    & $python run.py $ownerInput $customerInput `
        --output-dir $OutputRoot `
        --pretrained-model-name-or-path $modelRoot `
        --device cuda:0 `
        --chunk-size 4096 `
        --mc-resolution 256 `
        --model-save-format glb `
        --render
    if ($LASTEXITCODE -ne 0) {
        throw "TripoSR control run failed with exit code $LASTEXITCODE"
    }
} finally {
    Pop-Location
}

Write-Output "PIPILABU_TRIPOSR_CONTROL_OK output=$OutputRoot"
