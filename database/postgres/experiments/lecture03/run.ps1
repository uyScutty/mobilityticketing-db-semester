$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
$databaseName = 'mobility_l3_test'
$evidenceLog = Join-Path $repoRoot 'docs\evidence\lecture03\test-output.txt'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Add-Evidence {
    param([string] $Text)

    [System.IO.File]::AppendAllText($evidenceLog, $Text, $utf8NoBom)
}

function Invoke-DockerCommand {
    param([string[]] $Arguments)

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & docker @Arguments | Out-String
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }

    if ($output) {
        Write-Host $output -NoNewline
        Add-Evidence $output
    }

    if ($exitCode -ne 0) {
        throw "Docker command failed with exit code $exitCode"
    }
}

function Invoke-SqlFile {
    param([string] $RelativePath)

    $absolutePath = Join-Path $repoRoot $RelativePath
    Write-Host "Running $RelativePath"
    Add-Evidence "`n===== $RelativePath =====`n"

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = Get-Content -Raw -LiteralPath $absolutePath |
            docker compose exec -T postgres psql -U mobility -d $databaseName -v ON_ERROR_STOP=1 |
            Out-String
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }

    if ($output) {
        Write-Host $output -NoNewline
        Add-Evidence $output
    }

    if ($exitCode -ne 0) {
        throw "$RelativePath failed with exit code $exitCode"
    }
}

Push-Location $repoRoot
try {
    [System.IO.File]::WriteAllText(
        $evidenceLog,
        "Lecture 3 PostgreSQL test output`n",
        $utf8NoBom
    )

    Invoke-DockerCommand @(
        'compose', 'up', '-d', '--wait', 'postgres'
    )
    Invoke-DockerCommand @(
        'compose', 'exec', '-T', 'postgres',
        'dropdb', '-U', 'mobility', '--if-exists', $databaseName
    )
    Invoke-DockerCommand @(
        'compose', 'exec', '-T', 'postgres',
        'createdb', '-U', 'mobility', $databaseName
    )

    @(
        'database/postgres/init/001_relational_baseline.sql',
        'database/postgres/init/002_seed.sql',
        'database/postgres/init/010_ticketing_draft.sql',
        'database/postgres/init/011_ticketing_seed.sql',
        'database/postgres/migrations/020_enforce_ticketing_integrity.sql',
        'database/postgres/migrations/021_add_reporting_programmability.sql',
        'database/postgres/experiments/lecture03/reporting_function.sql',
        'database/postgres/experiments/lecture03/trigger_experiment.sql',
        'database/postgres/experiments/lecture03/materialized_view_experiment.sql'
    ) | ForEach-Object { Invoke-SqlFile $_ }

    $successMessage = 'Lecture 3 tests passed.'
    Write-Host $successMessage
    Add-Evidence "`n$successMessage`n"
}
finally {
    Pop-Location
}
