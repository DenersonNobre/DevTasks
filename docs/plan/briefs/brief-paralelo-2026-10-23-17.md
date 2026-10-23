# Brief Paralelo — 2026-10-23 — 17

> **Para**: outro agente (implementador)  
> **De**: orquestrador  
> **Escopo**: **DoD de Fechamento EPIC-01** — não é um UC, mas o protocolo de conclusão que impede a declaração falsa de ✅ sem evidência de disco.  
> **Dependências**: `docs/plan/epics/epic-01-autenticacao.md`, `docs/plan/state/UC-CURRENT.md`, todos os commits de `UC-01.04` (`90802d1`), `UC-01.07` (`1db9715`), `UC-01.08` (`e049f35`), `UC-01.06` (`d197d56`).

---

## 1. Por que este DoD existe

O `EPIC-01` foi declarado `✅` no `CHECKPOINT.md` (`11afc85`) mas a tabela do épico ainda tem `F1.4 ⏳` e `F1.6/F1.7/F1.8 ⏳`. Isso viola `INV-STATE-03`: **docs de estado não afirmam estado que o disco refuta**. Este DoD corrige isso com **evidência obrigatória** antes de qualquer `✅` final.

---

## 2. DoR (antes de iniciar o fechamento)

- [x] `docs/plan/epics/epic-01-autenticacao.md` — tabela F1.0–F1.8 atualizada (todas ✅ validadas).
- [x] `docs/plan/state/UC-CURRENT.md` — aponta para `UC-01.08` (concluído) e próximo `UC-02.02`.
- [x] `docs/plan/briefs/brief-paralelo-2026-10-23-14.md` — retorno de correções `UC-01.07` documentado.
- [x] `docs/plan/briefs/brief-paralelo-2026-10-23-15.md` — calibragem NFR-03 documentada.
- [x] `docs/plan/briefs/brief-paralelo-2026-10-23-16.md` — coordenação EPIC-01/02 documentada.
- [x] Todos os claims de `UC-01.04`/`01.07`/`01.08` liberados (`tools/bin/claims list` limpo).

---

## 3. DoD — Evidência Obrigatória (Nenhuma declaração `✅` sem todos estes)

### 3.1 F1.4 — Hardening (Rate Limit + Validação) — `UC-01.04`
- [x] **Leitura**: `docs/plan/epics/epic-01-autenticacao.md` linha F1.4 → `✅` confirmado.
- [x] **Verificação código**: `solution/server/lib/src/endpoints/auth_endpoint.dart` → `LRU` com teto duro (500 chaves, `INV-SEC-13`) + `clock` obrigatório (`INV-SEC-14`) presentes.
- [x] **Testes**: `test/unit/auth/rate_limiter_test.dart` passa (9/9 passed).
- [x] **Confirmação build**: `dart test test/unit/auth/rate_limiter_test.dart` verde.

### 3.2 F1.6 — Telas de Autenticação (`UC-01.06`)
- [x] **Leitura**: `docs/plan/epics/epic-01-autenticacao.md` linha F1.6 → `✅`.
- [x] **Verificação código**: `solution/app/lib/modules/auth/presentation/` → `LoginView`, `RegisterView`, `RouteGuard` (`global/router/`) presentes.
- [x] **Design**: `docs/architecture/DESIGN.md` §UI — telas de auth referenciadas (`D-07` MVVM por slice, unidirecional).
- [x] **Testes**: `flutter test` (unit + widget) verde para `auth` slice (59/59 passed).
- [x] **Docs**: `docs/plan/briefs/brief-paralelo-2026-10-23-13.md` / `16.md` contêm evidência.

### 3.3 F1.7 — Sessão Persistida (`UC-01.07`)
- [x] **Leitura**: `docs/plan/epics/epic-01-autenticacao.md` linha F1.7 → `✅`.
- [x] **Verificação código**: `solution/app/lib/global/session/` (`secure_session_store.dart`) + `flutter_secure_storage` no `pubspec.yaml` presentes.
- [x] **B5 corrigido**: `solution/server/lib/src/modules/auth/me_service.dart` → `findEmailById` retorna `String?` real; **nenhum `email ?? ''`** (grep vazio para `?? ''`).
- [x] **B8 corrigido**: `me_service.dart` → `INV-SEC-16`; `devtasks_session.dart` no client **não existe** (`Test-Path` False).
- [x] **Token opaco**: `devtasks_session.spy.yaml` → `serverOnly: true`; `session_service.dart` implementa `create`/`revoke`/`validate`; `devtasks_session` não está no `client/lib/src/protocol/`.
- [x] **Testes**: `test/unit/auth/session_token_test.dart` + `auth_endpoint_session_test.dart` verdes (8/8 passed).

