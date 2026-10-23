# tools/install-hooks.ps1
# Configuração dos Git Hooks do DevTasks via core.hooksPath (F0.4 / NC-24)
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$LegacyCopyFallback
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
Set-Location $RepoRoot

Write-Host "==> [DevTasks] Configurando Git Hooks versionados (core.hooksPath = tools/hooks)..."
& git config core.hooksPath "tools/hooks"

$gitHooksDir = Join-Path $RepoRoot ".git/hooks"

if ($LegacyCopyFallback -and (Test-Path $gitHooksDir)) {
    Write-Host "  [INFO] Copiando hooks para .git/hooks (modo fallback legado ativado)..."
    Copy-Item -Path "$RepoRoot/tools/hooks/commit-msg" -Destination "$gitHooksDir/commit-msg" -Force
    Copy-Item -Path "$RepoRoot/tools/hooks/commit-msg.ps1" -Destination "$gitHooksDir/commit-msg.ps1" -Force
    Copy-Item -Path "$RepoRoot/tools/hooks/pre-commit" -Destination "$gitHooksDir/pre-commit" -Force
    Copy-Item -Path "$RepoRoot/tools/hooks/pre-commit.ps1" -Destination "$gitHooksDir/pre-commit.ps1" -Force
} else {
    # Remove cópias legadas obsoletas para garantir que tools/hooks seja a fonte única da verdade
    if (Test-Path $gitHooksDir) {
        Remove-Item -Path "$gitHooksDir/commit-msg*" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$gitHooksDir/pre-commit*" -Force -ErrorAction SilentlyContinue
    }
    Write-Host "  [OK] core.hooksPath ativo apontando para 'tools/hooks' (fonte única, sem duplicatas em .git/hooks)."
}

Write-Host "==> [DevTasks] Git hooks instalados com sucesso!"
exit 0
