# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-00-fundacao.md` §F0.7.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-00.07** — Shared Kernel & Primitivos Universais de Domínio (EPIC-00 · F0.7 · `US-0.7.1`).

**Gate 2.5: AVALIADO E APROVADO** — domínio puro do Shared Kernel; sem imports de banco, rede ou frameworks (DIP 100%); `Result<T>` tipado e taxonomia de falhas de negócio da SPEC §6.

## Interfaces

- Kernel Domain Types:
  - `IResult<T, F>` (`Success`, `Failure`, `fold`, `map`, `flatMap`).
  - `IFailure` e taxonomia formal (`ValidationFailure`, `NotFoundFailure`, `InsufficientRoleFailure`, etc.).
  - VOs: `UserId`, `WorkspaceId`, `ProjectId`, `TaskId`, `CommentId`, `NonEmptyString`, `DateOnly`.
  - Port de tempo: `IClock` e `SystemClock`.
- Barrels pontuados (convenção `topics/flutter.md`):
  - `solution/app/lib/global/kernel/.kernel.dart`.

## Arquivos-alvo

- `solution/app/lib/global/kernel/.kernel.dart` [NEW]
- `solution/app/lib/global/kernel/result.dart` [NEW]
- `solution/app/lib/global/kernel/failures.dart` [NEW]
- `solution/app/lib/global/kernel/value_objects.dart` [NEW]
- `solution/app/lib/global/kernel/clock.dart` [NEW]
- `solution/app/test/unit/kernel/kernel_test.dart` [NEW]
- `docs/plan/state/UC-CURRENT.md` [MODIFY]
- `docs/plan/epics/epic-00-fundacao.md` [MODIFY]
- `CHECKPOINT.md` [MODIFY]

## Estado de execução

- Claim: liberado pós-consolidação de `UC-00.07`.
- Implementação: GREEN — TDD Red-Before-Green comprovado; Gates 3 e 4 aprovados.

## Evidência (preenchida pelo Coder, Reviewer e QA)

- **Red**:
  - `flutter test solution/app/test/unit/kernel/kernel_test.dart` falhou antes da implementação do Shared Kernel com exit code 1 (`Type 'IResult' not found`, `Type 'IFailure' not found`, etc.).
- **Green**:
  - Implementação completa dos primitivos em `solution/app/lib/global/kernel/`.
  - Execução de `kernel_test.dart` passou com exit code 0 (`+7: All tests passed!`).
  - `flutter analyze solution/app` passou com exit code 0 (`No issues found!`).
  - `tools/test.ps1 -Coverage` executou a suíte completa de testes em 18.78s com exit code 0.
  - Auditoria DIP: Zero imports de `serverpod`, `http` ou banco no kernel (`Select-String` retornou vazio).
  - Laudo final: `>>> ALL KERNEL TESTS PASSED & DIP 100% VERIFIED <<<`.
- **Gate 3 (Review / Tech Lead)**: Aprovado — Diff Budget estrito ao kernel e testes unitários; convenção de barrels pontuados e prefixos `I-` atendidos; classes puras e imutáveis.
- **Gate 4 (QA & Release)**: Laudo Verde empírico (suíte automatizada de testes executada com exit code 0).

## Próximo UC

- **UC-00.08** (F0.8 — Governança Documental, Gate de DAG & Matriz de Planos: fechamento da EPIC-00; DoR exige F0.4/F0.7 ✅).
