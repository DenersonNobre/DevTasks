# Epic 06 — Dashboard (dashboard)

> Status: ⏳ Pendente | Prioridade: Alta | Dependências: EPIC-04

## 1. Objetivo e Valor de Negócio

Entregar a visão de estado do trabalho: por escopo selecionado (workspace/projeto), totais de
tarefas, concluídas, em andamento e atrasadas — a tela que fecha o loop "abrir o app e saber onde
estou" (Rafa) e "ver o progresso da equipe" (Carla). Segue em paralelo a EPIC-05 (ramos disjuntos).

- **Stack**: `dashboard_endpoint` (query, CQRS light — sem mutação) + módulo VSA `dashboard/`.
- **Invariantes**: INV-07 (`isOverdue` derivado — nunca coluna persistida: `dueDate < hoje ∧
  status != done`, `Clock` injetada) e INV-01 (métricas só do workspace do usuário).
- **NFR-03**: leitura agregada pura — teste unitário com fakes, sem banco/rede.

## 2. Matriz de Features

| # | Feature | UCs/Histórias | Independência / Risco | Status |
|:---|:---|:---:|:---|:---:|
| F6.1 | Métricas por escopo (totais, progresso, atrasadas) | 1 | INV-07 (fuso/clock), INV-01 | ⏳ |

---

## 3. Detalhamento das Features

### Feature 6.1 — Métricas por Escopo (RF-13 / INV-07)

**Descrição**: agregação `total / done / in_progress / overdue` por workspace ou projeto
selecionado; `overdue` calculado sob demanda com `Clock` injetada (INV-07 — sem flag persistida,
impede atraso obsoleto após mudança de prazo/status). Comparação por data de calendário (fuso
canônico definido no DESIGN).

**DoR**: EPIC-04 ✅ (tarefas existentes).
**DoD**: INV-07 com teste unitário em 3 relógios diferentes (nada muda no banco; só o cálculo);
`StatCard` (DESIGN §4.6) com estados de loading/vazio/erro.

#### User Story 6.1.1 — Ver o estado do trabalho de uma olhada

* **Identificador**: `UC-06.01`
* **Narrativa**:
  - **Como** tech lead (persona Carla) e desenvolvedor (persona Rafa)
  - **Eu quero** ver totais, progresso e tarefas atrasadas do workspace ou projeto selecionado
  - **Para que** eu decida onde intervir sem abrir tarefa por tarefa
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: métricas por escopo selecionado
    Dado um projeto com 10 tarefas (4 done, 3 in_progress, 2 backlog, 1 atrasada)
    Quando seleciono o projeto no dashboard
    Então vejo total 10, concluídas 4, em andamento 3 e atrasadas 1

  Cenário: atraso é derivado, não persistido
    Dado o relógio em 2026-01-10 e uma tarefa com dueDate 2026-01-05 em progresso
    Quando a leio no dashboard
    Then ela conta como atrasada; quando mudo o status para done, deixa de contar sem nenhuma escrita de flag

  Cenário: métricas respeitam o tenant
    Dado um workspace alheio
    Quando abro meu dashboard
    Então nenhuma métrica daquele workspace aparece (INV-01)
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: teste Red da agregação com `Clock` fake (INV-07) ➔ Commit: `test(dashboard): red for overdue derivation`
  2. `TASK-02`: `dashboard_endpoint` (query agregada por escopo) ➔ Commit: `feat(dashboard): add metrics endpoint`
  3. `TASK-03`: tela `/` com `StatCard`s (DESIGN §4.6), seletor de escopo e states §3 ➔ Commit: `feat(ui): add dashboard with stat cards`
* **Impacto & Arquivos Alvo**:
  - `solution/server/lib/src/endpoints/dashboard_endpoint.dart` [NEW]
  - `solution/app/lib/modules/dashboard/{domain,infrastructure,presentation}/**` [NEW]
  - `solution/app/test/unit/dashboard/**` [NEW]
