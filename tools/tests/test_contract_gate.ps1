# tools/tests/test_contract_gate.ps1
# Test suite for Contract Gate (D-08 / UC-08.06 / F8.6)
# Valida paridade de rotas OpenAPI e provas negativas automatizadas.

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "../..")
Set-Location $RepoRoot

$psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell.exe" }
$GateScript = Join-Path $RepoRoot "tools/contract-gate.ps1"

Write-Host "=== TEST 1: Verificar existência de tools/contract-gate.ps1 ==="
if (-not (Test-Path $GateScript)) {
    throw "FAIL: tools/contract-gate.ps1 não existe."
}
Write-Host "Pass: Script do Contract Gate encontrado."

Write-Host "`n=== TEST 2: Validação da base canônica atual (exit 0) ==="
& $psExe -ExecutionPolicy Bypass -NoProfile -File $GateScript
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: Contract Gate falhou na base canônica (exit code $LASTEXITCODE)."
}
Write-Host "Pass: Contrato e código 100% aderentes."

Write-Host "`n=== TEST 3: Prova Negativa - Simulação de falha explícita deve falhar (exit 1) ==="
$prevEap = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$negOut = & $psExe -ExecutionPolicy Bypass -NoProfile -File $GateScript -SimulateFailure 2>&1 | Out-String
$negCode = $LASTEXITCODE
$ErrorActionPreference = $prevEap

if ($negCode -eq 0) {
    throw "FAIL: Contract Gate aceitou execução com -SimulateFailure (exit code 0)."
}
Write-Host "Pass: Prova negativa bloqueada com exit code $negCode."

Write-Host "`n=== TODOS OS TESTES DO CONTRACT GATE PASSARAM COM SUCESSO ==="
exit 0

