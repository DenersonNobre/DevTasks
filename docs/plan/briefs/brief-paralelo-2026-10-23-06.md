# Brief paralelo — 2026-10-23 — 06

> **Para**: agente de apoio. **De**: orquestrador.
> **Status**: o brief 05 está em execução (R-01 + drift da CLI). O orquestrador **abriu o `UC-01.02`**
> (Login & Sessão Persistente) — as trilhas abaixo são **disjuntas** do slice em voo.

---

## 1. Congelado enquanto o `UC-01.02` está em voo

`solution/app/lib/modules/auth/**` · `solution/server/lib/src/endpoints/**` ·
`solution/server/lib/src/modules/auth/**` · `docs/plan/state/UC-CURRENT.md` ·
`docs/plan/epics/epic-01-autenticacao.md` · `docs/plan/README.md` · `CHECKPOINT.md`.

> **Não** faça agora: N18 (pacote compartilhado de validação) e persistência (M1) — os dois tocam os
> módulos de auth em voo. Ficam para depois da consolidação do `UC-01.02`.

## 2. Item A (prioridade) — Tema Base & WCAG (D-06), trilha disjunta

Implemente o Design System mínimo, **sem tocar o módulo de auth**:

- `solution/app/lib/global/theme/tokens.dart` — cores (claro/escuro) conforme `DESIGN.md` §2, com
  **referência aos tokens** (não invente hex novos sem registrar a origem).
- `solution/app/lib/global/theme/app_theme.dart` — `ThemeData` claro e escuro (`ColorScheme`,
  tipografia, raios, densidade) a partir dos tokens.
- `solution/app/lib/global/theme/contrast.dart` — função que calcula **contraste WCAG** entre duas
  cores (luminância relativa) — usada pelo teste.
- `solution/app/test/unit/theme/` — testes: (a) **contraste AA**: texto 4.5:1 e grandes 3:1 nos dois
  temas; (b) `ThemeData` resolve `brightness` correto; (c) tokens usados pelo tema são os declarados
  (sem hex órfão).
- Ligação no app: `solution/app/lib/main.dart` passa a usar `AppTheme.light/dark` (wiring mínimo).

**Aceite**: `flutter test test/unit/theme` verde · `flutter analyze solution/app` limpo · nenhum
arquivo do módulo `auth` tocado.

## 3. Item B — Artefatos de evidência (A5 do laudo)

Crie `docs/plan/reviews/evidence/` e versione **artefatos de Red/Green** dos UCs já fechados
(`UC-00.01..08` e `UC-01.00/01`): para cada um, um `.md` curto com o comando, o exit code e o trecho
real (extraído de `LEARNINGS.md`, `UC-CURRENT` histórico e `git log`). **Não invente saída** — se não
houver registro, escreva "não registrado" (o objetivo é honestidade de rastro, não maquiagem).

## 4. Item C — Fila (após o `UC-01.02`)

Persistência (M1: `UNIQUE(email)` + `emailVerified` default + TOCTOU) · pacote compartilhado das regras
(N18: e-mail/política) · UI `/register` · migração para `serverpod_auth_idp_server` (3.5+/4.x).

## Regras
Claim por slice · stage por **path explícito** · sem push sem pedido do PO + 3 evidências · docs no
mesmo commit · retorno com `[EVIDÊNCIA]` (Leitura → Verificação → Confirmação).
