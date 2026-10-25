# tools/sync-remotes.ps1
# Projecao idempotente dos artefatos de governanca (docs/plan) para os remotos Gitea e GitHub.
#
# REGRA DE STATUS (fonte unica, auditavel):
#   O status de um UC e o status da FEATURE que o contem no epico (coluna Status da
#   tabela "Matriz de Features"). Hoje existe 1 UC por feature, entao o mapeamento e 1:1.
#   Os commits que citam o UC (com ou sem parenteses: `(UC-01.01)` ou `UC-01.01:`) sao
#   EVIDENCIA citada no corpo da issue, nunca o criterio de status.
#   Motivo: derivar status de commit produz falso negativo (um UC fechado por commit com
#   tag em outro formato aparece "pendente") e nao enxerga o caso "implementado, aguardando
#   Gate 3". O epico e o dono do escopo; a ele pertence a decisao de fechamento.
#
# IDEMPOTENCIA:
#   label/milestone  -> casados por nome/titulo
#   issue            -> casada pelo prefixo `UC-XX.YY` do titulo
#   wiki             -> paginas reescritas a partir da fonte local
#   board (GitHub)   -> item casado pelo numero da issue
#
# USO:
#   pwsh tools/sync-remotes.ps1 -Stage issues -DryRun
#   pwsh tools/sync-remotes.ps1 -Remote gitea -Stage wiki
#
# REQUISITOS: GITEA_TOKEN e GH_TOKEN no ambiente (nunca em URL de remote persistido).
[CmdletBinding()]
param(
    [ValidateSet('all', 'gitea', 'github')]
    [string]$Remote = 'all',

    [ValidateSet('issues', 'wiki', 'board', 'all')]
    [string]$Stage = 'all',

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $repoRoot

$giteaOwner = 'DartFlutter'; $giteaRepo = 'DevTasks'; $giteaBase = 'http://gitea.lan/api/v1'
$ghOwner = 'DenersonNobre';  $ghRepo = 'DevTasks';    $ghBase = 'https://api.github.com'
$ghProjectTitle = 'DevTasks — Governança de UCs'

$epicNames = @{
    '00' = 'Fundação'; '01' = 'Autenticação'; '02' = 'Workspace & Membresias'; '03' = 'Projetos'
    '04' = 'Tarefas & Kanban'; '05' = 'Comentários'; '06' = 'Dashboard'; '07' = 'Deploy & Medição'
    '08' = 'Migração Serverpod → shelf'
}
$milestoneByEpic = @{
    '00' = 'v0.1.0'; '01' = 'v0.1.0'; '02' = 'v0.1.0'; '08' = 'v0.1.0'
    '03' = 'v0.2.0'; '04' = 'v0.2.0'; '05' = 'v0.2.0'; '06' = 'v0.2.0'; '07' = 'v0.2.0'
}
$epicInvariants = @{
    'EPIC-00' = 'NFR-03 · NFR-04 (harness e gates da fundação)'
    'EPIC-01' = 'INV-08 · NFR-03 · NFR-05 (identidade e sessão)'
    'EPIC-02' = 'INV-01 · INV-02 · INV-06 · INV-09 (tenancy e papéis)'
    'EPIC-03' = 'INV-05 (projeto arquivado é somente leitura)'
    'EPIC-04' = 'INV-03 · INV-04 · NFR-02 (atribuição, colunas e concorrência)'
    'EPIC-05' = 'INV-02 · INV-05 · INV-06 (comentário imutável e composição)'
    'EPIC-06' = 'INV-07 (atraso derivado, nunca persistido)'
    'EPIC-07' = 'NFR-01 (P95 < 500 ms)'
    'EPIC-08' = 'INV-01 · INV-06 · INV-09 · INV-SEC-04/13/16/17 (contrato neutro e segurança)'
}
$epicColors = @{
    '00' = '6b7280'; '01' = '1d4ed8'; '02' = '0e7490'; '03' = '7c3aed'; '04' = 'b91c1c'
    '05' = 'a16207'; '06' = '15803d'; '07' = 'be185d'; '08' = '0f766e'
}

# ----------------------------------------------------------------------------- manifest
function Get-UcManifest {
    $commitByUc = @{}
    foreach ($line in (git log --format='%H%x09%s' --all)) {
        if ($line -notmatch '^([0-9a-f]{40})\t(.+)$') { continue }
        $sha = $Matches[1].Substring(0, 7); $subject = $Matches[2]
        foreach ($m in [regex]::Matches($subject, '(?i)(\(|\b)(UC-\d{2}\.\d{2})(\)|\b)')) {
            $id = $m.Groups[2].Value.ToUpper()
            if (-not $commitByUc.ContainsKey($id)) { $commitByUc[$id] = @() }
            $commitByUc[$id] += [pscustomobject]@{ sha = $sha; subject = $subject }
        }
    }

    $ucs = @()
    foreach ($file in (Get-ChildItem docs\plan\epics\*.md | Sort-Object Name)) {
        $epicId = [regex]::Match($file.Name, 'epic-(\d{2})').Groups[1].Value
        $lines = Get-Content $file.FullName
        $statusHeader = ($lines | Select-String -Pattern '^> Status:' | Select-Object -First 1).Line
        $epicStatus = if ($statusHeader -match 'Concluída') { 'Concluída' } else { 'Pendente' }

        # status por feature (coluna Status da Matriz de Features)
        $featureStatus = @{}
        foreach ($l in $lines) {
            if ($l -match '^\|\s*(F\d\.\d)\s*\|.*\|\s*(✅|⏳|🔄|❌)\s*\|\s*$') {
                $featureStatus[$Matches[1]] = $Matches[2]
            }
        }

        $blocks = @()
        if ($epicId -eq '08') {
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -notmatch '^### (F8\.\d) — (.+)$') { continue }
                $ucMatch = [regex]::Match($Matches[2], '`(UC-08\.\d{2})`')
                if (-not $ucMatch.Success) { continue }
                $blocks += [pscustomobject]@{
                    index = $i; feature = $Matches[1]; uc = $ucMatch.Groups[1].Value
                    title = ($Matches[2] -replace '\s*\(`UC-08\.\d{2}`\).*$', '' -replace '\s*—\s*\*\*objetivo do épico\*\*\s*$', '').Trim()
                }
            }
        } else {
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -notmatch '^#### User Story .*? — (.+)$') { continue }
                $title = $Matches[1].Trim()
                $feature = $null
                for ($k = [Math]::Max(0, $i - 40); $k -lt $i; $k++) {
                    if ($lines[$k] -match '^### Feature (\d\.\d) ') { $feature = "F$($Matches[1])" }
                }
                $ucId = $null
                for ($j = $i + 1; $j -lt [Math]::Min($i + 8, $lines.Count); $j++) {
                    if ($lines[$j] -match '\*\*Identificador\*\*: `(UC-\d{2}\.\d{2})`') { $ucId = $Matches[1]; break }
                }
                if (-not $ucId) { continue }
                $blocks += [pscustomobject]@{ index = $i; feature = $feature; uc = $ucId; title = $title }
            }
        }

        foreach ($b in $blocks) {
            $narrative = @(); $gherkin = @(); $inG = $false
            for ($j = $b.index + 1; $j -lt $lines.Count; $j++) {
                if ($lines[$j] -match '^### ' -or $lines[$j] -match '^## ') { break }
                if ($lines[$j] -match '^#### ' -and $epicId -ne '08') { break }
                if ($lines[$j] -match '\*\*(Como|Eu quero|Para que)\*\*') {
                    $narrative += (($lines[$j] -replace '^\s*[-*]\s+', '').Trim())
                }
                if ($lines[$j] -match '^\s*```gherkin') { $inG = $true; continue }
                if ($inG -and $lines[$j] -match '^\s*```') { $inG = $false; continue }
                if ($inG) { $gherkin += $lines[$j].TrimEnd() }
            }

            $featureOk = ($b.feature -and $featureStatus[$b.feature] -eq '✅')
            $commits = if ($commitByUc.ContainsKey($b.uc)) { $commitByUc[$b.uc] } else { @() }
            $ucs += [pscustomobject]@{
                uc         = $b.uc
                epic       = "EPIC-$epicId"
                epicName   = $epicNames[$epicId]
                epicStatus = $epicStatus
                feature    = $b.feature
                milestone  = $milestoneByEpic[$epicId]
                title      = $b.title
                narrative  = $narrative
                gherkin    = $gherkin
                status     = if ($featureOk) { 'Concluída' } else { 'Pendente' }
                evidence   = $commits
                source     = "docs/plan/epics/$($file.Name)"
            }
        }
    }

    return ($ucs | Sort-Object uc -Unique)
}

