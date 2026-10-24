# tools/pin-gate.ps1
# Gate de Pinning Exato de Dependências Cripto e Framework (INV-SEC-11)
# Garante que dependências críticas estejam fixadas em versão exata sem ranges
# e sem divergência entre pubspec.yaml e pubspec.lock.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ApiPubspecPath,

    [Parameter(Mandatory=$false)]
    [string]$LockfilePath
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
Set-Location $RepoRoot

Write-Host "==> [Pin Gate] Verificando pinning exato de dependências críticas (INV-SEC-11)..."

if (-not $ApiPubspecPath) {
    $ApiPubspecPath = Join-Path $RepoRoot "solution/api/pubspec.yaml"
}
if (-not $LockfilePath) {
    $LockfilePath = Join-Path $RepoRoot "pubspec.lock"
}

if (-not (Test-Path $ApiPubspecPath)) {
    Write-Error "[PIN-FAIL] pubspec.yaml da api não encontrado: $ApiPubspecPath"
    exit 1
}

if (-not (Test-Path $LockfilePath)) {
    Write-Error "[PIN-FAIL] pubspec.lock não encontrado na raiz: $LockfilePath"
    exit 1
}

$apiPubspec = Get-Content -Path $ApiPubspecPath -Raw
$lockfile = Get-Content -Path $LockfilePath -Raw

$violations = @()

# Pacotes críticos que exigem pin exato (versão exata sem wildcard ou range)
$criticalPins = @{
    "pointycastle" = "4.0.0"
}

foreach ($pkg in $criticalPins.Keys) {
    $expectedVer = $criticalPins[$pkg]

    # 1. Checa pin no pubspec.yaml (deve ser exato sem ^, >, <, ~)
    $pattern = "(?m)^\s*" + [regex]::Escape($pkg) + "\s*:\s*(.+)$"
    if ($apiPubspec -match $pattern) {
        $actualVer = $Matches[1].Trim().Trim('"').Trim("'")
        if ($actualVer -ne $expectedVer) {
            $violations += "Pacote '$pkg' em $ApiPubspecPath deve ter pin exato '$expectedVer', mas possui '$actualVer' (ranges '^', '>', '~' são proibidos por INV-SEC-11)."
        }
    } else {
        $violations += "Pacote crítico '$pkg' não declarado em $ApiPubspecPath."
    }

    # 2. Checa versão efetivamente travada no pubspec.lock
    $lockPattern = "(?ms)^\s*" + [regex]::Escape($pkg) + ":.*?version:\s*""?([^""\r\n]+)""?"
    if ($lockfile -match $lockPattern) {
        $lockedVer = $Matches[1].Trim()
        if ($lockedVer -ne $expectedVer) {
            $violations += "Pacote '$pkg' está travado no pubspec.lock com versão '$lockedVer', divergindo do pin exato '$expectedVer' (INV-SEC-11)."
        }
    } else {
        $violations += "Pacote crítico '$pkg' ausente no pubspec.lock."
    }
}

if ($violations.Count -gt 0) {
    Write-Host "`n[PIN-FAIL] Violações de pinning detectadas (INV-SEC-11):" -ForegroundColor Red
    foreach ($v in $violations) {
        Write-Host "  - $v" -ForegroundColor Red
    }
    Write-Host "`nCorreção obrigatória:" -ForegroundColor Yellow
    Write-Host "1. Mantenha os pins exatos sem range em solution/api/pubspec.yaml (ex: pointycastle: 4.0.0)."
    Write-Host "2. Execute 'dart pub get' para alinhar pubspec.lock."
    exit 1
}

Write-Host "  [OK] Todas as dependências críticas possuem pin exato e íntegro (INV-SEC-11)."
exit 0
