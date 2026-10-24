# tools/db.ps1
# Runner de banco do DevTasks (UC-08.02): migrations + status + reset.
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('up', 'status', 'reset')]
    [string]$Action = 'up',

    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir '..')
$ApiDir = Join-Path $RepoRoot 'solution/api'

if (-not (Test-Path $ApiDir)) {
    Write-Error "[db] pasta não encontrada: $ApiDir"
    exit 1
}

Push-Location $ApiDir
try {
    switch ($Action) {
        'status' {
            dart run bin/migrate.dart --status
        }
        'reset' {
            if (-not $Force) {
                Write-Host '[db] reset é destrutivo (DROP SCHEMA public). Reexecute com -Force.' -ForegroundColor Yellow
                exit 2
            }
            $env:DEVTASKS_ALLOW_RESET = 'true'
            dart run bin/migrate.dart --reset
            dart run bin/migrate.dart
            Remove-Item Env:\DEVTASKS_ALLOW_RESET -ErrorAction SilentlyContinue
        }
        default {
            dart run bin/migrate.dart
        }
    }
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
