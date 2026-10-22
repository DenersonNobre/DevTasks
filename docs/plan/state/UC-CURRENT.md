# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-00-fundacao.md` §F0.8.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-00.08** — Governança Documental, Gate de DAG & Matriz de Planos (EPIC-00 · F0.8 · `US-0.8.1`).

**Gate 2.5: AVALIADO E APROVADO** — governança documental executável; sem superfície sensível de dados ou rede externa; validação mecânica de hand-off (`Gate 2.5:`), integridade da DAG e baseline de release.

## Interfaces

- Enforcement Documental:
  - `tools/doc-gate.ps1` (validação de `Gate 2.5:` em hand-offs, tamanho de `CHECKPOINT.md` <= 60 linhas e integridade da DAG via `tools/dag-gate.ps1`).
  - `docs/plan/state/CLAIMS.md` (manual e referência do protocolo de concorrência de Casos de Uso).
- Baseline de Release:
  - `README.md` executável da raiz.
  - `CHANGELOG.md` e `LICENSE` (MIT).

## Arquivos-alvo

- `tools/doc-gate.ps1` [NEW]
- `docs/plan/state/CLAIMS.md` [NEW]
- `tools/tests/test_doc_governance.ps1` [NEW]
- `README.md`, `CHANGELOG.md`, `LICENSE` [MODIFY/NEW]
- `docs/plan/README.md` [MODIFY]
- `docs/plan/epics/epic-00-fundacao.md` [MODIFY]
- `docs/plan/state/UC-CURRENT.md` [MODIFY]
- `CHECKPOINT.md` [MODIFY]

## Estado de execução

- Claim: liberado pós-consolidação de `UC-00.08`.
- Implementação: GREEN — TDD Red-Before-Green comprovado; Gates 3 e 4 aprovados.
- **EPIC-00 (FUNDAÇÃO): 100% CONCLUÍDA ✅** (todas as 8 features F0.1 a F0.8 entregues e verificadas).

## Evidência (preenchida pelo Coder, DevOps, Reviewer e QA)

- **Red**:
  - `tools/tests/test_doc_governance.ps1` falhou antes da existência de `tools/doc-gate.ps1` com exit code 1:
    `RED EXPECTED: tools/doc-gate.ps1 does not exist yet.`
- **Green**:
  - Execução de `tools/tests/test_doc_governance.ps1` executou com sucesso (exit code 0):
    - Teste 1: Existência de `tools/doc-gate.ps1`, `CLAIMS.md`, `LICENSE`, `CHANGELOG.md` confirmada.
    - Teste 2: Governança documental atual aprovada (hand-off válido, `CHECKPOINT.md` com 42 linhas, DAG com 8 épicos íntegros).
    - Teste 3: Prova negativa de hand-off rejeitando arquivo sem `Gate 2.5:` com exit code 1.
    - Teste 4: Prova negativa de orçamento de linhas rejeitando checkpoint > 60 linhas com exit code 1.
    - Laudo final: `>>> ALL UC-00.08 ACCEPTANCE TESTS PASSED SUCCESSFULLY! <<<`.
- **Gate 3 (Review / Tech Lead)**: Aprovado — Diff Budget estrito à governança documental executável; README acoplado aos comandos reais da fundação; MIT license adicionada.
- **Gate 4 (QA & Release)**: Laudo Verde empírico (suíte automatizada de aceitação executada com exit code 0).

## Próximo UC

- **UC-01.01** (EPIC-01 · F1.1 · `US-1.1.1` — Cadastro de Usuário & Hash de Senha; DoR exige EPIC-00 ✅).
