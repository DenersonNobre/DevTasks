# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-00-fundacao.md` §F0.6.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-00.06** — Pipeline de CI/CD Contínuo (Shift-Left Gate) (EPIC-00 · F0.6 · `US-0.6.1`).

**Gate 2.5: AVALIADO E APROVADO** — sem superfície sensível de auth ou dados de produção; automação declarativa de CI/CD via GitHub Actions e Gitea Actions em paridade, com gate de DAG acoplado.

## Interfaces

- CI/CD Workflows:
  - `.github/workflows/ci.yml` (GitHub Actions em paridade Day 1).
  - `.gitea/workflows/ci.yml` (Gitea Actions primário).
- Enforcement mecânico da DAG:
  - `tools/dag-gate.ps1` (validação determinística de precedência topológica da DAG de épicos).
  - `tools/tests/test_ci_pipeline.ps1` (suíte automatizada de validação dos workflows e do gate de DAG).

## Arquivos-alvo

- `tools/dag-gate.ps1` [NEW]
- `.github/workflows/ci.yml` [NEW]
- `.gitea/workflows/ci.yml` [NEW]
- `tools/tests/test_ci_pipeline.ps1` [NEW]
- `docs/plan/state/UC-CURRENT.md` [MODIFY]
- `docs/plan/epics/epic-00-fundacao.md` [MODIFY]
- `CHECKPOINT.md` [MODIFY]

## Estado de execução

- Claim: liberado pós-consolidação de `UC-00.06`.
- Implementação: GREEN — TDD Red-Before-Green comprovado; Gates 3 e 4 aprovados.

## Evidência (preenchida pelo Coder, DevOps, Reviewer e QA)

- **Red**:
  - `tools/tests/test_ci_pipeline.ps1` falhou antes da existência dos workflows com exit code 1:
    `RED EXPECTED: tools/dag-gate.ps1 does not exist yet.`
- **Green**:
  - Execução de `tools/tests/test_ci_pipeline.ps1` executou com sucesso (exit code 0):
    - Teste 1: Existência de `tools/dag-gate.ps1`, `.github/workflows/ci.yml` e `.gitea/workflows/ci.yml` confirmada.
    - Teste 2: Gate de DAG executado na topologia canônica atual com exit 0 (8 épicos mapeados e arquivos presentes).
    - Teste 3: Teste negativo de violação de precedência da DAG comprovado (exit 1 quando EPIC-03 ✅ com EPIC-02 ⏳).
    - Teste 4: Paridade estrita comprovada entre GitHub Actions e Gitea Actions (triggers `develop`/`main`, steps clean-room, analyze, test runner, dag gate e docker build).
    - Laudo final: `>>> ALL UC-00.06 ACCEPTANCE TESTS PASSED SUCCESSFULLY! <<<`.
- **Gate 3 (Review / Tech Lead)**: Aprovado — Diff Budget estrito a workflows, gate de DAG e documentação; sem dívida ativa de workflow não executável.
- **Gate 4 (QA & Release)**: Laudo Verde empírico (suíte automatizada de aceitação executada com exit code 0).

## Próximo UC

- **UC-00.07** (F0.7 — Shared Kernel & Primitivos Universais de Domínio: `Result<T>`, VOs, clock; DoR exige F0.1/SPEC ✅).
