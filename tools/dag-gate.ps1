# tools/dag-gate.ps1
# Gate mecânico de verificação de precedência e integridade da DAG de Épicos (F0.6 / UC-00.06)
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$PlanFile
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
Set-Location $RepoRoot

if (-not $PlanFile) {
    $PlanFile = Join-Path $RepoRoot "docs/plan/README.md"
}

if (-not (Test-Path $PlanFile)) {
    Write-Error "[DAG-GATE-FAIL] Arquivo de planejamento não encontrado: $PlanFile"
    exit 1
}

$planDir = Split-Path -Parent $PlanFile
$content = Get-Content -Path $PlanFile

Write-Host "==> [DAG Gate] Analisando precedência e integridade de épicos em: $PlanFile"

$epics = @{}
$fileChecks = @()

# Regex para parsear linhas de tabela de épicos
# Ex: | **00 — Fundação** | [epic-00-fundacao.md](epics/epic-00-fundacao.md) | Nenhuma | Crítica | 🔄 Em execução |
$tableRowPattern = '^\|\s*\*\*(\d{2})[^\*]*\*\*\s*\|\s*\[([^\]]+)\]\(([^)]+)\)\s*\|\s*([^|]+)\|\s*([^|]+)\|\s*([^|]+)\|'

foreach ($line in $content) {
    if ($line -match $tableRowPattern) {
        $epicNum = $Matches[1].Trim()
        $epicId = "EPIC-$epicNum"
        $fileName = $Matches[3].Trim()
        $depsRaw = $Matches[4].Trim()
        $statusRaw = $Matches[6].Trim()

        # Extrai dependências (ex: EPIC-00, EPIC-01 ou 00, 01)
        $deps = @()
        if ($depsRaw -notmatch "Nenhuma" -and $depsRaw -notmatch "-\s*$") {
            $depMatches = [regex]::Matches($depsRaw, "(?:EPIC-)?(\d{2})")
            foreach ($m in $depMatches) {
                $depId = "EPIC-$($m.Groups[1].Value)"
                if ($depId -ne $epicId) {
                    $deps += $depId
                }
            }
        }

        $isDone = ($statusRaw -match "✅" -or $statusRaw -match "Concluído" -or $statusRaw -match "Done")

        $epics[$epicId] = @{
            Id = $epicId
            File = $fileName
            Deps = $deps
            IsDone = $isDone
            Status = $statusRaw
        }

        # Checagem de existência do arquivo físico
        $resolvedFilePath = Join-Path $planDir $fileName
        if (-not (Test-Path $resolvedFilePath)) {
            Write-Error "[DAG-GATE-FAIL] Arquivo do épico $epicId não encontrado no disco: $resolvedFilePath"
            exit 1
        }
    }
}

if ($epics.Count -eq 0) {
    Write-Error "[DAG-GATE-FAIL] Nenhum épico encontrado na tabela de planejamento do arquivo $PlanFile."
    exit 1
}

Write-Host "  Encontrados $($epics.Count) épicos modelados na DAG."

# Validação de Precedência Topológica
$violations = @()

foreach ($kv in $epics.GetEnumerator()) {
    $e = $kv.Value
    if ($e.IsDone) {
        foreach ($depId in $e.Deps) {
            if (-not $epics.ContainsKey($depId)) {
                $violations += "Épico $($e.Id) depende de $depId, que não existe na DAG!"
                continue
            }
            $dep = $epics[$depId]
            if (-not $dep.IsDone) {
                $violations += "VIOLAÇÃO: $($e.Id) está marcado como CONCLUÍDO ($($e.Status)), mas sua dependência prévia $depId está PENDENTE ($($dep.Status))!"
            }
        }
    }
}

if ($violations.Count -gt 0) {
    Write-Error @"
[DAG GATE REPROVADO - PRECEDÊNCIA TOPOLÓGICA VIOLADA]
Foram detectadas violações das regras canônicas da DAG:
$($violations -join "`n")
"@
    exit 1
}

Write-Host "==> [OK] Gate de DAG: topologia válida, todos os arquivos presentes e sem violação de precedência!"
exit 0
