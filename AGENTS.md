# AGENTS.md — DevTasks

Acordos operacionais do projeto. Regras globais do oráculo (`~/.agents/rules/`) continuam valendo;
em conflito, este arquivo documenta as **decisões específicas deste repo**.

## Stack & Topologia

- Stack Dart única: **Flutter** (`solution/app`) + **Dart/shelf** (`solution/api`) + **PostgreSQL** + **Docker**.
- Topologia `solution/{app,api}` é decisão consciente de arquitetura — documentada em `docs/architecture/DESIGN.md` §9.
- Pub workspace nativo na raiz (membros: `app`, `api`) — **lock único na raiz**.
- Fonte de verdade do contrato client↔server: **`docs/api/openapi.yaml` (OpenAPI 3.1)** — validado por teste de contrato (`D-08`). O cliente **nunca** é derivado do código do servidor; adaptadores falam HTTP e vivem em `infrastructure/`.

## Código

- Identificadores em **inglês**; documentação (`docs/`, `LEARNINGS.md`) em **pt-BR**.
- **Interfaces e classes abstratas iniciam com `'I'`** (regra do Oráculo: `abstract interface class IWorkspaceRepository`, `abstract class IProjectRepository`, etc.).
- VSA no app: `lib/modules/<modulo>/{domain,infrastructure,presentation}` + kernel `global/`.
- Domínio/Handlers sem imports de infra (DIP); Port só com o que a Feature usa (ISP).
- **Barrels pontuados** (`.<dir>.dart` — ex.: `modules/auth/.domain.dart`, `global/session/.session.dart`)
  com `show`/`hide` para reduzir imports. Regras: (a) um arquivo **nunca** importa o barrel que o
  exporta (ciclo); (b) caminhos de `export` são relativos à **posição do barrel**, não da camada
  (o barrel na raiz do módulo exporta `domain/email.dart`; o que vive dentro da camada exporta `email.dart`); (c) barrels de camada só exportam o que a camada
  de cima consome (VMs não entram no barrel de estados); (d) o barrel vive **dentro** do diretório que
  agrega (`global/kernel/.kernel.dart`, `modules/auth/domain/.domain.dart`, `global/session/.session.dart`)
  com `export` relativo a esse diretório — a raiz do módulo só tem o barrel de superfície (`.auth.dart`);
  (e) `global/` **não** importa `modules/` (a porta transversal `SessionStore` mora em `global/session/`).
- Falha de negócio esperada → `Result`/erro tipado capturado na fronteira; exceção só para falha impredizável.

## Qualidade

- TDD **Red-Before-Green**; pirâmide: unit (domínio, fakes) ≫ contract ≫ poucos E2E.
- Commits Conventional, atômicos, **docs no mesmo commit** da mudança; stage **por path explícito**.
- Nenhuma entrega declarada sem cadeia de evidência estruturada (`[EVIDÊNCIA]`).

## Decisões fechadas (trilha completa em `docs/architecture/DESIGN.md` §12)

- **D-01**: Kanban = **3 colunas** (`Backlog | Em Progresso | Concluído`) — PRD RF-10/Apêndice A corrigidos.
- **D-02**: Papéis = **3** (`owner | developer | viewer`) — PRD RF-05/§7/§9 corrigidos.
- **D-03**: Gerência de estado do app = **Riverpod** (GetX descartado).
- **D-04**: Branches = ciclo por UC com commits assinados direto em **`develop`**; `main` só via
  release; hook F0.04 bloqueia commit `(UC-XX.YY)` fora de `develop`.
- **D-07**: Apresentação do app = **MVVM por slice, unidirecional** (1 UC = 1 ViewModel com estado
  imutável + intents; Riverpod é o mecanismo); estado transversal em `global/`; código enxuto com
  **Object Calisthenics + SOLID + Clean Code ponta a ponta** auditados no Gate 3.
- **D-08**: Arquitetura da API = **Dart/Shelf + PostgreSQL nativo puro + OpenAPI 3.1** como contrato canônico.
