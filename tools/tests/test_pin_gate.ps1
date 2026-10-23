# Test suite for tools/pin-gate.ps1
# Implements acceptance criteria and negative proofs for INV-SEC-11 (Pin Gate)
$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "../..")
Set-Location $RepoRoot

$PinGateScript = Join-Path $RepoRoot "tools/pin-gate.ps1"
$psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell.exe" }

Write-Host "=== TEST 1: Verificar existência de tools/pin-gate.ps1 ==="
if (-not (Test-Path $PinGateScript)) {
    throw "RED EXPECTED: tools/pin-gate.ps1 does not exist yet."
}

Write-Host "=== TEST 2: Árvore canônica atual deve passar com exit code 0 ==="
& $psExe -ExecutionPolicy Bypass -NoProfile -File $PinGateScript
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: tools/pin-gate.ps1 falhou na árvore canônica com exit code $LASTEXITCODE"
}
Write-Host "Pass: Árvore canônica aprovada no Pin Gate."

# Cria ambiente temporário para provas negativas
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("devtasks_pingate_" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    $tempPubspec = Join-Path $tempDir "pubspec.yaml"
    $tempLock = Join-Path $tempDir "pubspec.lock"
    Copy-Item (Join-Path $RepoRoot "solution/server/pubspec.yaml") $tempPubspec
    Copy-Item (Join-Path $RepoRoot "pubspec.lock") $tempLock

    Write-Host "`n=== TEST 3 (PROVA NEGATIVA 1): Versão com range (^3.4.13) deve ser REPROVADA (exit 1) ==="
    (Get-Content $tempPubspec -Raw) -replace 'serverpod: 3.4.13', 'serverpod: ^3.4.13' |
        Set-Content -Path $tempPubspec -Encoding utf8
    & $psExe -ExecutionPolicy Bypass -NoProfile -File $PinGateScript -ServerPubspecPath $tempPubspec -LockfilePath $tempLock
    if ($LASTEXITCODE -eq 0) {
        throw "FAIL: Pin gate não reprovou dependência com range (^3.4.13)!"
    }
    Write-Host "Pass: Pin gate reprovou range com exit code $LASTEXITCODE (prova negativa 1 verde)."

    Write-Host "`n=== TEST 4 (PROVA NEGATIVA 2): Divergência no pubspec.lock deve ser REPROVADA (exit 1) ==="
    # Restaura pubspec
    Copy-Item (Join-Path $RepoRoot "solution/server/pubspec.yaml") $tempPubspec -Force
    # Adultera o lockfile
    (Get-Content $tempLock -Raw) -replace 'version: "3.4.13"', 'version: "3.4.14"' |
        Set-Content -Path $tempLock -Encoding utf8
    & $psExe -ExecutionPolicy Bypass -NoProfile -File $PinGateScript -ServerPubspecPath $tempPubspec -LockfilePath $tempLock
    if ($LASTEXITCODE -eq 0) {
        throw "FAIL: Pin gate não reprovou divergência no lockfile!"
    }
    Write-Host "Pass: Pin gate reprovou divergência no lockfile com exit code $LASTEXITCODE (prova negativa 2 verde)."

    Write-Host "`n=== TEST 5 (PROVA NEGATIVA 3): Divergência da versão da Serverpod CLI deve ser REPROVADA (exit 1) ==="
    # Restaura lockfile
    Copy-Item (Join-Path $RepoRoot "pubspec.lock") $tempLock -Force
    & $psExe -ExecutionPolicy Bypass -NoProfile -File $PinGateScript -ServerPubspecPath $tempPubspec -LockfilePath $tempLock -SimulateCliVersion "4.0.4"
    if ($LASTEXITCODE -eq 0) {
        throw "FAIL: Pin gate não reprovou versão divergente da Serverpod CLI (4.0.4 vs 3.4.13)!"
    }
    Write-Host "Pass: Pin gate reprovou CLI divergente com exit code $LASTEXITCODE (prova negativa 3 verde)."
} finally {
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`n>>> ALL INV-SEC-11 ACCEPTANCE TESTS PASSED SUCCESSFULLY! <<<"
exit 0

