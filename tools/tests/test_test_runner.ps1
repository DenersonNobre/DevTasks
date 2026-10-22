# Test suite for tools/test.ps1
# Implements Gherkin acceptance criteria for UC-00.03 (US-0.3.1)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "../..")
Set-Location $RepoRoot

$TestScript = Join-Path $RepoRoot "tools/test.ps1"

Write-Host "=== TEST 1: Verificar existência de tools/test.ps1 ==="
if (-not (Test-Path $TestScript)) {
    throw "RED EXPECTED: tools/test.ps1 does not exist yet."
}

Write-Host "=== TEST 2: Suíte verde em um comando (exit 0) ==="
$psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell.exe" }
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
& $psExe -ExecutionPolicy Bypass -NoProfile -File $TestScript
$elapsed = $stopwatch.Elapsed.TotalSeconds
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: tools/test.ps1 failed with exit code $LASTEXITCODE"
}
$maxTime = if ($env:CI -eq "true") { 60 } else { 120 }
if ($elapsed -gt $maxTime) {
    throw "FAIL: tools/test.ps1 exceeded limit (NFR-03: ${maxTime}s). Took: $elapsed s"
}
Write-Host "Pass: Test runner completed successfully in $elapsed s (<= ${maxTime}s)"

Write-Host "=== TEST 3: Falha propagada (nunca verde falso) ==="
& $psExe -ExecutionPolicy Bypass -NoProfile -File $TestScript -SimulateFailure
if ($LASTEXITCODE -eq 0) {
    throw "FAIL: Expected failure exit code when a test fails, but got 0 (false green!)"
}
Write-Host "Pass: Failure correctly propagated with exit code $LASTEXITCODE"

Write-Host "=== TEST 4: Coleta de cobertura (-Coverage) ==="
& $psExe -ExecutionPolicy Bypass -NoProfile -File $TestScript -Coverage
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: tools/test.ps1 -Coverage failed with exit code $LASTEXITCODE"
}

Write-Host "`n>>> ALL UC-00.03 ACCEPTANCE TESTS PASSED SUCCESSFULLY! <<<"
exit 0

