# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-01-autenticacao.md` §F1.3.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-01.03** — Logout & Guarda de Rotas Privadas (EPIC-01 · F1.3 · `US-1.3.1`).

**Gate 2.5: INVOKED** — reutiliza a análise de auth do ciclo; aplicáveis: `INV-SEC-06` (token só em
header/cookie; nunca em URL), `INV-SEC-04` (respostas de auth não enumeram) e a trava de exposição
(rate limit ainda em `UC-01.04`).

## Escopo (DoD da F1.3)

- **DoD**: teste prova que **cada endpoint privado sem sessão** responde falha tipada de sessão
  (`ERR_NOT_AUTHENTICATED`) — **contrato, não UI**; logout limpa o estado local.
- **TASK-01**: teste Red do guard de sessão (servidor) + guarda de rota (app).
- **TASK-02**: guard no servidor + primeiro endpoint privado de referência (`MeEndpoint`).
- **TASK-03**: logout no app (já existe `SessionController.signOut`) + decisão de rota.

## Decisões de fatia (infra ainda ausente — mesmo padrão dos UCs anteriores)

1. **Server**: porta `SessionAuthenticator` (token → usuário | null) + `SessionGuard` **puro**
   (token vazio/nulo ou inválido → falha `ERR_NOT_AUTHENTICATED`). O `MeEndpoint` é o **endpoint
   privado de referência** (padrão que os endpoints da EPIC-02+ adotam).
2. **App**: `RouteGuard` **puro** (rota privada + sessão ausente → redireciona ao login; autenticado →
   permite). O roteador real (go_router) é decisão do slice de UI — não adiciono dependência aqui.
3. **HTTP 401**: o RPC devolve código tipado; o mapeamento para status HTTP pertence à fachada REST
   (mesma decisão registrada nos UCs anteriores).

## Interfaces

- `SessionGuard(authenticator).requireSession(token)` → `GuardOutcome` (`user` | `code`).
- `MeService(guard?)` → `MeResultDto` (sem guard → `ERR_INFRA_FAILURE`, não finge).
- `RouteGuard.decide({requiresSession, session})` → `RouteDecision.allow | redirectToLogin`.

## Arquivos-alvo

- `solution/server/lib/src/modules/auth/{ports,session_guard,me_service}.dart` [NEW/MODIFY]
- `solution/server/lib/src/endpoints/me_endpoint.dart` + `protocol/me_*.spy.yaml` [NEW]
- `solution/app/lib/global/router/route_guard.dart` [NEW]
- `solution/server/test/unit/auth/**`, `solution/app/test/unit/auth/**` [NEW]

## Estado de execução

- Claim: **ativo** — `UC-01.03`, owner `coder` (paths `solution/app`, `solution/server`, hand-off).
- Modelo do Coder: `opencode/deepseek-v4.1-flash-free` (os 2 coder anteriores estouraram passos →
  implementação conduzida pelo orquestrador, gates independentes).
- Implementação: **não iniciada**.

## Evidência

### Fatia 1 — guard no server (endpoint privado de referência)
- **Red**: `dart test test/unit/auth/session_guard_test.dart` → exit 1 (`session_guard.dart`/porta ausentes).
- **Green**: **4 testes** — token nulo **sem consultar** o authenticator, token vazio, token inválido →
  `ERR_NOT_AUTHENTICATED`; token válido → usuário autorizado.
- `MeEndpoint`/`MeService` = **padrão de referência** para endpoints privados (EPIC-02+); sem guard
  responde `ERR_INFRA_FAILURE` (não finge). DTOs `MeDto`/`MeResultDto` gerados.

### Fatia 2 — guarda de rota no app
- **Red**: `flutter test test/unit/auth/route_guard_test.dart` → exit 1 (arquivo ausente).
- **Green**: **4 testes** — rota privada sem sessão → `redirectToLogin`; autenticada → `allow`;
  pública → `allow`; **após `signOut` volta a redirecionar** (logout integrado ao `SessionController`).

- **Suítes**: server **33 testes** · app auth **24** · `analyze` limpo nos dois · `serverpod generate`
  (CLI 3.4.13) exit 0.
- **Declarado**: roteador real (go_router) e mapeamento HTTP 401 pertencem à fachada/UI (follow-up).

## Pendências / coordenação

- **`tools/**` + persistência/hash** estão com o outro agente (brief 07). Não editar.
- Persistência real, token emitido e roteador (go_router)/UI seguem como follow-up declarado.
- Rate limit (`SEC-02`) → `UC-01.04`.

## Próximo UC

- `UC-01.04` (Hardening de auth: rate limit + validação na fronteira).