function New-IssueBody {
    param($u)
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("### Caso de Uso: $($u.uc) — $($u.title)")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("**Épico**: ``$($u.epic)`` — $($u.epicName) (status na fonte: $($u.epicStatus))  ")
    [void]$sb.AppendLine("**Feature**: ``$($u.feature)``  ")
    [void]$sb.AppendLine("**Milestone**: ``$($u.milestone)``  ")
    [void]$sb.AppendLine("**Estado**: **$($u.status)** (fonte: status da feature em ``$($u.source)``)")
    [void]$sb.AppendLine()
    if ($u.narrative.Count -gt 0) {
        [void]$sb.AppendLine('#### Narrativa (User Story)')
        foreach ($n in $u.narrative) { [void]$sb.AppendLine("- $n") }
        [void]$sb.AppendLine()
    }
    if ($u.gherkin.Count -gt 0) {
        [void]$sb.AppendLine('#### Critérios de aceitação')
        [void]$sb.AppendLine('```gherkin')
        foreach ($g in $u.gherkin) { [void]$sb.AppendLine($g) }
        [void]$sb.AppendLine('```')
        [void]$sb.AppendLine()
    }
    [void]$sb.AppendLine('#### Invariantes do épico (SPEC §8)')
    [void]$sb.AppendLine($epicInvariants[$u.epic])
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('#### Rastreabilidade')
    [void]$sb.AppendLine("- Fonte: ``$($u.source)``")
    if ($u.evidence.Count -gt 0) {
        [void]$sb.AppendLine("- Commits que citam este UC ($($u.evidence.Count)):")
        foreach ($c in $u.evidence) { [void]$sb.AppendLine("  - ``$($c.sha)`` — $($c.subject)") }
    } else {
        [void]$sb.AppendLine('- Nenhum commit cita este UC ainda.')
    }
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('---')
    [void]$sb.AppendLine('_Issue projetada de `docs/plan/epics/` por `tools/sync-remotes.ps1`. Edite o épico, não a issue._')
    return $sb.ToString()
}

