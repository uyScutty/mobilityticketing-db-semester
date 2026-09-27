$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$runners = @(
    'database/postgres/experiments/lecture01/run.ps1',
    'database/postgres/experiments/lecture02/run.ps1',
    'database/postgres/experiments/lecture03/run.ps1',
    'database/postgres/experiments/lecture04/run.ps1'
)

Push-Location $repoRoot
try {
    foreach ($runner in $runners) {
        Write-Host "`n===== Running $runner ====="
        & powershell -NoProfile -ExecutionPolicy Bypass -File $runner
        if ($LASTEXITCODE -ne 0) {
            throw "$runner failed with exit code $LASTEXITCODE"
        }
    }

    Write-Host "`nAll Lecture 1-4 tests passed."
}
finally {
    Pop-Location
}