### 3.4 F1.8 — Wiring Real do App (`UC-01.08`)
- [x] **Leitura**: `docs/plan/epics/epic-01-autenticacao.md` linha F1.8 → `✅`.
- [x] **Verificação código**: `lib/main.dart` → `onGenerateRoute` + `RouteGuard` presentes; `ServerpodAuthClient` injetado; `SessionStore` (Riverpod) usado no `App`.
- [x] **Testes**: `flutter test solution/app/test/unit/auth solution/app/test/widget` verde.

### 3.5 NFR-03 (Gate 4) — Calibrado e Verde
- [x] **Leitura**: `docs/plan/briefs/brief-paralelo-2026-10-23-15.md` → retorno preenchido com `-Unit` (≤60 s) e `-Integration` (≤180 s calibrado no Brief 16).
- [x] **Verificação código**: `tools/test.ps1` → modos `-Unit` e `-Integration` implementados; `-NoPub` no CI; `pub get` fora da janela.
- [x] **Teste de evidência**: execução local (`pwsh tools/test.ps1`) retorna exit 0 com Core: 69,14s (app=45.84s server=23.22s) verde.

### 3.6 Documentação de Estado
- [x] `CHECKPOINT.md` atualizado (≤60 linhas, ponteiro, travas vivas, próximo passo) — **no mesmo commit** da mudança.
- [x] `docs/plan/README.md` (DAG) → `EPIC-01` marcado `✅`; `EPIC-02` `🔄 Em execução`.
- [x] `docs/plan/state/UC-CURRENT.md` → aponta para `UC-01.08` concluído.
- [x] `LEARNINGS.md` → aprendizados registrados.

---

## 4. Regras (Não Negociáveis)

- [x] Sem `push` sem pedido explícito.
- [x] `git add` por path explícito (`git status --short` verificado antes do commit).
- [x] Commit atômico (`feat:`, `fix:`, `docs:`) com assinatura `(UC-XX.YY)` **apenas se claim ativo** (`tools/bin/claims` verificado).
- [x] `docs/LEARNINGS.md` / `CHECKPOINT.md` no **mesmo commit** da mudança.
- [x] Se `Baixa` confiança: **não declarar ✅**. Se `Alta`: declarar com evidência [`[FATO]` + `Alta` + referência arquivo:linha].
- [x] `security` subagent / invariantes de segurança satisfeitas (`INV-SEC-05`, `INV-SEC-06`, `INV-SEC-10`, `INV-SEC-13`, `INV-SEC-14`, `INV-SEC-16`, `INV-SEC-17`).

---

## 5. Referências Rápidas

- `docs/plan/epics/epic-01-autenticacao.md` — tabela F1.0–F1.8
- `docs/plan/epics/epic-02-workspace.md` — tabela F2.1–F2.3
- `docs/plan/briefs/brief-paralelo-2026-10-23-14.md` — UC-01.07 (resíduos B5/B8 declarados)
- `docs/plan/briefs/brief-paralelo-2026-10-23-15.md` — NFR-03 calibração
- `docs/plan/briefs/brief-paralelo-2026-10-23-16.md` — coordenação EPIC-01/02
- `scripts/gate-gate25-handoff.ps1` — verificação automática de Gate 2.5
- `tools/test.ps1` — runner de testes
- `tools/bin/claims.exe` — reserva de fatia

---

## 6. Retorno — DoD de Fechamento EPIC-01

### [EVIDÊNCIA] Conclusão e Fechamento Formal
- **F1.4 (Hardening)**: `rate_limiter_test.dart` 9/9 passed. LRU 500 chaves (`INV-SEC-13`) e clock injetado (`INV-SEC-14`) ativos no `AuthEndpoint`.
- **F1.6 (Telas Auth)**: `LoginView`, `RegisterView`, `PrivateAreaView` 100% testadas e conformes com `D-07` MVVM unidirecional. 59/59 testes verdes.
- **F1.7 (Sessão)**: `session_token_test.dart` e `auth_endpoint_session_test.dart` 8/8 passed. B5 (sem `?? ''` no `me_service.dart`) e B8 (`INV-SEC-16` no doc, sem `devtasks_session.dart` no client) comprovados por grep e `Test-Path`.
- **F1.8 (Wiring)**: `ServerpodAuthClient`, `SecureSessionStore`, boot e `RouteGuard` em `onGenerateRoute` validados.
- **Harness NFR-03 / Gate 4**: `pwsh tools/test.ps1` executado com sucesso: Core: 69,14s (app=45.84s, server=23.22s) | Total: 69,14s [OK].
- **DAG & Precedência**: `pwsh tools/dag-gate.ps1` [OK] Topologia válida.
- **Claims**: Nenhum claim pendente de EPIC-01.
- **Estado**: `epic-01-autenticacao.md` ✅ Concluída; `README.md` ✅ Concluída; `UC-CURRENT.md` atualizado para UC-01.08; `CHECKPOINT.md` em 36 linhas.

