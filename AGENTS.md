# AGENTS.md — DevTasks

Acordos operacionais do projeto. Regras globais do oráculo (`~/.agents/rules/`) continuam valendo;
em conflito, este arquivo documenta as **decisões específicas deste repo**.

## Stack & Topologia

- Stack Dart única: **Flutter** (`solution/app`) + **Serverpod** (`solution/server`) + **PostgreSQL** + **Docker**.
- Topologia `solution/{app,server,client}` é **decisão consciente do PO** — desvio da topologia `lib/` raiz
  prevista para stack mobile no oráculo; registrada em `docs/architecture/DESIGN.md` §9. Não "consertar" para `lib/` raiz.
- Pub workspace nativo na raiz (membros: `app`, `server`, `client`) — **lock único na raiz** (EPIC-00).
- `solution/client/` é **código gerado** (`serverpod generate`) — nunca editar à mão.

## Código

- Identificadores em **inglês**; documentação (`docs/`, `LEARNINGS.md`) em **pt-BR**.
- VSA no app: `lib/modules/<modulo>/{domain,infrastructure,presentation}` + kernel `global/`.
- Domínio/Handlers sem imports de infra (DIP); Port só com o que a Feature usa (ISP).
- Falha de negócio esperada → `Result`/erro tipado capturado na fronteira; exceção só para falha impredizável.
- Fonte de verdade do contrato client↔server: modelos Serverpod (`serverpod generate`), não OpenAPI manual.

## Qualidade

- TDD **Red-Before-Green**; pirâmide: unit (domínio, fakes) ≫ contract ≫ poucos E2E.
- Commits Conventional, atômicos, **docs no mesmo commit** da mudança; stage **por path explícito**.
- Nenhuma entrega declarada sem cadeia de evidência estruturada (`[EVIDÊNCIA]`).

## Decisões fechadas (2026-10-21 — trilha completa em `docs/architecture/DESIGN.md` §12)

- **D-01**: Kanban = **3 colunas** (`Backlog | Em Progresso | Concluído`) — PRD RF-10/Apêndice A corrigidos.
- **D-02**: Papéis = **3** (`owner | developer | viewer`) — PRD RF-05/§7/§9 corrigidos.
- **D-03**: Gerência de estado do app = **Riverpod** (GetX descartado).
- **D-04**: Branches = ciclo por UC com commits assinados direto em **`develop`**; `main` só via
  release; hook F0.04 bloqueia commit `(UC-XX.YY)` fora de `develop` (2026-10-21).
- **D-07**: Apresentação do app = **MVVM por slice, unidirecional** (1 UC = 1 ViewModel com estado
  imutável + intents; Riverpod é o mecanismo); estado transversal em `global/`; código enxuto com
  **Object Calisthenics + SOLID + Clean Code ponta a ponta** auditados no Gate 3 (2026-10-23).
