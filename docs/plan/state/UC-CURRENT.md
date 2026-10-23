# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-01-autenticacao.md` §F1.6.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-01.06** — Telas de Autenticação (EPIC-01 · F1.6 · `US-1.6.1`).

**Gate 2.5: INVOKED** — a superfície de auth já foi analisada no ciclo (`SEC-01..08`, `INV-SEC-04/05/06`);
este UC herda as invariantes aplicáveis ao cliente: `INV-SEC-05` (senha/PII **nunca** em log/print),
`INV-SEC-06` (token só via header/cookie — nunca em URL/body de tela) e **dependência** `flutter_riverpod`
coberta pela decisão **D-03** (gerência de estado local, sem superfície de rede própria).

## Escopo (DoD da F1.6)

- Telas `/login` e `/register` com os **4 estados** do `DESIGN` §3 (`idle/loading/error/authenticated`).
- Validação de formulário pelos VOs existentes (`Email`/`Password`).
- Sucesso → estado `authenticated` → `RouteGuard` permite rota privada; logout → volta ao login.
- Testes de **widget** dos 4 estados + unit do controller; nenhuma senha em log.

## Decisões de fatia

1. **Padrão de apresentação: D-07** (`DESIGN` §12/§12.1, commit `fcac2ba`) — **MVVM por slice,
   unidirecional**: 1 caso de uso = 1 ViewModel com estado imutável + intents; View renderiza/despacha;
   Riverpod (D-03) é o **mecanismo**. VM sem `BuildContext`/I/O; sessão em `global/` (o VM observa).
2. **Porta `AuthClient`** (app): `signIn(email, password)` / `signUp(name, email, password)` devolvendo
   os DTOs do contrato ou um `AuthFailure` tipado. O **cliente gerado do Serverpod** é o adaptador real
   (wiring com URL/token = follow-up declarado, pois a emissão de token ainda não existe).
3. **Roteador**: manter o `RouteGuard` puro como contrato. O wiring **estava** no escopo: a
   **descrição da F1.6** diz "aplica o `RouteGuard`" **e** a `TASK-03` lista "wiring do `RouteGuard` +
   testes de widget dos 4 estados" — ou seja, é **escopo não executado, declarado**, não ambiguidade.
   `MaterialApp.routes` **não** consulta o guard (⇒ `/projects` é alcançável sem sessão no app real).
   Wiring (go_router ou `onGenerateRoute`) fica como **follow-up rastreado no épico** (F1.6,
   "Gaps conhecidos").
4. **Qualidade (DoD de código)**: enxuto e otimizado — 1 nível de indentação por método, sem `else` de
   validação, sem números/strings mágicos, VOs para primitivos de negócio, zero comentário-ruído;
   Object Calisthenics + SOLID + Clean Code auditados no Gate 3.

## Interfaces

- `LoginViewModel` / `RegisterViewModel` (`Notifier`, estado imutável + intents) ·
  `LoginState`/`RegisterState` (`idle|loading|error(failure)|authenticated`) · `AuthClient` (porta) ·
  reuso de `SessionController`/`SessionStore` (global).

## Arquivos-alvo

- `solution/app/lib/modules/auth/presentation/**` (controller + telas) [NEW/MODIFY]
- `solution/app/lib/modules/auth/infrastructure/**` (adaptador `AuthClient` — fachada do cliente gerado) [NEW]
- `solution/app/pubspec.yaml` (`flutter_riverpod`) · `pubspec.lock` (workspace) [MODIFY]
- `solution/app/test/unit/auth/**` · `solution/app/test/widget/**` [NEW]

## Estado de execução

- Claim: **ativo** — `UC-01.06`, owner `coder` (paths `solution/app`, hand-off).
- **Implementação: concluída** (fatia única; sem depender de outro agente).
- D-07 registrada em `DESIGN` §12/§12.1 + `AGENTS.md` + F1.6 (commit `fcac2ba`) **antes** do código.
- `SessionController` **movido** para `global/session/` (D-07 regra 4) com providers em
  `session_providers.dart`; imports de `route_guard` e dos 2 testes atualizados.
- Modelo do Coder: `opencode/deepseek-v4.1-flash-free` (orquestrador conduziu a implementação;
  Gates 3/4 auditam em contexto limpo).

## Entregue (arquivos)

- `modules/auth/domain/auth_client.dart` — porta + `AuthSession` (token fora de `toString`).
- `modules/auth/infrastructure/auth_client_provider.dart` — composição (adaptador real = follow-up).
- `modules/auth/presentation/auth_form_status.dart` — `idle|loading|error|completed`.
- `modules/auth/presentation/login/{login_state,login_view_model,login_view}.dart`.
- `modules/auth/presentation/register/{register_state,register_view_model,register_view}.dart`.
- `global/session/{session_controller,session_providers}.dart` · `global/router/app_routes.dart` ·
  `global/shell/private_area_view.dart` · `main.dart` (ProviderScope + rotas).
- `test/support/{fake_auth_client,in_memory_session_store}.dart` ·
  `test/unit/auth/{login,register}_view_model_test.dart` · `test/widget/auth_screens_test.dart`.

## Evidência

