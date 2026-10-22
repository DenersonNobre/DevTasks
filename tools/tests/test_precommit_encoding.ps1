# Test suite for tools/hooks/pre-commit.ps1 (encoding)
# Provas negativas reais (NC-13): U+FFFD e BOM-only reprovam; arquivo limpo passa.

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "../..")
Set-Location $RepoRoot

$Hook = Join-Path $RepoRoot "tools/hooks/pre-commit.ps1"
$probe = Join-Path $RepoRoot "tools/_encoding_probe.txt"
$psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell.exe" }

function Invoke-Hook {
    & $psExe -ExecutionPolicy Bypass -NoProfile -File $Hook | Out-Null
    return $LASTEXITCODE
}

Write-Host "=== TEST 1: Hook versionado existe e o INSTALADOR o instala ==="
if (-not (Test-Path $Hook)) { throw "RED EXPECTED: tools/hooks/pre-commit.ps1 does not exist yet." }

$installer = Join-Path $RepoRoot "tools/install-hooks.ps1"
if (-not (Test-Path $installer)) { throw "FAIL: tools/install-hooks.ps1 ausente." }

& $psExe -ExecutionPolicy Bypass -NoProfile -File $installer | Out-Null
if ($LASTEXITCODE -ne 0) { throw "FAIL: tools/install-hooks.ps1 falhou (exit $LASTEXITCODE)." }

$installedHook = Join-Path $RepoRoot ".git/hooks/pre-commit"
if (-not (Test-Path $installedHook)) {
    throw "FAIL: install-hooks.ps1 nao instalou .git/hooks/pre-commit."
}
if ((& git config core.hooksPath) -ne "tools/hooks") {
    throw "FAIL: core.hooksPath nao aponta para tools/hooks."
}
Write-Host "Pass: hook instalado por tools/install-hooks.ps1 e core.hooksPath configurado."

try {
    Write-Host "=== TEST 2: Arquivo limpo (UTF-8) passa ==="
    Set-Content -Path $probe -Value "texto limpo sem contaminacao" -Encoding utf8
    & git add -- $probe
    $code = Invoke-Hook
    if ($code -ne 0) { throw "FAIL: hook reprovou arquivo limpo (exit $code)." }
    Write-Host "Pass: arquivo limpo aprovado."

    Write-Host "=== TEST 3: U+FFFD (encoding duplo) reprova ==="
    [System.IO.File]::WriteAllText($probe, "texto corrompido $([char]0xFFFD) aqui", [System.Text.UTF8Encoding]::new($false))
    & git add -- $probe
    $code = Invoke-Hook
    if ($code -eq 0) { throw "FAIL: hook nao reprovou U+FFFD (verde falso!)." }
    Write-Host "Pass: U+FFFD reprovado (exit $code)."

    Write-Host "=== TEST 4: Contaminacao CJK reprova ==="
    [System.IO.File]::WriteAllText($probe, "texto com ideograma $([char]0x4E2D) no meio", [System.Text.UTF8Encoding]::new($false))
    & git add -- $probe
    $code = Invoke-Hook
    if ($code -eq 0) { throw "FAIL: hook nao reprovou contaminacao CJK." }
    Write-Host "Pass: CJK reprovado (exit $code)."

    Write-Host "=== TEST 5: Arquivo truncado (apenas BOM) reprova ==="
    [System.IO.File]::WriteAllBytes($probe, [byte[]](0xEF, 0xBB, 0xBF))
    & git add -- $probe
    $code = Invoke-Hook
    if ($code -eq 0) { throw "FAIL: hook nao reprovou arquivo truncado (apenas BOM)." }
    Write-Host "Pass: arquivo truncado reprovado (exit $code)."
} finally {
    & git restore --staged -- $probe 2>$null
    if (Test-Path $probe) { Remove-Item $probe -Force }
}

Write-Host "`n>>> ALL UC-00.04 PRECOMMIT ENCODING TESTS PASSED SUCCESSFULLY! <<<"
exit 0
