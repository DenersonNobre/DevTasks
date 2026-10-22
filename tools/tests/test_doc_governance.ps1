# Test suite for Document Governance & State Matrix
# Implements Gherkin acceptance criteria for UC-00.08 (US-0.8.1)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "../..")
Set-Location $RepoRoot

$psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell.exe" }
$DocGateScript = Join-Path $RepoRoot "tools/doc-gate.ps1"
$ClaimsDoc = Join-Path $RepoRoot "docs/plan/state/CLAIMS.md"
$LicenseFile = Join-Path $RepoRoot "LICENSE"
$ChangelogFile = Join-Path $RepoRoot "CHANGELOG.md"

Write-Host "=== TEST 1: Verificar existência dos artefatos de governança documental ==="
if (-not (Test-Path $DocGateScript)) {
    throw "RED EXPECTED: tools/doc-gate.ps1 does not exist yet."
}
if (-not (Test-Path $ClaimsDoc)) {
    throw "RED EXPECTED: docs/plan/state/CLAIMS.md does not exist yet."
}
if (-not (Test-Path $LicenseFile)) {
    throw "RED EXPECTED: LICENSE does not exist yet."
}
if (-not (Test-Path $ChangelogFile)) {
    throw "RED EXPECTED: CHANGELOG.md does not exist yet."
}

Write-Host "`n=== TEST 2: Validação documental canônica atual (exit 0) ==="
& $psExe -ExecutionPolicy Bypass -NoProfile -File $DocGateScript
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: tools/doc-gate.ps1 falhou na verificação atual com exit code $LASTEXITCODE"
}
Write-Host "Pass: Governança documental atual verificada com sucesso."

Write-Host "`n=== TEST 3: Reprovação de hand-off sem linha 'Gate 2.5:' ==="
$tempHandoff = [System.IO.Path]::GetTempFileName()
try {
    $invalidHandoff = @"
# UC-CURRENT — Invalido
## UC corrente
**UC-99.99** — Teste sem gate
## Interfaces
Nenhuma
"@
    Set-Content -Path $tempHandoff -Value $invalidHandoff

    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $gateOut = & $psExe -ExecutionPolicy Bypass -NoProfile -File $DocGateScript -HandoffFile $tempHandoff 2>&1 | Out-String
    $gateExit = $LASTEXITCODE
    $ErrorActionPreference = $prevEap

    if ($gateExit -eq 0) {
        throw "FAIL: Expected doc gate to fail with exit code 1 when 'Gate 2.5:' is missing, but got 0."
    }
    Write-Host "Pass: Doc gate correctly rejected hand-off without 'Gate 2.5:' (exit code $gateExit)."
} finally {
    if (Test-Path $tempHandoff) {
        Remove-Item $tempHandoff -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`n=== TEST 4: Reprovação de CHECKPOINT.md > 60 linhas (INV-STATE-02) ==="
$tempCheckpoint = [System.IO.Path]::GetTempFileName()
try {
    $tooManyLines = (1..65 | ForEach-Object { "Linha $_ de texto repetitivo" }) -join "`r`n"
    Set-Content -Path $tempCheckpoint -Value $tooManyLines

    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $gateOut2 = & $psExe -ExecutionPolicy Bypass -NoProfile -File $DocGateScript -CheckpointFile $tempCheckpoint 2>&1 | Out-String
    $gateExit2 = $LASTEXITCODE
    $ErrorActionPreference = $prevEap

    if ($gateExit2 -eq 0) {
        throw "FAIL: Expected doc gate to fail when CHECKPOINT.md exceeds 60 lines, but got 0."
    }
    Write-Host "Pass: Doc gate correctly enforced checkpoint line budget (<= 60 lines)."
} finally {
    if (Test-Path $tempCheckpoint) {
        Remove-Item $tempCheckpoint -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`n>>> ALL UC-00.08 ACCEPTANCE TESTS PASSED SUCCESSFULLY! <<<"
exit 0
