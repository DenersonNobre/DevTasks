# Test suite for CI/CD Pipeline & DAG Gate
# Implements Gherkin acceptance criteria for UC-00.06 (US-0.6.1)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "../..")
Set-Location $RepoRoot

$DagGateScript = Join-Path $RepoRoot "tools/dag-gate.ps1"
$GithubWorkflow = Join-Path $RepoRoot ".github/workflows/ci.yml"
$GiteaWorkflow = Join-Path $RepoRoot ".gitea/workflows/ci.yml"

Write-Host "=== TEST 1: Verificar existência dos artefatos de CI/CD e Gate de DAG ==="
if (-not (Test-Path $DagGateScript)) {
    throw "RED EXPECTED: tools/dag-gate.ps1 does not exist yet."
}
if (-not (Test-Path $GithubWorkflow)) {
    throw "RED EXPECTED: .github/workflows/ci.yml does not exist yet."
}
if (-not (Test-Path $GiteaWorkflow)) {
    throw "RED EXPECTED: .gitea/workflows/ci.yml does not exist yet."
}

Write-Host "`n=== TEST 2: Validação da DAG canônica atual (exit 0) ==="
& powershell.exe -ExecutionPolicy Bypass -NoProfile -File $DagGateScript
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: tools/dag-gate.ps1 falhou na DAG atual com exit code $LASTEXITCODE"
}
Write-Host "Pass: DAG atual verificada com sucesso (topologia válida e arquivos íntegros)."

Write-Host "`n=== TEST 3: Violação de Precedência (épico concluído com pré-requisito aberto) deve falhar ==="
$tempPlanFile = [System.IO.Path]::GetTempFileName()
try {
    # Simula violação: EPIC-03 marcado como concluído enquanto EPIC-02 está pendente
    $violatingPlan = @"
# Plan — Simulado

| Épico | Arquivo | Dependências | Prioridade | Status |
|:---|:---|:---|:---:|:---:|
| **00 — Fundação** | [epic-00-fundacao.md](epics/epic-00-fundacao.md) | Nenhuma | Crítica | ✅ Concluído |
| **01 — Autenticação** | [epic-01-autenticacao.md](epics/epic-01-autenticacao.md) | EPIC-00 | Crítica | ✅ Concluído |
| **02 — Workspace** | [epic-02-workspace.md](epics/epic-02-workspace.md) | EPIC-00, EPIC-01 | Alta | ⏳ Pendente |
| **03 — Projetos** | [epic-03-projetos.md](epics/epic-03-projetos.md) | EPIC-02 | Alta | ✅ Concluído |
"@
    Set-Content -Path $tempPlanFile -Value $violatingPlan

    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $dagOut = & powershell.exe -ExecutionPolicy Bypass -NoProfile -File $DagGateScript -PlanFile $tempPlanFile 2>&1 | Out-String
    $dagExit = $LASTEXITCODE
    $ErrorActionPreference = $prevEap

    if ($dagExit -eq 0) {
        throw "FAIL: Expected DAG gate to fail with exit code 1 on precedence violation, but got 0."
    }
    Write-Host "Pass: DAG gate correctly failed with exit code $dagExit on precedence violation."
} finally {
    if (Test-Path $tempPlanFile) {
        Remove-Item $tempPlanFile -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`n=== TEST 4: Paridade dos Workflows (.github e .gitea) ==="
$ghContent = Get-Content $GithubWorkflow -Raw
$giteaContent = Get-Content $GiteaWorkflow -Raw

$requiredTriggers = @("develop", "main")
foreach ($trig in $requiredTriggers) {
    if ($ghContent -notmatch $trig -or $giteaContent -notmatch $trig) {
        throw "FAIL: Workflows devem monitorar branch '$trig'."
    }
}

$requiredSteps = @("flutter pub get", "flutter analyze", "tools/test.ps1", "tools/dag-gate.ps1")
foreach ($step in $requiredSteps) {
    if ($ghContent -notmatch [regex]::Escape($step)) {
        throw "FAIL: .github/workflows/ci.yml ausente do step '$step'."
    }
    if ($giteaContent -notmatch [regex]::Escape($step)) {
        throw "FAIL: .gitea/workflows/ci.yml ausente do step '$step'."
    }
}
Write-Host "Pass: Paridade estrita verificada entre GitHub Actions e Gitea Actions."

Write-Host "`n>>> ALL UC-00.06 ACCEPTANCE TESTS PASSED SUCCESSFULLY! <<<"
exit 0
