# tools/clean.ps1
# Limpeza idempotente de artefatos de build e caches locais (F0.2 / UC-00.02)
[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
Set-Location $RepoRoot

Write-Host "==> [DevTasks] Executando limpeza idempotente..."

$directoriesToClean = @(
    "solution/app/build",
    "solution/app/.dart_tool",
    "solution/server/build",
    "solution/server/.dart_tool",
    ".dart_tool"
)

foreach ($dir in $directoriesToClean) {
    $fullPath = Join-Path $RepoRoot $dir
    if (Test-Path $fullPath) {
        Write-Host "  Removendo: $dir"
        Remove-Item -Recurse -Force $fullPath -ErrorAction SilentlyContinue
    }
}

Write-Host "==> [DevTasks] Limpeza concluída com sucesso (código-fonte preservado)."
exit 0

