# Brief paralelo — 2026-10-23 — 13

> **Para**: agente paralelo (`parallel-agent`) · **De**: orquestrador (`coder`).
> **Fatia**: `UC-02.01` — CRUD de Workspace (EPIC-02 · F2.1) — **server + contrato apenas**.
> **Pré-requisito de épico**: EPIC-01 **✅** (o gate de DAG não permite EPIC-02 com pré-requisito aberto).
> Comece quando o orquestrador avisar que a EPIC-01 fechou — não antes.
> **Escopo físico**: `solution/server/**` + `solution/client/**` (só `serverpod generate`) +
> `solution/server/migrations/**` + o retorno nesta seção. **Fence**: `solution/app/**` (o slice de UI do
> workspace é de outro momento), `docs/architecture/**`, `docs/plan/state/**`, `CHECKPOINT.md`.

## 0. Claim

```powershell
tools\bin\claims.cmd claim -Slice UC-02.01 -Owner parallel-agent `
  -Paths "solution/server/lib/src/endpoints,solution/server/lib/src/modules/workspace,solution/server/test/unit/workspace" -Ttl 240
```

## 1. Escopo (do épico, F2.1) — sem inventar além

**Gherkin canônico**:
- usuário autenticado cria workspace com nome válido → persistido **com papel `owner` para ele** e
  aparece na listagem dele;
- não-membro tentando listar/editar → **`ERR_NOT_FOUND`** (INV-01: nunca 403 de existência).

**DoD**: INV-06 testada (viewer/developer **não** mutam workspace) e listagem **nunca** devolve workspace alheio.

**Fora de escopo nesta fatia** (declarar, não implementar):
- telas `/workspaces` (TASK-03) — virá depois do `UC-01.08` (wiring do app);
- adicionar membros/papéis (`UC-02.02`) e `MembershipGuard` completo (`UC-02.03`) — mas **já modele** a
  membresia, porque a criação precisa gravar o `owner` e a listagem precisa filtrar por membresia;
- arquivamento de workspace (INV-05 é de projeto, não de workspace).

## 2. Gate 2.5 (obrigatório antes do código)

Superfície mais sensível do produto: **isolamento multi-tenant**. Invoque `security` e registre a linha
canônica no retorno. Mínimo esperado:
- `userId` vem **sempre da sessão** (token do `UC-01.07`), **nunca** do body/query (`INV-SEC-06`);
- toda leitura/mutação valida membresia **ativa**; recurso alheio responde **"não encontrado"** (INV-01);
- papel mínimo na fronteira (INV-06 / matriz PRD §7): `owner` muta workspace; `developer`/`viewer` não;
- nenhum ID/`userId`/nome de workspace alheio em mensagem de erro ou log (`INV-SEC-05`);
- criação grava workspace **e** membresia `owner` na **mesma transação** (INV-09: `UNIQUE(workspaceId, userId)`).

IDs `INV-SEC-*` só os da tabela `SPEC.md` §3.1 — se faltar um, **pare e peça**.

## 3. Contrato a implementar

1. **Modelos** (`.spy.yaml` + migração gerada, CLI **3.4.13**):
   - `devtasks_workspace`: `name`, `createdAt` (campos conforme `SPEC` §4 — leia antes; não invente);
   - `devtasks_workspace_member`: `workspaceId`, `userId`, `role` (enum `owner|developer|viewer`, D-02),
     com **índice único** `(workspaceId, userId)` (INV-09).
2. **Portas** (`SPEC` §5): `WorkspaceRepository` + a parte de membresia que a fatia usa (ISP: só o
   necessário; não crie `IRepository` genérico).
3. **Endpoints** (`workspace_endpoint.dart`): criar, editar, listar (e ler um, se necessário para o
   `ERR_NOT_FOUND`); autenticação via `SessionAuthenticator` (`UC-01.07`), não via parâmetro.
4. **Erros tipados** (nunca exceção): `ERR_VALIDATION` (nome vazio/limite), `ERR_NOT_FOUND` (não-membro),
   `ERR_INSUFFICIENT_ROLE` (membro sem papel), `ERR_INFRA_FAILURE` (neutro).
5. **Contrato**: `serverpod generate` **2×** e diff vazio; commite o gerado de `solution/client`.

## 4. TDD Red-Before-Green (prova nos dois estados)

1. `test(workspace): red for owner-only crud` — testes falhando.
2. `feat(workspace): add workspace crud use cases (UC-02.01)` — implementação.

Cobertura mínima (asserção real, sem tautologia):
- criação: workspace persistido **e** `WorkspaceMember(role: owner, userId: <da sessão>)` na mesma operação;
  `userId` vindo do body é **ignorado/rejeitado** (prove);
- listagem: usuário A não vê workspace de B (asssert de ausência, não de tamanho apenas);
- edição: `owner` edita; `developer` recebe `ERR_INSUFFICIENT_ROLE`; não-membro recebe `ERR_NOT_FOUND`
  (**mesma** resposta para workspace inexistente e alheio — prove a indistinção);
- validação de nome: vazio → `ERR_VALIDATION` com `field`; e nenhuma escrita no banco;
- log: nenhuma linha com nome de workspace alheio/`userId` de terceiro.

## 5. Evidência exigida no retorno

```text
## Retorno — UC-02.01 (CRUD workspace)
Gate 2.5: INVOKED — <INV-SEC-XX>
### Arquivos
- <path> [NEW/MODIFY] (inclua migração + gerado de solution/client)
### [EVIDÊNCIA] Criação atômica
- Red: <falha real> · Green: <N/N> · prova owner+transação: <assert>
### [EVIDÊNCIA] Isolamento
- <assert não-membro == inexistente (indistinção) + developer → ERR_INSUFFICIENT_ROLE>
### [EVIDÊNCIA] Contrato
- `serverpod generate` 2× → diff vazio · `dart analyze` → <ok> · `dart test test/unit/workspace` → <N/N>
### Desvios e limitações declaradas
- <itens>
### Follow-ups
- telas `/workspaces` (app) · `UC-02.02` · `UC-02.03`
```

## 6. Proibições

- Não tocar `solution/app/**` nesta fatia (UI depois, em slice próprio).
- Não editar `solution/client/**` à mão; não alterar `solution/server/lib/src/modules/auth/**` além do
  consumo do `SessionAuthenticator` (se precisar mudar auth, **pare e reporte**).
- Sem push. Stage por path explícito.
