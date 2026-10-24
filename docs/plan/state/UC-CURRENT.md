# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-08-migracao-shelf.md`.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-08.07** — App desacoplado do transporte (adaptadores HTTP + remoção de `devtasks_client`).
Dono: este agente. Status: **Em execução 🔄**.

**UC-08.04** (workspace/projects) — **handover para o outro agente** (brief-24). O port entregue em
`296d91a` ainda tem `id` **int** e `createdAt` **opcional**: divergência com o contrato, correção
especificada no brief-24 (UUID + campo obrigatório). Claim liberado; a fatia é dele.

**UC-08.03** (auth) — parte 1 concluída (`18410a3`, 50/50). Parte 2 (repositórios SQL + rotas) pendente.

## Incidente de concorrência (registrado, não maquiado)

Dois escritores no mesmo slice (`modules/{workspace,projects}`) entre 11:48 e 11:49. Sintoma clássico:
arquivo já gravado voltou ao conteúdo anterior (`workspace_entity` reverteu `String id` → `int id`) e
o worktree passou a divergir do index. **Resolução do PO**: um único dono por slice; este agente
liberou `UC-08.04` e saiu do path. Nenhum trabalho foi commitado em estado misturado.

Regra que passa a valer: **um agente por slice + stage por path + conferir `git diff --cached`** antes
de commitar. `claims` é coordenação, não cerca.

## Decisão do PO registrada (`D-08`, consequência 5)

**IDs são UUID** (`uuid` no Postgres, `String` no Dart) e `createdAt` é obrigatório onde o contrato
exige. Motivo: contrato declara `format: uuid` (11 pontos) e id sequencial em API pública permite
enumeração. Aplicação do lado servidor: brief-24 (outro agente).

## Escopo do UC-08.07

- [ ] Substituir `serverpod_auth_client.dart` por adaptador `http` falando o contrato (`/auth/*`, `/me`).
- [ ] Substituir `serverpod_project_client.dart` por adaptador `http` (`/workspaces/{id}/projects`, `/projects/{id}`).
- [ ] Adicionar `http` às dependências do app e **remover** `devtasks_client`.
- [ ] Manter `IResult`/`IFailure` e o mapeamento de `errorCode` → failure tipada.
- [ ] `flutter test` verde **sem** o pacote `devtasks_client` instalado.

## Evidência já disponível (não do UC-08.07)

```text
[EVIDÊNCIA] (pacote api, antes do handover)
- dart analyze → No issues found
- dart test → 106 passed, 4 skipped (integração de banco sem DEVTASKS_TEST_DATABASE_URL)
```

## Pendências declaradas

1. `solution/api/analysis_options.yaml` ausente → pacote sem lints (mais fraco que app/server).
2. Integração real de banco bloqueada: sem Postgres na máquina.
3. Gate de contrato só valida forma (rotas/`$ref`), **não tipos por campo** — foi assim que
   `uuid` × `bigserial` passou; o `UC-08.06b` precisa validar payload.
