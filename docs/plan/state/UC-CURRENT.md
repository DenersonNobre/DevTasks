# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-08-infra-devops.md`.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-08.07** — Wiring do App & Shell de Navegação Completa (Auditoria R1 / D-07 / D-08).
Dono: Coder. Status: **Concluído ✅**.

## Escopo do UC-08.07 (R1 - Shell & Navegação)

- [x] Módulo `workspace` no frontend (`solution/app/lib/modules/workspace/`):
  - `WorkspaceItem` (VO de exibição e seleção).
  - Porta `IWorkspaceClient` (DIP).
  - Adaptador `HttpWorkspaceClient` (consumindo `GET /workspaces` e `POST /workspaces`).
  - `WorkspaceController` (Riverpod) para estado de seleção de workspace ativo.
  - Barrels pontuados (`.domain.dart`, `.infrastructure.dart`, `.presentation.dart`, `.workspace.dart`).
- [x] Shell `PrivateAreaView` (`solution/app/lib/global/shell/private_area_view.dart`):
  - Conexão reativa com `workspaceControllerProvider`.
  - Seletor de workspace ativo no AppBar via `PopupMenuButton`.
  - Onboarding amigável (`first-workspace-form`) caso o usuário não possua nenhum workspace.
  - Renderização integrada de `ProjectsView` filtrada pelo workspace selecionado.
  - Navegação nativa para `TasksView` ao tocar num projeto e acionamento de `CommentsSheet`.
- [x] Testes & Qualidade:
  - `FakeWorkspaceClient` em `solution/app/test/support/fake_workspace_client.dart`.
  - Teste de integração de jornada ponta a ponta `solution/app/test/widget/navigation_flow_test.dart` (Login ➔ Workspace ➔ Projetos ➔ Tarefas ➔ Comentários).
  - Atualização dos testes de widget em `auth_screens_test.dart` e unitários em `auth_wiring_test.dart` para refletir o shell real de navegação.
  - Suíte de widget do app com 36 testes passando (100% verde).
- [x] Gates completos (`dart analyze`, `tools/contract-gate.ps1`, `tools/test.ps1 -Unit`, `tools/test.ps1 -Database`, `tools/doc-gate.ps1`).

## Evidência da Entrega

Gate 2.5: PULADO (não altera criptografia nem autenticação direta; conecta telas e módulos do cliente).

```text
[EVIDÊNCIA]
1. Leitura:
   - solution/app/lib/modules/workspace/: módulo completo de workspace no app com DIP e Riverpod.
   - solution/app/lib/global/shell/private_area_view.dart: shell real conectando workspace -> projetos -> tarefas -> comentários.
   - solution/app/test/widget/navigation_flow_test.dart: teste de integração de widget da jornada ponta a ponta.
2. Verificação:
   - dart analyze solution/app solution/api (0 issues).
   - pwsh tools/contract-gate.ps1 (23 operações em sincronia 1:1, testes de contrato verdes).
   - flutter test solution/app/test/widget/ (36 testes de widget verdes).
   - pwsh tools/test.ps1 -Unit (336 testes unitários verdes).
   - pwsh tools/test.ps1 -Database (25 testes contra PostgreSQL 18.6 real WSL verdes).
   - pwsh tools/doc-gate.ps1 (100% aprovado).
3. Confirmação:
   - O usuário consegue efetuar login, selecionar/criar workspaces, gerenciar projetos, acessar tarefas/Kanban e interagir com comentários.
   - R1 da auditoria de 2026-10-25 completamente sanado com evidência executável.
```

## Próximo UC

- **Auditoria Bloco A — Item 2: R2 (Decisão INV-04, Midpoint e CHECK no Postgres)**.
- **EPIC-06** — Dashboard (RF-13 / INV-07).
