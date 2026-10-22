# tools/hooks/commit-msg.ps1
# Hook de validação de Conventional Commits, D-04 de branches e Poka-Yoke de Claims (F0.4)
[CmdletBinding()]
param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$MsgFile,

    [Parameter(Position=1, Mandatory=$false)]
    [string]$SimulatedBranch
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "../..")
$ClaimsScript = Join-Path $RepoRoot "tools/bin/claims.ps1"

if (-not (Test-Path $MsgFile)) {
    Write-Error "[HOOK-ERROR] Arquivo de mensagem de commit não encontrado: $MsgFile"
    exit 1
}

$rawMsg = (Get-Content -Path $MsgFile -Raw).Trim()
# Primeira linha é o assunto do commit
$subject = ($rawMsg -split "`r?`n")[0].Trim()

# 1. Validação de Conventional Commits
$conventionalPattern = "^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-zA-Z0-9_\-\.\/]+\))?:\s+.+"
if ($subject -notmatch $conventionalPattern) {
    Write-Error @"
[CONVENTIONAL COMMIT REJEITADO]
A mensagem de commit não atende ao padrão Conventional Commits.
Assunto: '$subject'

Formato exigido:
  <type>(<scope>): <assunto imperativo em inglês> (UC-XX.YY)

Tipos permitidos: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert.
Exemplo:
  chore(git): add claims shims and commit-msg hook (UC-00.04)
"@
    exit 1
}

# 2. Verificação de Caso de Uso e Poka-Yoke
if ($subject -match "\((UC-\d{2}\.\d{2})\)") {
    $slice = $Matches[1]

    # Obtenção da branch
    $branch = $SimulatedBranch
    if (-not $branch) {
        $branch = (& git branch --show-current 2>$null).Trim()
    }

    # Regra D-04: Commits de Caso de Uso DEVEM ser feitos no branch 'develop'
    if ($branch -ne "develop") {
        Write-Error @"
[POKA-YOKE D-04 VIOLATION]
Commits de Caso de Uso assinados com '($slice)' só são permitidos no branch 'develop'.
Branch atual: '$branch'

Para cumprir a política D-04:
1. Mude para o branch develop: git checkout develop
2. Reaplique o commit
(A branch 'main' é reservada exclusivamente para releases consolidadas).
"@
        exit 1
    }

    # Regra de Claims: O slice DEVE possuir claim ativo
    & powershell.exe -ExecutionPolicy Bypass -NoProfile -File $ClaimsScript check -slice $slice | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error @"
[POKA-YOKE CLAIM GATE]
Nenhum claim ativo encontrado para o slice '$slice'.
Commits com assinatura '(UC-XX.YY)' exigem claim prévio para garantir a disciplina de concorrência.

Obtenha o claim antes de commitar:
  powershell.exe -ExecutionPolicy Bypass -File tools/bin/claims.ps1 claim -slice $slice -owner <seu-papel>
Exemplo:
  tools/bin/claims.cmd claim -slice $slice -owner coder
"@
        exit 1
    }
}

exit 0
