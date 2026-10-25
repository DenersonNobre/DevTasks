# tools/tests/test_db_gate.ps1
# Prova do gate de integração de banco (achado B-2 do laudo de auditoria da API).
#
# Prova negativa (sempre roda, sem banco): `tools/test.ps1 -Database` SEM
# DEVTASKS_TEST_DATABASE_URL precisa FALHAR. Sem isso, o modo DB viraria
# "verde" com zero SQL executado — exatamente o defeito que o gate existe
# para impedir.
#
# Prova positiva (condicional): com a variável definida, `-Database` precisa passar.
# Roda quando o ambiente tem banco, inclusive no job de CI dedicado.

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "../..")
Set-Location $RepoRoot

$TestScript = Join-Path $RepoRoot "tools/test.ps1"
$psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell.exe" }

Write-Host "=== TEST 1: o modo -Database existe e recusa rodar sem DSN ==="
if (-not (Test-Path $TestScript)) { throw "RED: tools/test.ps1 ausente." }

$saved = [Environment]::GetEnvironmentVariable('DEVTASKS_TEST_DATABASE_URL')
try {
    [Environment]::SetEnvironmentVariable('DEVTASKS_TEST_DATABASE_URL', $null)
    $out = & $psExe -ExecutionPolicy Bypass -NoProfile -File $TestScript -Database 2>&1 | Out-String
    $code = $LASTEXITCODE

    if ($code -eq 0) {
        throw "FAIL: '-Database' passou sem DEVTASKS_TEST_DATABASE_URL (gate inoperante: testes de integração seriam pulados em silêncio)."
    }
    if ($out -notmatch 'DEVTASKS_TEST_DATABASE_URL') {
        throw "FAIL: a falha não cita DEVTASKS_TEST_DATABASE_URL. Saída:`n$out"
    }
    if ($out -notmatch 'DB-GATE-FAIL') {
        throw "FAIL: falha sem o código canônico DB-GATE-FAIL. Saída:`n$out"
    }
    Write-Host "Pass: '-Database' falhou sem DSN (exit $code) com mensagem acionável."
} finally {
    [Environment]::SetEnvironmentVariable('DEVTASKS_TEST_DATABASE_URL', $saved)
}

Write-Host "=== TEST 2: -Unit continua funcionando (o gate não contaminou os outros modos) ==="
& $psExe -ExecutionPolicy Bypass -NoProfile -File $TestScript -Unit -Target api -NoPub | Out-Null
$unitCode = $LASTEXITCODE
if ($unitCode -ne 0) { throw "FAIL: '-Unit' regrediu (exit $unitCode)." }
Write-Host "Pass: '-Unit' continua saindo 0 sem banco."

Write-Host "=== TEST 3: prova positiva (só quando há banco no ambiente) ==="
$dsn = [Environment]::GetEnvironmentVariable('DEVTASKS_TEST_DATABASE_URL')
if ([string]::IsNullOrWhiteSpace($dsn)) {
    Write-Host "  [SKIP] sem DEVTASKS_TEST_DATABASE_URL: a prova positiva roda no job de CI de banco."
    Write-Host "=== DB GATE: provas concluídas (negativa executada) ==="
    exit 0
}

Write-Host "  DSN presente: executando a suíte de integração real..."
& $psExe -ExecutionPolicy Bypass -NoProfile -File $TestScript -Database -NoPub
if ($LASTEXITCODE -ne 0) { throw "FAIL: '-Database' falhou com DSN válido (exit $LASTEXITCODE)." }
Write-Host "=== DB GATE: provas concluídas (negativa + positiva) ==="
exit 0