```text
[EVIDÊNCIA] (corrigida após Gate 3 — ver §Gate 3 abaixo)
- Leitura: login_view_model.dart:1-55 → valida com VOs, chama a porta e delega a persistência ao
  SessionController (global/); LoginState NÃO carrega token (D-07 §12.1 regra 4).
- Verificação: flutter analyze solution/app/lib solution/app/test → "No issues found!" (5.1 s)
- Confirmação: flutter test (app completo) → 66/66 passed.
- Prova negativa reproduzível (3 mutações isoladas, restauração byte-a-byte):
  M1 remover `sessionController.signIn(...)` no login → 2 falhas
     (unit "sucesso persiste a sessão" + widget "completed: navega e persiste o token")
  M2 `return;` no início de RegisterViewModel.submit → 9 falhas (5 unit + 3 widget de cadastro + loading)
  M3 remover `signOut()` no PrivateAreaView → 1 falha (widget "sair limpa a sessão e volta ao login")
- NOTA: a evidência anterior ("5 falhas") estava ERRADA e foi retirada — a contagem correta é a lista acima.
```

## Gate 3 (veredito e correções)

**Rodada 1: REJEITADO (confiança Alta)** — 4 bloqueantes, todos fechados **no código** na rodada 2
(o revisor reproduziu as 3 mutações por execução, não por relato):

1. `LoginState.session` duplicava o estado transversal e mantinha o token vivo após logout →
   campo **removido**; o sucesso é `status: completed` e a prova é `store.token` +
   `SessionController.state`; teste novo cobre logout limpando a sessão global.
2. DoD incompleto (loading do cadastro + logout sem teste) → adicionados: unit + widget de `loading`
   no cadastro e widget de logout em `PrivateAreaView`.
3. Inversão de camada (`global/session` importava `modules/auth/domain`) → porta `SessionStore`
   **movida** para `global/session/session_store.dart` e reexportada em `.session.dart`; `global/`
   não importa mais `modules/`.
4. Prova negativa sobredeclarada → lista de mutações acima, com contagem real (2/9/1).

Não-bloqueantes aplicados: números mágicos → `AppSpacing`/constantes; `_FormMessage`/`_SubmitButton`
duplicados → `presentation/widgets/auth_form_widgets.dart` (DRY); `InfraFailure` cru na tela →
`authFailureMessage()` com mensagem genérica; rótulo `'Nome'` no VO; barrels movidos para **dentro**
da camada (`.`-prefixed) conforme correção do agente paralelo.

Não corrigidos (declarados): `RouteGuard` ainda não consultado no `main.dart` (wiring de roteador é
follow-up rastreado em F1.6 "Gaps conhecidos"); providers lançam `UnimplementedError` até a borda
injetar adaptadores reais.

### Rodada 2 — novos bloqueantes e correção

1. **`dcbef49` não compila (atomicidade partida, agora REGISTRADA aqui)**: o rename
   `modules/auth/domain/session_store.dart` → `global/session/session_store.dart` entrou no commit de
   **docs** por staging prévio de `git mv`, mas **4 imports** continuavam apontando para o caminho antigo
   (`session_controller.dart`, `test/support/in_memory_session_store.dart`, e os 2 testes de sessão/guard)
   **e** o barrel `modules/auth/.domain.dart` ainda **exportava** o caminho antigo (5ª referência órfã).
   Consequência: `analyze`/`test`/`git bisect` quebram nesse commit; `e88e2c4` fecha a árvore.
   **Histórico não reescrito** (decisão): o defeito é documental, e reescrever um commit em árvore
   compartilhada é risco maior que o benefício.
2. **UTF-8 BOM em 8 arquivos `.dart`** (invisível no diff): `Set-Content -Encoding utf8` do Windows
   PowerShell grava BOM. Removidos byte-a-byte; o padrão do repo é **UTF-8 sem BOM**. Lacuna do gate
   registrada em `LEARNINGS.md` (o pre-commit só reprova arquivo com BOM *e nada mais*).
3. **`_AuthTextField` duplicado** entre as duas views (já divergindo) → promovido a `AuthTextField` em
   `presentation/widgets/auth_form_widgets.dart`, usado pelas duas telas.

### Rodada 3 — veredito

**APROVADO (confiança Alta), zero bloqueantes.** Verificação por medição: BOM nos blobs do HEAD = **0/47**;
`git grep "_AuthTextField"` = **0**; `git cat-file -e dcbef49:<caminho antigo>` = **exit 128** (prova de que
o rename vazou no commit de docs). Advisories aplicados: citação da **`TASK-03`** (o wiring era tarefa
explícita) e registro do **export órfão** no barrel como 5ª referência.

**Próximo**: Gate 4 (harness completo) — só depois marcar `F1.6` ✅ no épico.

## Desvios e follow-ups declarados

- **Adaptador real** `AuthClient` (cliente gerado + URL do server) e **adaptador** `SessionStore`
  (armazenamento local) não existem: os providers lançam `UnimplementedError` até a borda injetá-los.
  Motivo: o servidor ainda **não emite token** (follow-up já registrado na EPIC-01).
- **`signUp` não emite sessão** (contrato `SignUpResultDto`): cadastro conclui com `userId` e volta
  para `/login`; auto-login pós-cadastro fica para quando o token existir.
- **Roteador**: `MaterialApp.routes` nomeadas (sem `go_router`); o `RouteGuard` segue como contrato
  puro testado. **Gap conhecido**: `/projects` é alcançável sem sessão no app real — wiring do guard no
  router está rastreado como follow-up da F1.6 no épico.
- **Rate limit** (`UC-01.04`, brief 09) é do outro agente; a UI mapeia `ERR_RATE_LIMITED` como erro de
  formulário genérico (mensagem do servidor) quando ele entrar.

## Pendências / coordenação

- **`solution/server/**` está com o outro agente** (brief 09 / `UC-01.04`). Não tocar.
- Wiring real `AuthClient`/`SessionStore` + emissão de token = follow-ups declarados.
- `UC-01.04` fecha a EPIC-01 (brief 09 em execução pelo `parallel-agent`).

## Próximo UC

- `UC-01.04` (Hardening de auth) — retomar quando o brief 08 fechar.
