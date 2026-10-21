# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-00-fundacao.md` §F0.1.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-00.01** — Corrigir resíduos de scaffold e fechar topologia (EPIC-00 · F0.1 · `US-0.1.1`).

**Gate 2.5: PULADO** — sem superfície sensível (sem auth/sessão, upload, webhook, CORS,
execução de shell, PII) e sem dependência nova (renomeação de `name:`/imports e criação de
workspace; nenhum pacote é adicionado).

## Interfaces

- Nenhuma porta nova — topologia/renomeação apenas (VSA+DDD sem mudança de domínio).

## Arquivos-alvo

- `pubspec.yaml` [NEW] — workspace raiz nativo (membros `app`, `server`; `client` adiado à F0.2).
- `solution/app/pubspec.yaml`, `solution/app/test/**`, `solution/app/README.md` [MODIFY]
- `solution/server/pubspec.yaml`, `solution/server/test/**`, `solution/server/README.md` [MODIFY]
- `.gitignore` [MODIFY]
- `docs/plan/state/UC-CURRENT.md` [NEW]
- `docs/plan/epics/epic-00-fundacao.md` [MODIFY]

## Estado de execução

- Claim: liberado após consolidação do UC-00.01.
- Implementação: GREEN — TDD Red-Before-Green comprovado; Gates 3 e 4 aprovados.

## Evidência (preenchida pelo Coder + QA)

- **Red** (antes da renomeação, exit ≠ 0 nos dois membros):
  - `flutter test` em `solution/app` → `EXIT_APP=1`, `Error: Couldn't resolve the package 'devtasks_app'`.
  - `flutter test` em `solution/server` → `EXIT_SERVER=1`, `Error: Couldn't resolve the package 'devtasks_server'`.
- **Green** (após workspace + renomeação + correção de READMEs):
  - `flutter pub get` na raiz → `Got dependencies!`, `ROOT_EXIT=0` (lock único `pubspec.lock` na raiz).
  - `flutter analyze` em `solution/app` → `No issues found!`, exit 0.
  - `flutter test` em `solution/app` → `+1: All tests passed!`, exit 0.
  - `flutter analyze` em `solution/server` → `No issues found!`, exit 0.
  - `flutter test` em `solution/server` → `+1: All tests passed!`, exit 0.
- **Gate 3 (Review)**: Aprovado — apontamentos de READMEs e conciliação do DoD de F0.1 sanados.
- **Gate 4 (QA)**: Laudo Verde empírico (analyzer e runner executados em 2026-10-21).

## Próximo UC

- **UC-00.02** (F0.2 — toolchain, build em 1 comando, `serverpod generate`; DoR exige F0.1 ✅).
