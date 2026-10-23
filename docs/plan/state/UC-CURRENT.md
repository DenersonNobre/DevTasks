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
3. **Roteador**: manter o `RouteGuard` puro como contrato; o router real (go_router) é dependência nova
   → **não** entra neste UC sem decisão explícita (o DoD não exige; o guard já é testável).
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
[EVIDÊNCIA]
- Leitura: login_view_model.dart:28-60 → valida com VOs (Email/Password), chama a porta e persiste
  a sessão via SessionController; nenhum BuildContext/I/O no VM (D-07).
- Verificação: flutter analyze solution/app/lib solution/app/test → "No issues found!" (2 items, 8.5 s)
- Confirmação: flutter test (app completo) → 62/62 passed; nos arquivos da fatia → 42/42 passed.
- Prova negativa (mutação controlada): remover a persistência da sessão no login + early-return no
  submit do cadastro → 5 falhas reais (ex.: `Expected: 'tok-123'  Actual: <null>`), restaurado → verde.
```

## Desvios e follow-ups declarados

- **Adaptador real** `AuthClient` (cliente gerado + URL do server) e **adaptador** `SessionStore`
  (armazenamento local) não existem: os providers lançam `UnimplementedError` até a borda injetá-los.
  Motivo: o servidor ainda **não emite token** (follow-up já registrado na EPIC-01).
- **`signUp` não emite sessão** (contrato `SignUpResultDto`): cadastro conclui com `userId` e volta
  para `/login`; auto-login pós-cadastro fica para quando o token existir.
- **Roteador**: `MaterialApp.routes` nomeadas (sem `go_router`); o `RouteGuard` segue como contrato
  puro testado — wiring no router é decisão futura.
- **Rate limit** (`UC-01.04`, brief 09) é do outro agente; a UI mapeia `ERR_RATE_LIMITED` como erro de
  formulário genérico (mensagem do servidor) quando ele entrar.

## Pendências / coordenação

- **`solution/server/**` está com o outro agente** (brief 09 / `UC-01.04`). Não tocar.
- Wiring real `AuthClient`/`SessionStore` + emissão de token = follow-ups declarados.
- `UC-01.04` fecha a EPIC-01 (brief 09 em execução pelo `parallel-agent`).

## Próximo UC

- `UC-01.04` (Hardening de auth) — retomar quando o brief 08 fechar.
