# tools/doc-gate.ps1
# Gate mecânico de conformidade documental e governança viva (F0.8 / UC-00.08)
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$HandoffFile,

    [Parameter(Mandatory=$false)]
    [string]$CheckpointFile,

    [Parameter(Mandatory=$false)]
    [string]$PlanFile
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
Set-Location $RepoRoot

if (-not $HandoffFile) {
    $HandoffFile = Join-Path $RepoRoot "docs/plan/state/UC-CURRENT.md"
}
if (-not $CheckpointFile) {
    $CheckpointFile = Join-Path $RepoRoot "CHECKPOINT.md"
}
if (-not $PlanFile) {
    $PlanFile = Join-Path $RepoRoot "docs/plan/README.md"
}

Write-Host "==> [Doc Gate] Verificando conformidade documental..."

# 1. Validação de Hand-off (UC-CURRENT.md)
if (Test-Path $HandoffFile) {
    $handoffContent = Get-Content -Path $HandoffFile -Raw
    if ($handoffContent -notmatch "(?m)^(\*\*|\#\#)?\s*Gate\s+2\.5:") {
        Write-Error @"
[DOC-GATE-FAIL] O arquivo de hand-off ($HandoffFile) NÃO contém a declaração obrigatória 'Gate 2.5:'.
Todo UC deve documentar se o Gate 2.5 (Segurança/Superfície Sensível) foi AVALIADO ou PULADO.
"@
        exit 1
    }
    Write-Host "  [OK] Hand-off ($HandoffFile): linha 'Gate 2.5:' presente e formalizada."
} else {
    Write-Host "  [INFO] Arquivo de hand-off ($HandoffFile) ausente no momento."
}

# 2. Validação do CHECKPOINT.md (Orçamento de linhas INV-STATE-02: <= 60 linhas)
if (Test-Path $CheckpointFile) {
    $cpLines = @(Get-Content -Path $CheckpointFile).Count
    if ($cpLines -gt 60) {
        Write-Error @"
[DOC-GATE-FAIL] CHECKPOINT.md excedeu o orçamento estrito de 60 linhas (INV-STATE-02).
Linhas atuais: $cpLines (máximo permitido: 60).
Elimine duplicações e mantenha apenas os ponteiros essenciais e o estado verificado.
"@
        exit 1
    }
    Write-Host "  [OK] CHECKPOINT.md: $cpLines linhas (dentro do limite de <= 60 linhas)."
} else {
    Write-Host "  [INFO] CHECKPOINT.md ausente no momento."
}

# 3. Execução do Gate de DAG
$dagGateScript = Join-Path $ScriptDir "dag-gate.ps1"
if (Test-Path $dagGateScript) {
    Write-Host "`n--> Acoplando verificação com o Gate de DAG..."
    $psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell.exe" }
    & $psExe -ExecutionPolicy Bypass -NoProfile -File $dagGateScript -PlanFile $PlanFile
    if ($LASTEXITCODE -ne 0) {
        Write-Error "[DOC-GATE-FAIL] Falha no Gate de DAG."
        exit $LASTEXITCODE
    }
}

Write-Host "`n==> [OK] Governança documental 100% aprovada!"
exit 0
