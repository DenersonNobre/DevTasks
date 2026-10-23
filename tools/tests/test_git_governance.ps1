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

    Write-Host "`n=== TEST 7: Ativação de claim com parâmetro -Paths e validação de schema ==="
    $testSlice = "UC-99.98"
    & $psExe -ExecutionPolicy Bypass -NoProfile -File $ClaimsScript release -slice $testSlice | Out-Null
    & $psExe -ExecutionPolicy Bypass -NoProfile -File $ClaimsScript claim -slice $testSlice -owner "test-runner" -paths "solution/server/lib/src/test.dart,solution/client/lib/src/protocol.dart"
    if ($LASTEXITCODE -ne 0) {
        throw "FAIL: Failed to create claim with -Paths for $testSlice"
    }

    $claimFile = Join-Path $RepoRoot ".git/claims/$testSlice.json"
    if (-not (Test-Path $claimFile)) {
        throw "FAIL: Expected claim file $claimFile to exist."
    }
    $claimJson = Get-Content -Raw -Path $claimFile -Encoding UTF8 | ConvertFrom-Json
    if ($claimJson.schema -ne "claims/v1") {
        throw "FAIL: Expected schema 'claims/v1', got '$($claimJson.schema)'"
    }
    if ($null -eq $claimJson.paths -or $claimJson.paths.Count -ne 2) {
        throw "FAIL: Expected 2 paths in claim json, got '$($claimJson.paths)'"
    }
    if ($claimJson.paths[0] -ne "solution/server/lib/src/test.dart" -or $claimJson.paths[1] -ne "solution/client/lib/src/protocol.dart") {
        throw "FAIL: Paths array content does not match expected paths."
    }
    Write-Host "Pass: Claim created with -Paths and validated against canonical schema."
    & $psExe -ExecutionPolicy Bypass -NoProfile -File $ClaimsScript release -slice $testSlice | Out-Null

    Write-Host "`n=== TEST 8: Suporte ao override de diretório por CLAIMS_DIR ==="
    $customClaimsDir = Join-Path ([System.IO.Path]::GetTempPath()) ("devtasks_claims_" + [System.Guid]::NewGuid().ToString("N"))
    try {
        $env:CLAIMS_DIR = $customClaimsDir
        $customSlice = "UC-99.97"
        & $psExe -ExecutionPolicy Bypass -NoProfile -File $ClaimsScript claim -slice $customSlice -owner "env-tester"
        if ($LASTEXITCODE -ne 0) {
            throw "FAIL: Failed to create claim with CLAIMS_DIR set."
        }

        $customClaimFile = Join-Path $customClaimsDir "$customSlice.json"
        $standardClaimFile = Join-Path $RepoRoot ".git/claims/$customSlice.json"

        if (-not (Test-Path $customClaimFile)) {
            throw "FAIL: Expected claim to be written into CLAIMS_DIR ($customClaimsDir), but file was not found."
        }
        if (Test-Path $standardClaimFile) {
            throw "FAIL: Claim should NOT have been written to standard .git/claims when CLAIMS_DIR is set."
        }

        & $psExe -ExecutionPolicy Bypass -NoProfile -File $ClaimsScript check -slice $customSlice
        if ($LASTEXITCODE -ne 0) {
            throw "FAIL: claims check failed to locate claim inside CLAIMS_DIR."
        }
        Write-Host "Pass: CLAIMS_DIR environment variable correctly overrides storage directory."
    } finally {
        $env:CLAIMS_DIR = $null
        if (Test-Path $customClaimsDir) {
            Remove-Item -Path $customClaimsDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Host "`n=== TEST 9: Ação claims reap (-DryRun, -Force e prova negativa de ativos) ==="
    $activeSlice = "UC-99.96"
    $expiredSlice = "UC-99.95"

    # 1. Garante estado limpo
    & $psExe -ExecutionPolicy Bypass -NoProfile -File $ClaimsScript release -slice $activeSlice | Out-Null
    & $psExe -ExecutionPolicy Bypass -NoProfile -File $ClaimsScript release -slice $expiredSlice | Out-Null

    # 2. Cria claim ativo (fresco)
    & $psExe -ExecutionPolicy Bypass -NoProfile -File $ClaimsScript claim -slice $activeSlice -owner "active-runner" -ttl 60
    if ($LASTEXITCODE -ne 0) {
        throw "FAIL: Failed to create active claim $activeSlice"
    }

    # 3. Cria claim expirado diretamente
    $expiredFile = Join-Path $RepoRoot ".git/claims/$expiredSlice.json"
    $expiredData = @{
        schema = "claims/v1"
        slice = $expiredSlice
        owner = "ghost-runner"
        pid = 99999
        claimed_at = "2026-01-01T00:00:00.000Z"
        expires_at = "2026-01-01T01:00:00.000Z"
        ttl_minutes = 60
        status = "active"
    }
    [System.IO.File]::WriteAllText($expiredFile, ($expiredData | ConvertTo-Json), [System.Text.Encoding]::UTF8)

    # 4. Executa reap com -DryRun: NÃO deve remover arquivos
    $dryRunOutput = & $psExe -ExecutionPolicy Bypass -NoProfile -File $ClaimsScript reap -DryRun 2>&1 | Out-String
    if (-not (Test-Path $expiredFile)) {
        throw "FAIL: reap -DryRun deleted expired claim file! DryRun must be read-only."
    }
    if ($dryRunOutput -notmatch $expiredSlice) {
        throw "FAIL: reap -DryRun output did not mention expired slice ${expiredSlice}: $dryRunOutput"
    }
    Write-Host "Pass: reap -DryRun listed expired slice without deleting."

    # 5. Executa reap com -Force: DEVE remover apenas o expirado
    $activeFile = Join-Path $RepoRoot ".git/claims/$activeSlice.json"
    & $psExe -ExecutionPolicy Bypass -NoProfile -File $ClaimsScript reap -Force | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "FAIL: claims reap -Force failed."
    }

    if (Test-Path $expiredFile) {
        throw "FAIL: claims reap -Force did not remove expired claim file $expiredFile."
    }
    # PROVA NEGATIVA: O claim ativo NÃO PODE ter sido removido!
    if (-not (Test-Path $activeFile)) {
        throw "FAIL: PROVA NEGATIVA VIOLADA: claims reap -Force removeu indevidamente o claim ativo $activeSlice!"
    }
    Write-Host "Pass: claims reap -Force removed expired claim and preserved active claim (prova negativa verde)."

    # Limpeza
    & $psExe -ExecutionPolicy Bypass -NoProfile -File $ClaimsScript release -slice $activeSlice | Out-Null

} finally {
    if (Test-Path $tempMsgFile) {
        Remove-Item $tempMsgFile -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`n>>> ALL UC-00.04 ACCEPTANCE TESTS PASSED SUCCESSFULLY! <<<"
exit 0