# ----------------------------------------------------------------------------- gitea
function Invoke-Gitea {
    param([string]$Method, [string]$Path, $Body)
    $uri = "$giteaBase/repos/$giteaOwner/$giteaRepo$Path"
    if ($DryRun -and $Method -ne 'GET') { Write-Host "    [dry] $Method $Path"; return $null }
    if ($null -eq $Body) { return Invoke-RestMethod -Uri $uri -Headers @{ Authorization = "token $env:GITEA_TOKEN" } -Method $Method -TimeoutSec 40 }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes(($Body | ConvertTo-Json -Depth 10 -Compress))
    return Invoke-RestMethod -Uri $uri -Headers @{ Authorization = "token $env:GITEA_TOKEN" } -Method $Method `
        -Body $bytes -ContentType 'application/json; charset=utf-8' -TimeoutSec 40
}

function Get-GiteaList {
    param([string]$Path)
    $r = Invoke-Gitea GET $Path
    if ($null -eq $r) { return @() }
    return @($r)
}

function Sync-GiteaIssues {
    param($Ucs)
    Write-Host '== Gitea · labels =='
    $wanted = @(
        @{ name = 'uc'; color = '1d76db'; description = 'Caso de Uso (UC-XX.YY)' },
        @{ name = 'planejamento'; color = '0e8a16'; description = 'Projeção do docs/plan' }
    )
    foreach ($e in ($epicColors.Keys | Sort-Object)) {
        $wanted += @{ name = "epic-$e"; color = $epicColors[$e]; description = "Épico $e" }
    }
    $existing = Get-GiteaList '/labels?limit=100'
    $byName = @{}; foreach ($l in $existing) { $byName[$l.name] = $l }
    $labelIds = @{}
    foreach ($w in $wanted) {
        if ($byName.ContainsKey($w.name)) { $labelIds[$w.name] = $byName[$w.name].id }
        else { $c = Invoke-Gitea POST '/labels' $w; if ($c) { $labelIds[$w.name] = $c.id } }
        Write-Host "  $($w.name)"
    }

    Write-Host '== Gitea · milestones =='
    $msDefs = @(
        @{ title = 'v0.1.0'; description = 'Fundação, autenticação, workspace e migração shelf (EPIC-00/01/02/08).' },
        @{ title = 'v0.2.0'; description = 'Fechamento do MVP: projetos, tarefas, comentários, dashboard e deploy (EPIC-03..07).' }
    )
    $msByTitle = @{}; foreach ($m in (Get-GiteaList '/milestones?state=all&limit=100')) { $msByTitle[$m.title] = $m.id }
    $msIds = @{}
    foreach ($d in $msDefs) {
        if ($msByTitle.ContainsKey($d.title)) { $msIds[$d.title] = $msByTitle[$d.title] }
        else { $c = Invoke-Gitea POST '/milestones' $d; if ($c) { $msIds[$d.title] = $c.id } }
        Write-Host "  $($d.title)"
    }

    Write-Host '== Gitea · issues =='
    $all = @(); $page = 1
    do { $chunk = Get-GiteaList "/issues?state=all&type=issues&limit=50&page=$page"; $all += $chunk; $page++ } while ($chunk.Count -eq 50)
    $byPrefix = @{}
    foreach ($i in $all) { $m = [regex]::Match($i.title, '^(UC-\d{2}\.\d{2})'); if ($m.Success) { $byPrefix[$m.Groups[1].Value] = $i } }

    $created = 0; $updated = 0; $kept = 0
    foreach ($u in $Ucs) {
        $state = if ($u.status -eq 'Concluída') { 'closed' } else { 'open' }
        $title = "$($u.uc) — $($u.title)"
        $body = New-IssueBody $u
        if ($byPrefix.ContainsKey($u.uc)) {
            $ex = $byPrefix[$u.uc]
            if ($ex.state -ne $state -or $ex.body -ne $body) {
                Invoke-Gitea PATCH "/issues/$($ex.number)" @{ state = $state; body = $body } | Out-Null
                Write-Host "  ~ #$($ex.number) $($u.uc) -> $state"
                $updated++
            } else { $kept++ }
            continue
        }
        $payload = @{ title = $title; body = $body; closed = ($state -eq 'closed') }
        $ids = @(); foreach ($ln in @('uc', 'planejamento', "epic-$($u.epic.Substring(5))")) { if ($labelIds.ContainsKey($ln)) { $ids += $labelIds[$ln] } }
        $payload.labels = $ids
        if ($msIds.ContainsKey($u.milestone)) { $payload.milestone = $msIds[$u.milestone] }
        $r = Invoke-Gitea POST '/issues' $payload
        if ($r) { Write-Host "  + #$($r.number) $($u.uc) [$state]" }
        $created++
    }
    Write-Host "  Gitea issues: criadas=$created atualizadas=$updated inalteradas=$kept"
}

# ----------------------------------------------------------------------------- github
function Invoke-Gh {
    param([string]$Method, [string]$Path, $Body)
    $uri = "$ghBase/repos/$ghOwner/$ghRepo$Path"
    if ($DryRun -and $Method -ne 'GET') { Write-Host "    [dry] $Method $Path"; return $null }
    $h = @{ Authorization = "Bearer $env:GH_TOKEN"; 'User-Agent' = 'devtasks-sync'; Accept = 'application/vnd.github+json' }
    if ($null -eq $Body) { return Invoke-RestMethod -Uri $uri -Headers $h -Method $Method -TimeoutSec 40 }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes(($Body | ConvertTo-Json -Depth 10 -Compress))
    return Invoke-RestMethod -Uri $uri -Headers $h -Method $Method -Body $bytes -ContentType 'application/json; charset=utf-8' -TimeoutSec 40
}

function Get-GhList {
    param([string]$Path)
    $r = Invoke-Gh GET $Path
    if ($null -eq $r) { return @() }
    return @($r)
}

function Sync-GithubIssues {
    param($Ucs)
    Write-Host '== GitHub · labels =='
    $existing = Get-GhList '/labels?per_page=100'
    $byName = @{}; foreach ($l in $existing) { $byName[$l.name] = $l }
    foreach ($e in ($epicColors.Keys | Sort-Object)) {
        $name = "epic-$e"
        if (-not $byName.ContainsKey($name)) { Invoke-Gh POST '/labels' @{ name = $name; color = $epicColors[$e]; description = "Épico $e" } | Out-Null }
    }
    foreach ($w in @(@{ name = 'uc'; color = '1d76db'; description = 'Caso de Uso (UC-XX.YY)' },
                     @{ name = 'planejamento'; color = '0e8a16'; description = 'Projeção do docs/plan' })) {
        if (-not $byName.ContainsKey($w.name)) { Invoke-Gh POST '/labels' $w | Out-Null }
    }
    Write-Host '  ok'

    Write-Host '== GitHub · milestones =='
    $msByTitle = @{}; foreach ($m in (Get-GhList '/milestones?state=all&per_page=100')) { $msByTitle[$m.title] = $m.number }
    $msNumbers = @{}
    foreach ($d in @(@{ title = 'v0.1.0'; description = 'Fundação, autenticação, workspace e migração shelf (EPIC-00/01/02/08).' },
                     @{ title = 'v0.2.0'; description = 'Fechamento do MVP: projetos, tarefas, comentários, dashboard e deploy (EPIC-03..07).' })) {
        if ($msByTitle.ContainsKey($d.title)) { $msNumbers[$d.title] = $msByTitle[$d.title] }
        else { $c = Invoke-Gh POST '/milestones' $d; if ($c) { $msNumbers[$d.title] = $c.number } }
        Write-Host "  $($d.title)"
    }

    Write-Host '== GitHub · issues =='
    $all = @(); $page = 1
    do {
        $chunk = Get-GhList "/issues?state=all&per_page=100&page=$page"
        $all += @($chunk | Where-Object { -not $_.pull_request })
        $page++
    } while ($chunk.Count -eq 100)
    $byPrefix = @{}
    foreach ($i in $all) { $m = [regex]::Match($i.title, '^(UC-\d{2}\.\d{2})'); if ($m.Success) { $byPrefix[$m.Groups[1].Value] = $i } }

    $created = 0; $updated = 0; $kept = 0
    foreach ($u in $Ucs) {
        $state = if ($u.status -eq 'Concluída') { 'closed' } else { 'open' }
        $title = "$($u.uc) — $($u.title)"
        $body = New-IssueBody $u
        if ($byPrefix.ContainsKey($u.uc)) {
            $ex = $byPrefix[$u.uc]
            if ($ex.state -ne $state -or $ex.body -ne $body) {
                Invoke-Gh PATCH "/issues/$($ex.number)" @{ state = $state; body = $body } | Out-Null
                Write-Host "  ~ #$($ex.number) $($u.uc) -> $state"
                $updated++
            } else { $kept++ }
            continue
        }
        $payload = @{ title = $title; body = $body; labels = @('uc', 'planejamento', "epic-$($u.epic.Substring(5))") }
        if ($msNumbers.ContainsKey($u.milestone)) { $payload.milestone = $msNumbers[$u.milestone] }
        $r = Invoke-Gh POST '/issues' $payload
        if ($r) {
            if ($state -eq 'closed') { Invoke-Gh PATCH "/issues/$($r.number)" @{ state = 'closed' } | Out-Null }
            Write-Host "  + #$($r.number) $($u.uc) [$state]"
        }
        $created++
    }
    Write-Host "  GitHub issues: criadas=$created atualizadas=$updated inalteradas=$kept"
}

# ----------------------------------------------------------------------------- wiki
function Sync-Wiki {
    $pages = [ordered]@{
        'Home' = 'README.md'; 'Agents' = 'AGENTS.md'
        'Architecture' = 'docs/architecture/SPEC.md'; 'Design' = 'docs/architecture/DESIGN.md'
        'Plan' = 'docs/plan/README.md'; 'Checkpoint' = 'CHECKPOINT.md'
        'Learnings' = 'LEARNINGS.md'; 'Changelog' = 'CHANGELOG.md'
        'Api-Contract' = 'docs/api/.openapi-notes.md'
    }
    foreach ($f in (Get-ChildItem docs\plan\epics\*.md | Sort-Object Name)) {
        $pages[($f.BaseName -replace '^epic-(\d{2})-(.+)$', 'Epic-$1-$2')] = "docs/plan/epics/$($f.Name)"
    }
    $epicPages = @{}
    foreach ($k in $pages.Keys) { if ($k -like 'Epic-*') { $epicPages[(Split-Path $pages[$k] -Leaf)] = $k } }

    $targets = @(
        @{ name = 'gitea'; url = 'http://gitea.lan/DartFlutter/DevTasks.wiki.git'; branch = 'main'
           blob = 'http://gitea.lan/DartFlutter/DevTasks/src/branch/develop'; token = $env:GITEA_TOKEN; user = 'token' },
        @{ name = 'github'; url = 'https://github.com/DenersonNobre/DevTasks.wiki.git'; branch = 'master'
           blob = 'https://github.com/DenersonNobre/DevTasks/blob/develop'; token = $env:GH_TOKEN; user = 'x-access-token' }
    )

    foreach ($t in $targets) {
        if ($Remote -ne 'all' -and $Remote -ne $t.name) { continue }
        Write-Host "== wiki $($t.name) =="
        $work = Join-Path $env:TEMP "devtasks-wiki-$($t.name)"
        if (Test-Path $work) { Remove-Item -Recurse -Force $work }
        New-Item -ItemType Directory -Force -Path $work | Out-Null

        foreach ($k in $pages.Keys) {
            $src = Join-Path $repoRoot $pages[$k]
            if (-not (Test-Path $src)) { Write-Host "  ! ausente: $($pages[$k])"; continue }
            $body = Get-Content $src -Raw -Encoding utf8
            $srcDir = Split-Path $pages[$k] -Parent
            $body = [regex]::Replace($body, '\]\(([^)]+)\)', {
                    param($m)
                    $target = $m.Groups[1].Value
                    if ($target -match '^(https?:|#|mailto:)') { return $m.Value }
                    $leaf = Split-Path $target -Leaf
                    if ($epicPages.ContainsKey($leaf)) { return '](' + $epicPages[$leaf] + ')' }
                    $combined = if ($srcDir) { Join-Path $srcDir $target } else { $target }
                    try {
                        $full = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $combined))
                        $rel = ([System.IO.Path]::GetRelativePath($repoRoot, $full)) -replace '\\', '/'
                        return "]($($t.blob)/$rel)"
                    } catch { return $m.Value }
                })
            Set-Content -Path (Join-Path $work "$k.md") -Value $body -Encoding utf8 -NoNewline
        }
        $sidebar = "* [Pagina Inicial](Home)`n* [Agentes & Governanca](Agents)`n* [Arquitetura & SPEC](Architecture)`n" +
                   "* [Design & Engenharia](Design)`n* [Plano & Epicos](Plan)`n* [Checkpoint](Checkpoint)`n" +
                   "* [Aprendizados](Learnings)`n* [Changelog](Changelog)`n* [Contrato da API](Api-Contract)"
        Set-Content -Path (Join-Path $work '_Sidebar.md') -Value $sidebar -Encoding utf8 -NoNewline

        if ($DryRun) { Write-Host "  [dry] $((Get-ChildItem $work -File).Count) paginas -> push $($t.branch)"; continue }

        $authUrl = $t.url -replace '^(https?://)', "`$1$($t.user):$($t.token)@"
        Push-Location $work
        try {
            git init -q -b $t.branch 2>$null
            git add -A | Out-Null
            git -c user.name='devtasks-sync' -c user.email='sync@devtasks.local' commit -q -m 'docs(wiki): sync governance pages' | Out-Null
            git remote add origin $authUrl
            $out = git push -u origin $t.branch --force 2>&1
            $code = $LASTEXITCODE
            Write-Host ((($out | Out-String) -replace [regex]::Escape($t.token), '***').Trim())
            if ($code -ne 0 -and $t.name -eq 'github') {
                Write-Host '  [ACAO MANUAL] A wiki do GitHub exige a primeira pagina pela UI:' -ForegroundColor Yellow
                Write-Host "  https://github.com/$ghOwner/$ghRepo/wiki  ->  Create the first page" -ForegroundColor Yellow
            }
            Write-Host "  push exit=$code"
        } finally {
            Pop-Location
            Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
        }
    }
}

