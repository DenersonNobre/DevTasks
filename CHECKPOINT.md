# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md` · laudo da API em `docs/plan/reviews/audit-api-2026-10-24.md`.
> Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

DevTasks — Flutter (`solution/app`) + Dart/Shelf + PostgreSQL puro + OpenAPI 3.1. Repositório público,
sincronizado em dois remotos (Gitea `origin` e GitHub `github`, ambos em dia). Ciclo corrente:
pós-EPIC-08, com EPIC-03 recém-fechada.

## Estado verificado (2026-10-25, HEAD `a23ff06`)

- **Épicos**: 00 ✅ · 01 ✅ · 02 ✅ · 03 ✅ · **08 ✅** (migração shelf) · 04/05/06/07 ⏳.
- **UCs**: 39 no plano — **30 concluídos / 9 pendentes** (`docs/plan/README.md` §7, derivado do
  status da feature no épico, não de histórico git).
- **Suíte**: api **177** (unit+contract) verde · **20 de integração verde contra PostgreSQL 18.6**
  (`tools/test.ps1 -Database`) · app **109** verde.
- **Gate `-Unit`: VERMELHO por orçamento de tempo**, não por teste — 206,26s contra teto de 120s
  (app 130,53s / api 75,64s). Causa medida: compilação a frio do bundle de teste (a mesma suíte app
  roda em **62s** na 2ª execução e **00:22** no cronômetro do runner). Ver `LEARNINGS.md` 2026-10-25.
- **Governança**: `dag-gate` e `doc-gate` verdes · health do dotfiles **187/187** · contrato OpenAPI
  com paridade bidirecional e prova negativa.
- **Remotos**: 39 issues (30 fechadas / 9 abertas) em cada · milestones `v0.1.0`/`v0.2.0` ·
  board GitHub 30 *Concluído* / 9 *Backlog* · wiki Gitea com 18 páginas.

## Próximos passos

1. **Calibrar NFR-03**: aquecer o bundle de teste do app fora do cronômetro (mesmo padrão já usado
   para `package_config`). Medido — não é regressão de teste.
2. **Laudo da API, Etapa 3** (fronteira fiel ao contrato): `A-1` UUID no path (o teste de
   caracterização já existe e deve virar `400`), `A-2` mass assignment, `M-1` limites de nome,
   `M-3` `WWW-Authenticate`.
3. Observar o job `test-integration-db` numa execução real do runner (B-2 provado só localmente).
4. Wiki do GitHub: exige a primeira página pela UI antes de
   `pwsh tools/sync-remotes.ps1 -Stage wiki -Remote github`.

## Travas vivas

- Commit com `(UC-XX.YY)` exige claim ativo; stage **sempre** por path explícito (a árvore foi
  compartilhada por 2 agentes nesta sessão); `--amend` proibido em árvore compartilhada.
- Gate de banco: `DEVTASKS_TEST_DATABASE_URL` é obrigatório em `-Database` (falha sem ele).
- Postgres de desenvolvimento: WSL (Ubuntu), alcançável do Windows em `127.0.0.1:5432`.
