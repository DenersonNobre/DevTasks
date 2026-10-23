# Test suite for tools/build.ps1 and tools/clean.ps1
# Implements Gherkin acceptance criteria for UC-00.02 (US-0.2.1)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "../..")
Set-Location $RepoRoot

$psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell.exe" }
$BuildScript = Join-Path $RepoRoot "tools/build.ps1"
$CleanScript = Join-Path $RepoRoot "tools/clean.ps1"

Write-Host "=== TEST 1: Verificar existência dos scripts ==="
if (-not (Test-Path $BuildScript)) {
    throw "RED EXPECTED: tools/build.ps1 does not exist yet."
}
if (-not (Test-Path $CleanScript)) {
    throw "RED EXPECTED: tools/clean.ps1 does not exist yet."
}

Write-Host "=== TEST 2: Preflight da toolchain (exit 0) ==="
& $psExe -ExecutionPolicy Bypass -NoProfile -File $BuildScript -PreflightOnly
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: tools/build.ps1 -PreflightOnly failed with exit code $LASTEXITCODE"
}

Write-Host "=== TEST 3: Fail-fast REAL em ambiente sem Flutter no PATH (NC-09) ==="
$scrubbedPath = "$env:SystemRoot\System32"
$out = & $psExe -ExecutionPolicy Bypass -NoProfile -Command "`$env:PATH='$scrubbedPath'; & '$BuildScript' -PreflightOnly; exit `$LASTEXITCODE" 2>&1
if ($LASTEXITCODE -eq 0) {
    throw "FAIL: build.ps1 nao falhou com PATH sem Flutter/Dart (fail-fast real nao comprovado)"
}
if (($out | Out-String) -notmatch "FAIL-FAST") {
    throw "FAIL: fail-fast sem a mensagem '[FAIL-FAST]' esperada"
}
Write-Host "Pass: fail-fast real disparado (exit $LASTEXITCODE) com PATH sem Flutter/Dart"

Write-Host "=== TEST 3.1: Fail-fast REAL em caso de CLI Serverpod divergente do pin (INV-SEC-11) ==="
$mismatchOut = & $psExe -ExecutionPolicy Bypass -NoProfile -File $BuildScript -PreflightOnly -SimulateServerpodCliVersion "4.0.4" 2>&1
if ($LASTEXITCODE -eq 0) {
    throw "FAIL: build.ps1 nao falhou com versao divergente do Serverpod CLI!"
}
if (($mismatchOut | Out-String) -notmatch "FAIL-FAST") {
    throw "FAIL: fail-fast de versao sem a mensagem '[FAIL-FAST]' esperada"
}
Write-Host "Pass: fail-fast real de versao do Serverpod CLI disparado (exit $LASTEXITCODE)"

Write-Host "=== TEST 4: Build idempotente completo + artefato esperado (NC-10) ==="
& $psExe -ExecutionPolicy Bypass -NoProfile -File $BuildScript -SkipClientGen
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: tools/build.ps1 failed with exit code $LASTEXITCODE"
}
$artifact = Join-Path $RepoRoot "solution/builds/devtasks-server.exe"
if (-not (Test-Path $artifact)) {
    throw "FAIL: artefato esperado ausente apos o build: solution/builds/devtasks-server.exe"
}
if ((Get-Item $artifact).Length -le 0) {
    throw "FAIL: artefato gerado esta vazio"
}
Write-Host "Pass: build produziu o artefato esperado ($([Math]::Round((Get-Item $artifact).Length / 1MB, 2)) MB)"

Write-Host "=== TEST 5: Clean idempotente (2 execuções consecutivas) ==="
$backupTool = Join-Path ([System.IO.Path]::GetTempPath()) ("devtasks_darttool_" + [System.Guid]::NewGuid().ToString("N"))
if (Test-Path ".dart_tool") {
    Copy-Item ".dart_tool" $backupTool -Recurse -Force
}
try {
    & $psExe -ExecutionPolicy Bypass -NoProfile -File $CleanScript
    if ($LASTEXITCODE -ne 0) {
        throw "FAIL: First run of clean.ps1 failed with exit code $LASTEXITCODE"
    }

    & $psExe -ExecutionPolicy Bypass -NoProfile -File $CleanScript
    if ($LASTEXITCODE -ne 0) {
        throw "FAIL: Second run of clean.ps1 failed with exit code $LASTEXITCODE"
    }

    # Verifica integridade dos fontes após clean
    if (-not (Test-Path "solution/app/lib/main.dart") -or -not (Test-Path "solution/server/lib/main.dart")) {
        throw "FAIL: Clean deleted source files!"
    }
} finally {
    if (Test-Path $backupTool) {
        Copy-Item $backupTool ".dart_tool" -Recurse -Force
        Remove-Item $backupTool -Recurse -Force -ErrorAction SilentlyContinue
    }
    & flutter pub get | Out-Null
}

Write-Host "`n>>> ALL UC-00.02 ACCEPTANCE TESTS PASSED SUCCESSFULLY! <<<"
exit 0
