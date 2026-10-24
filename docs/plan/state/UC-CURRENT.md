# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-08-migracao-shelf.md`.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-08.03** — Auth no servidor shelf (parte 1: módulos puros). Status: **Concluído ✅** (parte 2 = repositórios SQL + rotas, pendente).

**Gate 2.5: PULADO nesta parte** — porte sem alteração de lógica; as invariantes de segurança
(`INV-SEC-04/05/08/10/13/16/17`) são cobertas pelos testes portados e permanecem asserções executáveis.

## Escopo (parte 1 do UC-08.03)

- [x] 9 arquivos portados: `argon2_password_hasher`, `rate_limiter`, `session_guard`, `sign_in_handler`,
      `sign_up_handler`, `session_service` (ex-`serverpod_session_service`), `ports`, `domain/email`, `domain/password`.
- [x] 6 arquivos de teste em `test/unit/modules/auth/` (inclui `session_service_test` novo e `sign_up_handler_test` portado).
- [x] Zero imports de `serverpod`/`devtasks_client`/`flutter` no módulo (verificado por grep).
- [ ] Parte 2: `UserRepository`/`SessionRepository` SQL + rotas HTTP + `Bearer` middleware.

## Coordenação — dois fatos que custaram tempo (registrados)

1. **`claims` rejeita sufixo**: só aceita `UC-XX.YY`. `UC-08.03a` → `[CLAIMS-ERROR] Slice inválido`.
   Sub-fatias agora são recorte de *paths* no brief, nunca no ID.
2. **Claim preso no próprio subagente**: o agente `coder` reservou `UC-08.03` e terminou sem liberar.
   O orquestrador liberou explicitamente (`release`) antes de reclamar — decisão declarada, não
   auto-reap silencioso.
3. **Continuação de linha com backtick no PowerShell** quebrou o comando do brief-23: `-Paths` virou
   argumento posicional literal. Comando de claim agora é linha única.

## Evidência

```text
[EVIDÊNCIA] (UC-08.03 · parte 1)
- Verificação: grep de imports proibidos em lib/src/modules/auth → nenhum resultado.
- Verificação: dart analyze lib/src/modules/auth test/unit/modules/auth lib/devtasks_api.dart → No issues found.
- Confirmação: dart test test/unit/modules/auth → 50/50 passed.
- Defeito encontrado e corrigido: teste de CSPRNG usava TokenGenerator(Random(42)) e asseria tokens
  distintos — fixture incoerente. Passou a usar o gerador seguro real; a propriedade agora é provada.
```

## Próximo passo

1. **`UC-08.03` parte 2** (repositórios SQL + rotas de auth) — depende de Postgres para prova real.
2. **`UC-08.04`** (Agente C, em voo): port de workspace/projects puros.
3. Bloqueio transversal: Postgres ausente ⇒ sem prova de persistência/E2E.
