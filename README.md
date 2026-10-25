# DevTasks

SaaS de gestão de tarefas para equipes de desenvolvimento — projeto de portfólio full-stack em Dart:
quadro Kanban, prazos/prioridades, colaboração assíncrona (comentários/atribuição) e dashboard de indicadores.

> **Status**: **EPIC-00 (Fundação) ✅** · **EPIC-01 (Autenticação) ✅** · **EPIC-02 (Workspace) ✅** · **EPIC-08 (Migração shelf) ✅** · Execução ativa em **EPIC-03 (Projetos)**.
> Todas as etapas seguem a esteira canônica de desenvolvimento com TDD Red-Before-Green e poka-yoke mecânico de claims.

---

## 1. Estrutura do Workspace (Monorepo)

```text
├── docs/                      # Quarteto canônico de documentação viva
│   ├── product/PRD.md         # Requisitos, personas e regras de negócio
│   ├── architecture/DESIGN.md # Decisões técnicas e UI
│   ├── architecture/SPEC.md   # Domínio puro, invariantes INV-01..09 e taxonomia
│   └── plan/                  # DAG de épicos e tracking de estado vivo
├── solution/
│   ├── app/                   # Cliente Flutter (VSA: modules/* + global/kernel/)
│   └── api/                   # API HTTP em Dart/Shelf + PostgreSQL puro
├── docker/                    # Paridade de ambiente (Dockerfile multi-stage + compose)
└── tools/                     # Toolchain de esteira, runners de teste e gates
```

---

## 2. Comandos Rápidos de Desenvolvimento

Todos os fluxos operacionais são executados em 1 comando determinístico:

| Operação | Comando | Descrição |
|:---|:---|:---|
| **Preflight** | `pwsh tools/build.ps1 -PreflightOnly` | Valida versões de SDK (Flutter ≥ 3.47, Dart ≥ 3.13) |
| **Build** | `pwsh tools/build.ps1` | Resolução de dependências do workspace e análise estática |
| **Clean** | `pwsh tools/clean.ps1` | Limpeza idempotente de caches/builds sem tocar em fontes |
| **Testes** | `pwsh tools/test.ps1` | Execução headless de todos os testes unitários/smoke (≤ 60s) |
| **Cobertura** | `pwsh tools/test.ps1 -Coverage` | Gera relatórios `lcov.info` nos membros do workspace |
| **Gate de DAG** | `pwsh tools/dag-gate.ps1` | Valida precedência topológica estrita de épicos |
| **Gate Documental**| `pwsh tools/doc-gate.ps1` | Valida hand-offs (`Gate 2.5:`), limites e integridade viva |
| **Docker Local** | `docker compose -f docker/docker-compose.yml up -d` | Sobe PostgreSQL 16 e API Shelf com healthchecks |

---

## 3. Governança de Código & Claims

- **Branch de Trabalho**: Ciclo por Caso de Uso direto em **`develop`** (D-04). A branch `main` é reservada para releases.
- **Poka-Yoke de Claims**: Commits contendo `(UC-XX.YY)` exigem claim ativo prévio via:
  ```bash
  pwsh tools/bin/claims.ps1 claim -slice UC-XX.YY -owner <seu-papel>
  ```
- Mais detalhes em [`docs/plan/state/CLAIMS.md`](docs/plan/state/CLAIMS.md).

---

## 4. Licença

Este projeto está licenciado sob os termos da licença [MIT](LICENSE).
