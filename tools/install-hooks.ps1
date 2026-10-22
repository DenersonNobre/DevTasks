# tools/install-hooks.ps1
# Instalação dos Git Hooks do DevTasks (F0.4 / UC-00.04)
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
Set-Location $RepoRoot

Write-Host "==> [DevTasks] Instalando Git Hooks versionados (core.hooksPath = tools/hooks)..."
& git config core.hooksPath "tools/hooks"

# Como salvaguarda para clientes Git que ignoram core.hooksPath, copia também para .git/hooks/
$gitHooksDir = Join-Path $RepoRoot ".git/hooks"
if (Test-Path $gitHooksDir) {
    Copy-Item -Path "$RepoRoot/tools/hooks/commit-msg" -Destination "$gitHooksDir/commit-msg" -Force
    Copy-Item -Path "$RepoRoot/tools/hooks/commit-msg.ps1" -Destination "$gitHooksDir/commit-msg.ps1" -Force
}

Write-Host "==> [DevTasks] Git hooks instalados com sucesso!"
exit 0
