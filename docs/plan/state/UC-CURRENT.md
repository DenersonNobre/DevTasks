# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-00-fundacao.md` §F0.2.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-00.02** — Toolchain, Automação de Build Local & Idempotência (EPIC-00 · F0.2 · `US-0.2.1`).

**Gate 2.5: AVALIADO E APROVADO** — sem superfície sensível de auth ou rede externa; automação de build e toolchain local via scripts PowerShell (`tools/build.ps1`, `tools/clean.ps1`).

## Interfaces

- Nenhuma porta de domínio nova — infraestrutura de esteira/build local.
- CLI:
  - `powershell.exe -ExecutionPolicy Bypass -File tools/build.ps1 [-PreflightOnly] [-SkipClientGen]` (exit 0 em sucesso, exit ≠ 0 em erro com fail-fast).
  - `powershell.exe -ExecutionPolicy Bypass -File tools/clean.ps1` (exit 0, idempotente).

## Arquivos-alvo

- `tools/build.ps1` [NEW]
- `tools/clean.ps1` [NEW]
- `tools/tests/test_build_scripts.ps1` [NEW]
- `docs/plan/state/UC-CURRENT.md` [MODIFY]
- `docs/plan/epics/epic-00-fundacao.md` [MODIFY]
- `CHECKPOINT.md` [MODIFY]

## Estado de execução

- Claim: liberado pós-consolidação de `UC-00.02`.
- Implementação: GREEN — TDD Red-Before-Green comprovado; Gates 3 e 4 aprovados.

## Evidência (preenchida pelo Coder, Reviewer e QA)

- **Red**:
  - `tools/tests/test_build_scripts.ps1` falhou antes da existência dos scripts com exit code 1:
    `RED EXPECTED: tools/build.ps1 does not exist yet.`
- **Green**:
  - Execução de `tools/tests/test_build_scripts.ps1` executou com sucesso (exit code 0):
    - Teste 1: Existência dos scripts comprovada.
    - Teste 2: Preflight da toolchain (Flutter 3.47.6 >= 3.47.0, Dart 3.13.5 >= 3.13.0) -> exit 0.
    - Teste 3: Fail-fast em ambiente quebrado (`-SimulateMissingFlutter`) -> exit 1 com mensagem de erro clara no stderr.
    - Teste 4: Build completo (`flutter pub get` + `flutter analyze solution/app` + `flutter analyze solution/server`) -> exit 0 (0 issues).
    - Teste 5: Clean idempotente (duas execuções consecutivas removem caches sem tocar em fontes) -> exit 0.
    - Laudo final: `>>> ALL UC-00.02 ACCEPTANCE TESTS PASSED SUCCESSFULLY! <<<`.
- **Gate 3 (Review / Tech Lead)**: Aprovado — Diff Budget estritamente limitado à pasta `tools/` e hand-off de documentação; sem acoplamentos de domínio.
- **Gate 4 (QA & Release)**: Laudo Verde empírico (suíte automatizada de aceitação executada com exit code 0).

## Próximo UC

- **UC-00.03** (F0.3 — Test Harness & Runner Automatizado Não-Bloqueante; DoR exige F0.2 ✅).
