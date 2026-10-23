# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

Projeto DevTasks (Flutter + Serverpod + Postgres, portfólio/demo público).
**EPIC-00 e EPIC-01 (Autenticação) encerradas** · **EPIC-02 (Workspaces) iniciada**.

## Estado verificado (2026-10-23)

- **Consolidadas EPIC-01**: `UC-01.00` a `UC-01.07` (bloqueantes sanados) e `UC-01.08` (wiring real do app com `flutter_secure_storage`, `ServerpodAuthClient` e rotas protegidas pelo `RouteGuard` no boot — commit `e049f35`).
- **Governança do Harness (NFR-03)**: `tools/test.ps1` calibrado com modos `-Unit` (≤60s; tempo medido: 31,68s) e `-Integration` (≤120s), resolução de pacotes isolada com `-NoPub` no CI — commit `f1eabd9`.
- **Iniciação da EPIC-02 (`UC-02.01` CRUD Workspace)**: modelos `DevtasksWorkspace` e `DevtasksWorkspaceMember` (role `owner|developer|viewer`, índice `UNIQUE(workspaceId, userId)` INV-09), migração `20261023211407351`, serviço puro com anti-enumeração (INV-01) e autorização por papel (INV-06) — commit `b2021a6`.
- **Suíte & Analisadores**: `solution/app` 79/79 passed, `solution/server` 91/91 passed; `flutter analyze` e `dart analyze` sem avisos; DAG gate e Pin gate OK.
- **Git & Remotos**: `origin/develop` 100% sincronizado após `git push` (HEAD `b2021a6`).

## Próximo passo

1. **`UC-02.02`**: Gestão de membros e convites de workspace (adicionar/remover membro com validação de papel).
2. **`UC-02.03`**: `MembershipGuard` transversal completo.
3. **App UI de Workspaces**: telas `/workspaces` consumindo o cliente gerado.

## Travas vivas

- Ciclo em `develop`; commit de UC exige claim ativo; `main` só por release (D-04).
- Toolchain: Serverpod CLI `3.4.13` obrigatória (idempotência com diff zero no generate).
- Segurança: `userId` vem sempre da sessão autenticada (`INV-SEC-06`), nunca de payloads de cliente.
