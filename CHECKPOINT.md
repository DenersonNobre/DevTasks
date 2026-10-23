# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

Projeto DevTasks (Flutter + Serverpod + Postgres, portfólio/demo público).
**EPIC-00 encerrada** (release `v0.1.0` publicada) · **EPIC-01 (Autenticação) em fechamento**.

## Estado verificado (2026-10-23)

- **Consolidadas**: `UC-01.00` (F1.0) · `UC-01.01` (F1.1 cadastro, Arch/Argon2id) ·
  `UC-01.02` (F1.2 login/sessão) · `UC-01.03` (F1.3 logout/guardas) · `UC-01.05` (F1.5 tema/WCAG).
- **`UC-01.06` (F1.6 telas `/login` + `/register`, D-07 MVVM por slice)**:
  - implementação `6cc4ba3` → **Gate 3 rejeitado** (4 bloqueantes: token duplicado no `LoginState`,
    DoD incompleto, inversão `global → modules`, evidência sobredeclarada);
  - correções em `e88e2c4` (e `dcbef49`): `LoginState` sem token, `SessionStore` movido para
    `global/session/`, loading do cadastro + teste de logout, widgets compartilhados, `AppSpacing`,
    mensagem genérica para `InfraFailure`, barrels dentro da camada. **Atenção**: `dcbef49` (docs)
    **não compila** — o rename de `session_store.dart` entrou ali por staging prévio e os 4 imports só
    foram atualizados em `e88e2c4`; a quebra de atomicidade está registrada em `UC-CURRENT.md`;
  - **verde**: app **66/66** testes, `flutter analyze` sem issues; prova negativa reproduzível
    M1=2 / M2=9 / M3=1 falhas (restauração byte-a-byte);
  - **2ª rodada do Gate 3 em andamento** (não declarar aprovado antes do veredito).
- **`UC-01.04` (F1.4 rate limit + validação de fronteira)**: `6807405` (server **62/62** auth,
  **68/68** completo) → **Gate 3 rejeitado** (3 bloqueantes: teto de memória do limiter inexistente,
  alegação falsa sobre 429 via `sendAsRaw`, IDs `INV-SEC` colididos) → correções no **brief 10**.
- **`INV-SEC` canônico** em `docs/architecture/SPEC.md` §3.1 (`13/14/15` registrados; `07` = pin de
  cripto, **não** rate limit). Não criar ID fora da tabela.
- **Push**: `origin/develop` em `6cc4ba3`; `dcbef49` e `e88e2c4` são **locais** (push é opt-in).

## Próximo passo

1. Fechar o **Gate 3 (2ª rodada)** do `UC-01.06`; corrigir o que sobrar.
2. Rodar **Gate 4** (`tools/test.ps1`) da EPIC-01 e só então marcar `F1.4`/`F1.6` como ✅ no épico.
3. **Brief 11** (decisão do PO: **token opaco em DB**) — emissão/validação de sessão no server;
   destrava os adaptadores reais do app (`AuthClient`/`SessionStore` gerados).
4. Push dos commits acumulados **somente** com pedido explícito.

## Travas vivas

- Ciclo em `develop`; commit de UC exige claim ativo; `main` só por release (D-04).
- Push exige pedido explícito + 3 evidências.
- Toolchain: **CLI `serverpod` deve ser `3.4.13`** (o PATH já driftou para 4.0.4 e gerou código
  incompatível); todo `generate` precisa de prova de idempotência.
- `INV-SEC`: fonte única é `SPEC.md` §3.1; seguir o namespace é obrigatório no hand-off (Gate 2.5).
