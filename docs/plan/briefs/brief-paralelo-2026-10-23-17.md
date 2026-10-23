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

- [ ] `docs/plan/epics/epic-01-autenticacao.md` — tabela F1.0–F1.8 atualizada (não apenas texto, mas o status `✅`/`⏳` real).
- [ ] `docs/plan/state/UC-CURRENT.md` — aponta para `UC-01.08` (último UC completo) ou `UC-01.07` (se ainda pendente).
- [ ] `docs/plan/briefs/brief-paralelo-2026-10-23-14.md` — retorno de correções `UC-01.07` (6/8 + 2 resíduos B5/B8) documentado.
- [ ] `docs/plan/briefs/brief-paralelo-2026-10-23-15.md` — calibragem NFR-03 (`-Unit`/`-Integration`) documentada.
- [ ] `docs/plan/briefs/brief-paralelo-2026-10-23-16.md` — coordenação EPIC-01/02 documentada.
- [ ] Todos os claims de `UC-01.04`/`01.07`/`01.08` liberados (`tools/bin/claims release -slice ...`).

---

## 3. DoD — Evidência Obrigatória (Nenhuma declaração `✅` sem todos estes)

### 3.1 F1.4 — Hardening (Rate Limit + Validação) — `UC-01.04`
- [ ] **Leitura**: `docs/plan/epics/epic-01-autenticacao.md` linha F1.4 → `✅` confirmado.
- [ ] **Verificação código**: `solution/server/lib/src/endpoints/auth_endpoint.dart` → `LRU` com teto duro (500 chaves, `INV-SEC-13`) + `clock` obrigatório (`INV-SEC-14`) presentes.
- [ ] **Testes**: `test/unit/auth/rate_limiter_test.dart` passa (todos os casos: limite excedido, clock obrigatório, reset após janela).
- [ ] **Confirmação build**: `build.cmd` (ou `build-tests.cmd`) passa (`dart test test/unit/auth` verde).

### 3.2 F1.6 — Telas de Autenticação (`UC-01.06`)
- [ ] **Leitura**: `docs/plan/epics/epic-01-autenticacao.md` linha F1.6 → `✅`.
- [ ] **Verificação código**: `solution/app/lib/modules/auth/presentation/` → `LoginScreen`, `SignUpScreen`, `RouteGuard` (`global/router/`) presentes.
- [ ] **Design**: `docs/architecture/DESIGN.md` §UI — telas de auth referenciadas (`D-07` MVVM por slice, unidirecional).
- [ ] **Testes**: `flutter test` (unit + widget) verde para `auth` slice.
- [ ] **Docs**: `docs/plan/briefs/brief-paralero-2026-10-23-...` (se existente) contém evidência (`[EVIDÊNCIA]` com Red/Green + asserções).

### 3.3 F1.7 — Sessão Persistida (`UC-01.07`)
- [ ] **Leitura**: `docs/plan/epics/epic-01-autenticacao.md` linha F1.7 → `✅`.
- [ ] **Verificação código**: `solution/app/lib/global/session/session_store.dart` (ou `session/`) + `flutter_secure_storage` no `pubspec.yaml` presentes.
- [ ] **B5 corrigido**: `solution/server/lib/src/modules/auth/me_service.dart` → `findEmailById` retorna `String?` real; **nenhum `email ?? ''`** (grep vazio para `?? ''` no arquivo).
- [ ] **B8 corrigido**: `me_service.dart` → `INV-SEC-16` (nunca `INV-SEC-06`); `devtasks_session.dart` no client **não existe** (`Test-Path` False).
- [ ] **Token opaco**: `devtasks_session.spy.yaml` → `serverOnly: true`; `session_service.dart` implementa `create`/`revoke`/`validate`; `devtasks_session` não está no `client/lib/src/protocol/`.
- [ ] **Testes**: `test/unit/auth/session_token_test.dart` + `auth_endpoint_session_test.dart` verdes (73/73 ou equivalente).

### 3.4 F1.8 — Wiring Real do App (`UC-01.08`)
- [ ] **Leitura**: `docs/plan/epics/epic-01-autenticacao.md` linha F1.8 → `✅`.
- [ ] **Verificação código**: `lib/main.dart` → `onGenerateRoute` + `RouteGuard` presentes; `ServerpodAuthClient` injetado; `SessionStore` (Riverpod) usado no `App`.
- [ ] **Testes**: `flutter test test/integration/app/` (se existente) ou `test/widget/auth/` passa.

### 3.5 NFR-03 (Gate 4) — Calibrado e Verde
- [ ] **Leitura**: `docs/plan/briefs/brief-paralelo-2026-10-23-15.md` → retorno preenchido com `-Unit` (≤60 s) e `-Integration` (≤120 s ou 180 s, conforme decisão do PO).
- [ ] **Verificação código**: `tools/test.ps1` → modos `-Unit` e `-Integration` implementados; `-NoPub` no CI (`ci.yml:43`); `pub get` fora da janela (`L32`).
- [ ] **Teste de evidência**: execução local (`pwsh tools/test.ps1`) retorna exit 0 (não exit 1) com mensagem de orçamento respeitado.

### 3.6 Documentação de Estado
- [ ] `CHECKPOINT.md` atualizado (≤60 linhas, ponteiro, travas vivas, próximo passo) — **no mesmo commit** da mudança.
- [ ] `docs/plan/README.md` (DAG) → `EPIC-01` marcado `✅`; `EPIC-02` ainda `⏳` (não `✅` até EPIC-01 fechar).
- [ ] `docs/plan/state/UC-CURRENT.md` → aponta para o UC corrente (não espelha backlog).
- [ ] `LEARNINGS.md` → se algum aprendizado novo (ex.: NFR-03 separação, `me_service` B8), registrado no nível correto (projeto, não global, a menos que transversal).

---

## 4. Regras (Não Negociáveis)

- [ ] Sem `push` sem pedido explícito.
- [ ] `git add` por path explícito (`git status --short` verificado antes do commit).
- [ ] Commit atômico (`feat:`, `fix:`, `docs:`) com assinatura `(UC-XX.YY)` **apenas se claim ativo** (`tools/bin/claims` verificado).
- [ ] `docs/LEARNINGS.md` / `CHECKPOINT.md` no **mesmo commit** da mudança.
- [ ] Se `Baixa` confiança (`gate-gate25-handoff.ps1` ou `review`): **não declarar ✅**. Se `Alta`: declarar com evidência [`[FATO]` + `Alta` + referência arquivo:linha].
- [ ] `security` subagent (`subagent_type: security`) invocado se tocar superfície sensível (auth, PII, token, upload, webhook) — Gate 2.5 (`SEC-XX`) registrado no `UC-CURRENT.md`.
- [ ] Modelo `openrouter/free` usado (não outra variante).

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
