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
- **Implementação: não iniciada** — segurando para não disputar o `pubspec.lock` do workspace com o
  brief 08 do outro agente (que adicionará `pointycastle` no server). Liberar quando ele fechar.
- D-07 registrada em `DESIGN` §12/§12.1 + `AGENTS.md` + F1.6 (commit `fcac2ba`) **antes** do código.
- Modelo do Coder: `opencode/deepseek-v4.1-flash-free` (os anteriores estouraram passos; orquestrador
  conduz a implementação e os Gates 3/4 auditam).

## Evidência

- Red/Green: a preencher.

## Pendências / coordenação

- **`solution/server/**` está com o outro agente** (brief 08: persistência + Argon2id). Não tocar.
- Wiring real do `AuthClient` (URL do server + token) e router (go_router) = follow-ups declarados.
- `UC-01.04` (rate limit) segue **bloqueado por colisão** com o brief 08 — abre depois.

## Próximo UC

- `UC-01.04` (Hardening de auth) — retomar quando o brief 08 fechar.