# ----------------------------------------------------------------------------- board
function Invoke-Gql {
    param([string]$Query, [hashtable]$Vars)
    if ($DryRun -and $Query -match '^\s*mutation') { Write-Host '    [dry] mutation'; return $null }
    $payload = @{ query = $Query; variables = $Vars } | ConvertTo-Json -Depth 12 -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
    $r = Invoke-RestMethod -Uri 'https://api.github.com/graphql' -Method Post `
        -Headers @{ Authorization = "Bearer $env:GH_TOKEN"; 'User-Agent' = 'devtasks-sync' } `
        -Body $bytes -ContentType 'application/json; charset=utf-8' -TimeoutSec 60
    if ($r.errors) { throw ('GraphQL: ' + (($r.errors | ForEach-Object { $_.message }) -join ' | ')) }
    return $r.data
}

function Sync-GithubBoard {
    Write-Host '== GitHub · board (Projects v2) =='
    $ctx = Invoke-Gql @'
query { viewer { id } repository(owner: "DenersonNobre", name: "DevTasks") { id } }
'@
    $viewerId = $ctx.viewer.id
    $repoId = $ctx.repository.id

    $existing = Invoke-Gql 'query { viewer { projectsV2(first: 30) { nodes { id title } } } }'
    $proj = $existing.viewer.projectsV2.nodes | Where-Object { $_.title -eq $ghProjectTitle } | Select-Object -First 1
    if ($proj) { $projectId = $proj.id; Write-Host "  = projeto existente" }
    else {
        $created = Invoke-Gql 'mutation($ownerId: ID!, $title: String!) { createProjectV2(input: { ownerId: $ownerId, title: $title }) { projectV2 { id } } }' @{ ownerId = $viewerId; title = $ghProjectTitle }
        if ($DryRun) { return }
        $projectId = $created.createProjectV2.projectV2.id
        Write-Host '  + projeto criado'
        Invoke-Gql 'mutation($projectId: ID!, $repositoryId: ID!) { linkProjectV2ToRepository(input: { projectId: $projectId, repositoryId: $repositoryId }) { repository { nameWithOwner } } }' @{ projectId = $projectId; repositoryId = $repoId } | Out-Null
    }

    $columns = @('Backlog', 'A Fazer', 'Em Andamento', 'Review & QA', 'Concluído')
    $fields = Invoke-Gql 'query($projectId: ID!) { node(id: $projectId) { ... on ProjectV2 { field(name: "Status") { ... on ProjectV2SingleSelectField { id options { id name } } } } } }' @{ projectId = $projectId }
    $statusField = $fields.node.field
    $current = @($statusField.options | ForEach-Object { $_.name })
    if (($current -join '|') -ne ($columns -join '|')) {
        $opts = $columns | ForEach-Object { @{ name = $_; color = 'GRAY'; description = $_ } }
        Invoke-Gql 'mutation($fieldId: ID!, $options: [ProjectV2SingleSelectFieldOptionInput!]!) { updateProjectV2Field(input: { fieldId: $fieldId, singleSelectOptions: $options }) { projectV2Field { ... on ProjectV2SingleSelectField { id } } } }' @{ fieldId = $statusField.id; options = $opts } | Out-Null
        $fields = Invoke-Gql 'query($projectId: ID!) { node(id: $projectId) { ... on ProjectV2 { field(name: "Status") { ... on ProjectV2SingleSelectField { id options { id name } } } } } }' @{ projectId = $projectId }
        $statusField = $fields.node.field
        Write-Host "  colunas: $(@($statusField.options | ForEach-Object { $_.name }) -join ' | ')"
    }
    $optBy = @{}; foreach ($o in $statusField.options) { $optBy[$o.name] = $o.id }

    $items = Invoke-Gql 'query($projectId: ID!) { node(id: $projectId) { ... on ProjectV2 { items(first: 100) { nodes { id content { ... on Issue { number } } } } } } }' @{ projectId = $projectId }
    $byNumber = @{}
    foreach ($it in $items.node.items.nodes) { if ($it.content -and $it.content.number) { $byNumber[$it.content.number] = $it.id } }

    $h = @{ Authorization = "Bearer $env:GH_TOKEN"; 'User-Agent' = 'devtasks-sync'; Accept = 'application/vnd.github+json' }
    $issues = @(); $page = 1
    do {
        $chunk = Invoke-RestMethod -Uri "$ghBase/repos/$ghOwner/$ghRepo/issues?state=all&per_page=100&page=$page" -Headers $h -TimeoutSec 40
        $issues += @($chunk | Where-Object { -not $_.pull_request })
        $page++
    } while (@($chunk).Count -eq 100)

    $added = 0; $moved = 0
    foreach ($iss in $issues) {
        if ($iss.title -notmatch '^UC-\d{2}\.\d{2}') { continue }
        $target = if ($iss.state -eq 'closed') { 'Concluído' } else { 'Backlog' }
        if ($byNumber.ContainsKey($iss.number)) { $itemId = $byNumber[$iss.number] }
        else {
            $add = Invoke-Gql 'mutation($projectId: ID!, $contentId: ID!) { addProjectV2ItemById(input: { projectId: $projectId, contentId: $contentId }) { item { id } } }' @{ projectId = $projectId; contentId = $iss.node_id }
            if ($DryRun) { continue }
            $itemId = $add.addProjectV2ItemById.item.id
            $added++
        }
        if (-not $optBy.ContainsKey($target)) { continue }
        Invoke-Gql 'mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) { updateProjectV2ItemFieldValue(input: { projectId: $projectId, itemId: $itemId, fieldId: $fieldId, value: { singleSelectOptionId: $optionId } }) { projectV2Item { id } } }' @{ projectId = $projectId; itemId = $itemId; fieldId = $statusField.id; optionId = $optBy[$target] } | Out-Null
        $moved++
    }
    Write-Host "  itens adicionados=$added posicionados=$moved"
}

# ----------------------------------------------------------------------------- main
$ucs = Get-UcManifest
$done = ($ucs | Where-Object status -eq 'Concluída').Count
Write-Host "manifesto: $($ucs.Count) UCs | concluidas=$done pendentes=$($ucs.Count - $done) | head=$(git log -1 --format='%h')"
$manifestPath = Join-Path $env:TEMP 'devtasks-ucs.json'
$ucs | ConvertTo-Json -Depth 8 | Set-Content $manifestPath -Encoding utf8

if ($Stage -eq 'all' -or $Stage -eq 'issues') {
    if ($Remote -eq 'all' -or $Remote -eq 'gitea') { Sync-GiteaIssues -Ucs $ucs }
    if ($Remote -eq 'all' -or $Remote -eq 'github') { Sync-GithubIssues -Ucs $ucs }
}
if ($Stage -eq 'all' -or $Stage -eq 'wiki') {
    Sync-Wiki
}
if (($Stage -eq 'all' -or $Stage -eq 'board') -and ($Remote -eq 'all' -or $Remote -eq 'github')) {
    Sync-GithubBoard
}
Write-Host "FIM (dryRun=$DryRun)"
