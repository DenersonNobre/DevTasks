# tools/hooks/commit-msg.ps1
# Poka-yoke de validação da mensagem de commit (F0.4 / UC-00.04)
# Valida: Conventional Commits + Tag canônica (UC-XX.YY) + Claim Ativo + Política D-04
param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$CommitMsgFile,

    [Parameter(Position=1, Mandatory=$false)]
    [string]$CurrentBranch = ""
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $CommitMsgFile)) {
    Write-Error "[HOOK-ERROR] Arquivo de mensagem de commit não encontrado: $CommitMsgFile"
    exit 1
}

$commitMsg = (Get-Content $CommitMsgFile -Raw).Trim()
$firstLine = ($commitMsg -split "`r?`n")[0].Trim()

# 1. Ignora commits de merge ou squash automáticos
if ($firstLine -match "^Merge " -or $firstLine -match "^Revert ") {
    exit 0
}

# 2. Validação de Conventional Commits
$convCommitPattern = "^(feat|fix|refactor|docs|test|chore|perf|ci|build)(\([a-z0-9_\-\/]+\))?!?: .+"
if ($firstLine -notmatch $convCommitPattern) {
    Write-Error @"
[CONVENTIONAL COMMITS VIOLATION]
A mensagem de commit não segue a convenção do projeto!
Formato exigido: <type>(<scope>): <subject> [(UC-XX.YY)]
Tipos válidos: feat, fix, refactor, docs, test, chore, perf, ci, build

Exemplo com UC:
  feat(auth): add user registration endpoint (UC-01.01)

Exemplo geral:
  docs(readme): update setup instructions
"@
    exit 1
}

# 3. Validação de Caso de Uso e Claim Gate
$ucPattern = "\((UC-\d{2}\.\d{2})\)$"
if ($firstLine -match $ucPattern) {
    $slice = $Matches[1]
    $RepoRoot = Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "../..")
    $ClaimsScript = Join-Path $RepoRoot "tools/bin/claims.ps1"

    # Regra D-04: Commits de UC DEVEM estar no branch develop
    if (-not $CurrentBranch) {
        $CurrentBranch = (& git rev-parse --abbrev-ref HEAD).Trim()
    }

    if ($CurrentBranch -ne "develop") {
        Write-Error @"
[POLÍTICA D-04 VIOLADA]
Tentativa de commitar UC '$slice' na branch '$CurrentBranch'.
Acordo D-04: Commits de Caso de Uso (UC-XX.YY) DEVEM ser efetuados na branch 'develop'.

Para cumprir a política D-04:
1. Mude para o branch develop: git checkout develop
2. Reaplique o commit
(A branch 'main' é reservada exclusivamente para releases consolidadas).
"@
        exit 1
    }

    # Regra de Claims: O slice DEVE possuir claim ativo
    $psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell.exe" }
    & $psExe -ExecutionPolicy Bypass -NoProfile -File $ClaimsScript check -slice $slice | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error @"
[POKA-YOKE CLAIM GATE]
Nenhum claim ativo encontrado para o slice '$slice'.
Commits com assinatura '(UC-XX.YY)' exigem claim prévio para garantir a disciplina de concorrência.

Obtenha o claim antes de commitar:
  tools/bin/claims.cmd claim -slice $slice -owner <seu-papel>
Exemplo:
  tools/bin/claims.cmd claim -slice $slice -owner coder
"@
        exit 1
    }
}

exit 0
