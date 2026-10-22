# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-00-fundacao.md` §F0.3.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-00.03** — Test Harness & Runner Automatizado Não-Bloqueante (EPIC-00 · F0.3 · `US-0.3.1`).

**Gate 2.5: AVALIADO E APROVADO** — sem superfície sensível de auth, storage ou rede; runner local de automação de testes via script PowerShell (`tools/test.ps1`).

## Interfaces

- Nenhuma porta de domínio nova — runner de testes headless.
- CLI:
  - `powershell.exe -ExecutionPolicy Bypass -File tools/test.ps1 [-Coverage] [-Target <all|app|server>] [-FailFast]` (exit 0 em sucesso, exit ≠ 0 em falha).

## Arquivos-alvo

- `tools/test.ps1` [NEW]
- `tools/tests/test_test_runner.ps1` [NEW]
- `docs/plan/state/UC-CURRENT.md` [MODIFY]
- `docs/plan/epics/epic-00-fundacao.md` [MODIFY]
- `CHECKPOINT.md` [MODIFY]

## Estado de execução

- Claim: liberado pós-consolidação de `UC-00.03`.
- Implementação: GREEN — TDD Red-Before-Green comprovado; Gates 3 e 4 aprovados.

## Evidência (preenchida pelo Coder, Reviewer e QA)

- **Red**:
  - `tools/tests/test_test_runner.ps1` falhou antes da existência de `tools/test.ps1` com exit code 1:
    `RED EXPECTED: tools/test.ps1 does not exist yet.`
- **Green**:
  - Execução de `tools/tests/test_test_runner.ps1` executou com sucesso (exit code 0):
    - Teste 1: Existência de `tools/test.ps1` confirmada.
    - Teste 2: Suíte verde em um comando executou em 36.51s, atendendo com folga à meta NFR-03 (<= 60s).
    - Teste 3: Fail propagation comprovado (`-SimulateFailure` saiu com exit code 1, nunca verde falso).
    - Teste 4: Geração de cobertura com `-Coverage` validada em `solution/app/coverage/lcov.info` e `solution/server/coverage/lcov.info` (tempo: 21.86s).
    - Laudo final: `>>> ALL UC-00.03 ACCEPTANCE TESTS PASSED SUCCESSFULLY! <<<`.
- **Gate 3 (Review / Tech Lead)**: Aprovado — Diff Budget restrito à automação de testes em `tools/` e hand-off de documentação; isolamento de artefatos preservado no `.gitignore`.
- **Gate 4 (QA & Release)**: Laudo Verde empírico (suíte automatizada de aceitação executada com exit code 0).

## Próximo UC

- **UC-00.04** (F0.4 — Governança de Código, VCS, Hooks & Claims; DoR exige F0.3 ✅).
