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

Write-Host "=== TEST 1: Hook de pre-commit existe e esta instalado ==="
if (-not (Test-Path $Hook)) { throw "RED EXPECTED: tools/hooks/pre-commit.ps1 does not exist yet." }
if (-not (Test-Path (Join-Path $RepoRoot ".git/hooks/pre-commit"))) {
    throw "FAIL: .git/hooks/pre-commit nao instalado (rode tools/install-hooks.ps1)."
}

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
