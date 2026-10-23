# tools/pin-gate.ps1
# Gate de Pinning Exato de Dependências Cripto e Framework (INV-SEC-11)
# Garante que dependências críticas (Serverpod, Auth, etc.) estejam fixadas
# em versão exata sem ranges e sem divergência entre pubspec.yaml e pubspec.lock.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ServerPubspecPath,

    [Parameter(Mandatory=$false)]
    [string]$LockfilePath
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
Set-Location $RepoRoot

Write-Host "==> [Pin Gate] Verificando pinning exato de dependências críticas (INV-SEC-11)..."

if (-not $ServerPubspecPath) {
    $ServerPubspecPath = Join-Path $RepoRoot "solution/server/pubspec.yaml"
}
if (-not $LockfilePath) {
    $LockfilePath = Join-Path $RepoRoot "pubspec.lock"
}

if (-not (Test-Path $ServerPubspecPath)) {
    Write-Error "[PIN-FAIL] pubspec.yaml do server não encontrado: $ServerPubspecPath"
    exit 1
}

if (-not (Test-Path $LockfilePath)) {
    Write-Error "[PIN-FAIL] pubspec.lock não encontrado na raiz: $LockfilePath"
    exit 1
}

$serverPubspec = Get-Content -Path $ServerPubspecPath -Raw
$lockfile = Get-Content -Path $LockfilePath -Raw

$violations = @()

# Pacotes críticos que exigem pin exato (versão exata sem wildcard ou range)
$criticalPins = @{
    "serverpod"             = "3.4.13"
    "serverpod_auth_server" = "3.4.13"
}

foreach ($pkg in $criticalPins.Keys) {
    $expectedVer = $criticalPins[$pkg]

    # 1. Checa pin no pubspec.yaml (deve ser exato, ex: 'serverpod: 3.4.13' sem ^, >, <, ~)
    $pattern = "(?m)^\s*" + [regex]::Escape($pkg) + "\s*:\s*(.+)$"
    if ($serverPubspec -match $pattern) {
        $actualVer = $Matches[1].Trim().Trim('"').Trim("'")
        if ($actualVer -ne $expectedVer) {
            $violations += "Pacote '$pkg' em $ServerPubspecPath deve ter pin exato '$expectedVer', mas possui '$actualVer' (ranges '^', '>', '~' são proibidos por INV-SEC-11)."
        }
    } else {
        $violations += "Pacote crítico '$pkg' não declarado em $ServerPubspecPath."
    }

    # 2. Checa versão efetivamente travada no pubspec.lock
    $lockPattern = "(?ms)^\s*" + [regex]::Escape($pkg) + ":.*?version:\s*""?([^""\r\n]+)""?"
    if ($lockfile -match $lockPattern) {
        $lockedVer = $Matches[1].Trim()
        if ($lockedVer -ne $expectedVer) {
            $violations += "Pacote '$pkg' travado em '$lockedVer' no pubspec.lock, divergindo do pin exato '$expectedVer'."
        }
    } else {
        $violations += "Pacote '$pkg' ausente no pubspec.lock."
    }
}

if ($violations.Count -gt 0) {
    Write-Error @"
[PIN-GATE-VIOLATION]
Foram detectadas violações à política INV-SEC-11 (pinning de dependências):
$($violations -join "`n")

Para corrigir:
1. Mantenha os pins exatos sem range em solution/server/pubspec.yaml (ex: serverpod: 3.4.13).
2. Execute 'flutter pub get' para sincronizar o pubspec.lock.
"@
    exit 1
}

Write-Host "  [OK] Todos os pacotes críticos possuem pin exato e lockfile sincronizado."
exit 0

