# Test suite for Git Governance, VCS, Hooks & Claims
# Implements Gherkin acceptance criteria for UC-00.04 (US-0.4.1)

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "../..")
Set-Location $RepoRoot

$psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell.exe" }
$ClaimsScript = Join-Path $RepoRoot "tools/bin/claims.ps1"
$HookScript = Join-Path $RepoRoot "tools/hooks/commit-msg.ps1"
$HookShell = Join-Path $RepoRoot "tools/hooks/commit-msg"

Write-Host "=== TEST 1: Verificar existência dos artefatos de governança ==="
if (-not (Test-Path $ClaimsScript)) {
    throw "RED EXPECTED: tools/bin/claims.ps1 does not exist yet."
}
if (-not (Test-Path $HookScript)) {
    throw "RED EXPECTED: tools/hooks/commit-msg.ps1 does not exist yet."
}
if (-not (Test-Path $HookShell)) {
    throw "RED EXPECTED: tools/hooks/commit-msg does not exist yet."
}

# Cria arquivo temporário de mensagem de commit
$tempMsgFile = [System.IO.Path]::GetTempFileName()

try {
    Write-Host "`n=== TEST 2: Cenário 1 - Commit de UC sem claim deve ser BLOQUEADO (exit 1) ==="
    # Garante que não há claim ativo para UC-99.99
    & $psExe -ExecutionPolicy Bypass -NoProfile -File $ClaimsScript release -slice "UC-99.99" | Out-Null

    Set-Content -Path $tempMsgFile -Value "feat(test): invalid unsigned commit (UC-99.99)"
    $hookOutput = & $psExe -ExecutionPolicy Bypass -NoProfile -File $HookScript $tempMsgFile "develop" 2>&1 | Out-String
    $hookExit = $LASTEXITCODE

    if ($hookExit -eq 0) {
        throw "FAIL: Expected hook to block commit without active claim, but it returned exit code 0."
    }
    Write-Host "Pass: Hook correctly blocked commit without claim with exit code $hookExit."
    Write-Host "Hook feedback: $hookOutput"

    Write-Host "`n=== TEST 3: Ativação de claim e aprovação de commit ==="
    & $psExe -ExecutionPolicy Bypass -NoProfile -File $ClaimsScript claim -slice "UC-99.99" -owner "test-runner"
    if ($LASTEXITCODE -ne 0) {
        throw "FAIL: Failed to create claim for UC-99.99"
    }

    $hookOutput2 = & $psExe -ExecutionPolicy Bypass -NoProfile -File $HookScript $tempMsgFile "develop" 2>&1 | Out-String
    $hookExit2 = $LASTEXITCODE
    if ($hookExit2 -ne 0) {
        throw "FAIL: Expected hook to accept commit with active claim on develop, but got exit code ${hookExit2}: $hookOutput2"
    }
    Write-Host "Pass: Hook approved commit with active claim on develop."

    Write-Host "`n=== TEST 4: Poka-Yoke D-04 - Bloqueio de commit de UC fora de 'develop' ==="
    # Tenta validar o mesmo commit simulando branch 'main' ou 'feature/teste'
    $hookOutput3 = & $psExe -ExecutionPolicy Bypass -NoProfile -File $HookScript $tempMsgFile "main" 2>&1 | Out-String
    $hookExit3 = $LASTEXITCODE
    if ($hookExit3 -eq 0) {
        throw "FAIL: Expected hook to block UC commit on branch 'main' (D-04 violation), but got exit 0."
    }
    Write-Host "Pass: Hook correctly blocked UC commit on branch 'main' with exit code $hookExit3 (D-04 enforced)."

    Write-Host "`n=== TEST 5: Cenário 2 - Commit documental sem assinatura de UC passa sem claim ==="
    Set-Content -Path $tempMsgFile -Value "docs(readme): update general documentation without uc tag"
    $hookOutput4 = & $psExe -ExecutionPolicy Bypass -NoProfile -File $HookScript $tempMsgFile "develop" 2>&1 | Out-String
    $hookExit4 = $LASTEXITCODE
    if ($hookExit4 -ne 0) {
        throw "FAIL: Expected hook to accept general commit without UC tag, but got exit code $hookExit4"
    }
    Write-Host "Pass: General commit without UC tag passed claim-gate cleanly."

    Write-Host "`n=== TEST 6: Liberação de claim ==="
    & $psExe -ExecutionPolicy Bypass -NoProfile -File $ClaimsScript release -slice "UC-99.99"
    if ($LASTEXITCODE -ne 0) {
        throw "FAIL: Failed to release claim for UC-99.99"
    }

    $checkExit = & $psExe -ExecutionPolicy Bypass -NoProfile -File $ClaimsScript check -slice "UC-99.99"
    if ($LASTEXITCODE -eq 0) {
        throw "FAIL: Claim check should return non-zero after release, but got 0"
    }
    Write-Host "Pass: Claim released and verified inactive."

} finally {
    if (Test-Path $tempMsgFile) {
        Remove-Item $tempMsgFile -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`n>>> ALL UC-00.04 ACCEPTANCE TESTS PASSED SUCCESSFULLY! <<<"
exit 0
