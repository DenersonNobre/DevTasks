# Test suite for tools/build.ps1 and tools/clean.ps1
# Implements Gherkin acceptance criteria for UC-00.02 (US-0.2.1)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "../..")
Set-Location $RepoRoot

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
& powershell.exe -ExecutionPolicy Bypass -NoProfile -File $BuildScript -PreflightOnly
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: tools/build.ps1 -PreflightOnly failed with exit code $LASTEXITCODE"
}

Write-Host "=== TEST 3: Fail-fast em ambiente quebrado ==="
# Simula ausência do Flutter forçando a falha de preflight
& powershell.exe -ExecutionPolicy Bypass -NoProfile -File $BuildScript -PreflightOnly -SimulateMissingFlutter
if ($LASTEXITCODE -eq 0) {
    throw "FAIL: Expected failure when Flutter is missing, but got exit code 0"
}
Write-Host "Pass: Fail-fast correctly triggered with exit code $LASTEXITCODE"

Write-Host "=== TEST 4: Build idempotente completo ==="
& powershell.exe -ExecutionPolicy Bypass -NoProfile -File $BuildScript
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: tools/build.ps1 failed with exit code $LASTEXITCODE"
}

Write-Host "=== TEST 5: Clean idempotente (2 execuções consecutivas) ==="
& powershell.exe -ExecutionPolicy Bypass -NoProfile -File $CleanScript
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: First run of clean.ps1 failed with exit code $LASTEXITCODE"
}

& powershell.exe -ExecutionPolicy Bypass -NoProfile -File $CleanScript
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: Second run of clean.ps1 failed with exit code $LASTEXITCODE"
}

# Verifica integridade dos fontes após clean
if (-not (Test-Path "solution/app/lib/main.dart") -or -not (Test-Path "solution/server/lib/main.dart")) {
    throw "FAIL: Clean deleted source files!"
}

# Restaura o workspace para as suítes de teste subsequentes
& flutter pub get | Out-Null

Write-Host "`n>>> ALL UC-00.02 ACCEPTANCE TESTS PASSED SUCCESSFULLY! <<<"
exit 0

