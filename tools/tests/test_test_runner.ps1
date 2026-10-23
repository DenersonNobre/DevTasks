# Test suite for tools/test.ps1
# Implements Gherkin acceptance criteria for UC-00.03 (US-0.3.1)
# Provas negativas REAIS (NC-09): falha de teste genuína, gate de cobertura e orçamento de tempo.

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "../..")
Set-Location $RepoRoot

$TestScript = Join-Path $RepoRoot "tools/test.ps1"
$psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell.exe" }

Write-Host "=== TEST 1: Verificar existência de tools/test.ps1 ==="
if (-not (Test-Path $TestScript)) {
    throw "RED EXPECTED: tools/test.ps1 does not exist yet."
}

Write-Host "=== TEST 2: Suíte core verde em um comando (exit 0) ==="
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
& $psExe -ExecutionPolicy Bypass -NoProfile -File $TestScript
$elapsed = $stopwatch.Elapsed.TotalSeconds
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: tools/test.ps1 failed with exit code $LASTEXITCODE"
}
if ($elapsed -gt 60) {
    throw "FAIL: tools/test.ps1 exceeded limit (NFR-03: 60s). Took: $elapsed s"
}
Write-Host "Pass: Test runner completed successfully in $elapsed s (<= 60s)"

Write-Host "=== TEST 3: Falha propagada por teste GENUINAMENTE falho (nunca verde falso) ==="
$probeTest = Join-Path $RepoRoot "solution/server/test/zz_fail_probe_test.dart"
try {
    @'
import 'package:test/test.dart';

void main() {
  test('probe de falha real', () {
    expect(1, 2);
  });
}
'@ | Set-Content -Path $probeTest -Encoding utf8

    & $psExe -ExecutionPolicy Bypass -NoProfile -File $TestScript -Target server
    if ($LASTEXITCODE -eq 0) {
        throw "FAIL: teste falho real nao propagou (verde falso!)"
    }
    Write-Host "Pass: falha real propagada com exit code $LASTEXITCODE"
} finally {
    if (Test-Path $probeTest) { Remove-Item $probeTest -Force }
}

Write-Host "=== TEST 4: Coleta de cobertura (-Coverage) ==="
& $psExe -ExecutionPolicy Bypass -NoProfile -File $TestScript -Coverage
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: tools/test.ps1 -Coverage failed with exit code $LASTEXITCODE"
}
Write-Host "Pass: cobertura coletada e gate NFR-04 satisfeito."

Write-Host "=== TEST 5: Gate de cobertura MORDE quando o minimo nao e atingido (NFR-04) ==="
$probeRunner = Join-Path $RepoRoot "tools/_probe_runner.ps1"
try {
    # 5.1 Prova negativa: gate de cobertura do app reprova threshold impossível
    (Get-Content $TestScript -Raw) -replace '\$globalPct -lt 70', '$globalPct -lt 99.9' |
        Set-Content -Path $probeRunner -Encoding utf8
    & $psExe -ExecutionPolicy Bypass -NoProfile -File $probeRunner -Coverage -Target app
    if ($LASTEXITCODE -eq 0) {
        throw "FAIL: gate de cobertura do app nao falhou com minimo impossivel (99.9%)"
    }
    Write-Host "Pass: gate de cobertura do app reprovou cobertura insuficiente (exit $LASTEXITCODE)"

    # 5.2 Prova negativa (R-03): gate de cobertura do server reprova threshold impossível
    (Get-Content $TestScript -Raw) -replace '\$serverPct -lt 70', '$serverPct -lt 99.9' |
        Set-Content -Path $probeRunner -Encoding utf8
    & $psExe -ExecutionPolicy Bypass -NoProfile -File $probeRunner -Coverage -Target server
    if ($LASTEXITCODE -eq 0) {
        throw "FAIL: gate de cobertura do server nao falhou com minimo impossivel (99.9%)"
    }
    Write-Host "Pass: gate de cobertura do server reprovou cobertura insuficiente (exit $LASTEXITCODE)"
} finally {
    if (Test-Path $probeRunner) { Remove-Item $probeRunner -Force }
}

Write-Host "=== TEST 6: Orcamento NFR-03 MORDE quando excedido ==="
try {
    (Get-Content $TestScript -Raw) -replace '\$coreElapsed -gt 60', '$coreElapsed -gt 0.001' |
        Set-Content -Path $probeRunner -Encoding utf8
    & $psExe -ExecutionPolicy Bypass -NoProfile -File $probeRunner -Target app
    if ($LASTEXITCODE -eq 0) {
        throw "FAIL: orcamento NFR-03 nao falhou com teto impossivel (0.001s)"
    }
    Write-Host "Pass: orcamento NFR-03 reprovou execucao acima do teto (exit $LASTEXITCODE)"
} finally {
    if (Test-Path $probeRunner) { Remove-Item $probeRunner -Force }
}

Write-Host "`n>>> ALL UC-00.03 ACCEPTANCE TESTS PASSED SUCCESSFULLY! <<<"
exit 0
