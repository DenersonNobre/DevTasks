# Brief Paralelo 23 — Agente C: port dos módulos puros de Workspace e Projetos

> Data: 2026-10-24 · Épico: `epic-08-migracao-shelf.md` · Base: brief-22 §6 · Decisão: `D-08`
> **Este brief é do Agente C** (o brief-22 cobre A e B).

## 1. Objetivo

Portar para `solution/api` os módulos de **workspace** e **projetos** que são puros (sem transporte),
com testes. É porte mecânico + **uma** adaptação declarada (`WorkspaceEntity`/role).

### 1.1 Claim (primeiro comando do Agente C)

> O validador aceita apenas `UC-XX.YY`. Use **`UC-08.04`** (não `UC-08.04a`) e passe os paths numa
> única linha, separados por vírgula — continuação de linha com backtick no PowerShell quebra o
> comando (o `-Paths` vira argumento posicional).

```powershell
.\tools\bin\claims.ps1 claim -Slice UC-08.04 -Owner "agent-c" -Ttl 120 -Paths "solution/api/lib/src/modules/workspace,solution/api/lib/src/modules/projects,solution/api/test/unit/modules/workspace,solution/api/test/unit/modules/projects"
```

Exit `2` = fatia tomada por outro agente: **aborte**, não edite nada.
Ao terminar (testes verdes), o orquestrador libera com `claims.ps1 release -Slice UC-08.04`.

## 2. Paths exclusivos do Agente C (não escrever fora)

- `solution/api/lib/src/modules/workspace/**`
- `solution/api/lib/src/modules/projects/**`
- `solution/api/test/unit/modules/workspace/**`
- `solution/api/test/unit/modules/projects/**`

**Fronteira com o Agente B**: ele é dono de `lib/src/modules/auth/**` e `test/unit/modules/auth/**`.
Não toque lá. `lib/devtasks_api.dart` (barrel), `pubspec.yaml`, `migrations/`, `lib/src/db/`, `bin/` e `tools/` são do Agente A.

## 3. Arquivos a portar

Origem: `solution/server/lib/src/modules/`

| Origem | Destino | Ação |
|:--|:--|:--|
| `workspace/domain/workspace_name.dart` | `workspace/domain/workspace_name.dart` | **verbatim** |
| `workspace/domain/workspace_entity.dart` | idem | **adaptar** (ver §4) |
| `workspace/ports.dart` | idem | **adaptar** (trocar enum gerado pelo puro) |
| `projects/domain/project_name.dart` | `projects/domain/project_name.dart` | **verbatim** |
| `projects/domain/project_entity.dart` | idem | **verbatim** (já é puro) |
| `projects/ports.dart` | idem | **verbatim** |

**Fora do escopo (não portar agora):** `workspace_service.dart`, `membership_guard.dart`,
`project_service.dart` — todos dependem de DTOs gerados / códigos de erro que serão definidos na
camada de serviço (UC-08.04b/08.05b). Se você os portar, estará criando design não acordado.

## 4. Adaptação declarada (a única permitida)

`workspace_member_role.dart` **novo**, puro: `enum WorkspaceMemberRole { owner, developer, viewer }`
(D-02). Então:
- `workspace_entity.dart`: remover `import '../../generated/protocol.dart'` e trocar
  `toDto()` por `toJson()` devolvendo `Map<String, Object?>` com `id`, `name`, `role`, `createdAt`
  (ISO-8601 UTC). Nenhum DTO de transporte no domínio.
- `workspace/ports.dart`: usar o `WorkspaceMemberRole` puro; `WorkspaceWithRole` continua como está.

Nada além disso. Não renomeie classes, não mude assinaturas, não "melhore" o design.

## 5. Ordem obrigatória (Red-Before-Green)

1. Escreva **primeiro** os testes em `test/unit/modules/{workspace,projects}/`.
2. Rode `cd solution/api; dart test test/unit/modules/workspace test/unit/modules/projects -r compact`
   e **capture a falha** (Red por módulo inexistente). Guarde a contagem.
3. Escreva a lib.
4. Rode de novo até verde.

Testes de origem para portar (mesmas asserções):
- `solution/server/test/unit/workspace/workspace_service_test.dart` → **apenas** o grupo
  `WorkspaceName Value Object`.
- `ProjectName`, `WorkspaceEntity`, `ProjectEntity`, `ProjectRepository`, `WorkspaceRepository` **não têm
  teste de origem** → escreva teste **novo** cobrindo validação (VO) e serialização (`toJson`).

## 6. Proibições

- Editar `pubspec.yaml` (raiz ou `solution/api`), rodar `dart pub get`.
- Rodar git de **mutação** (`add`/`commit`/`checkout`/`restore`/`stash`). `git status` read-only é permitido.
- Alterar lógica, mensagens ou códigos `ERR_*`; afrouxar asserção; importar `package:serverpod`,
  `devtasks_client` ou `package:flutter`.
- Criar arquivos fora dos paths do §2.

## 7. Validação final (obrigatória)

```text
cd solution/api
dart analyze lib/src/modules/workspace lib/src/modules/projects test/unit/modules/workspace test/unit/modules/projects
dart test test/unit/modules/workspace test/unit/modules/projects -r compact
```

Ambos devem passar (analyze sem issues, testes verdes). Se algum arquivo de origem não for portável
sem inventar design, **deixe de fora e relate** — não force.

## 8. Relatório final exigido

(a) arquivos criados:
- `solution/api/lib/src/modules/workspace/domain/workspace_name.dart`
- `solution/api/lib/src/modules/workspace/domain/workspace_entity.dart`
- `solution/api/lib/src/modules/workspace/domain/workspace_member_role.dart` (enum puro: `owner`, `developer`, `viewer` + `toJson()`)
- `solution/api/lib/src/modules/workspace/ports.dart` (`WorkspaceRepository`)
- `solution/api/lib/src/modules/projects/domain/project_name.dart`
- `solution/api/lib/src/modules/projects/domain/project_entity.dart`
- `solution/api/lib/src/modules/projects/ports.dart` (`ProjectRepository`)
- `solution/api/test/unit/modules/workspace/workspace_name_test.dart`
- `solution/api/test/unit/modules/workspace/workspace_entity_test.dart`
- `solution/api/test/unit/modules/projects/project_name_test.dart`
- `solution/api/test/unit/modules/projects/project_entity_test.dart`

(b) saída do Red e do Green:
- **Red**: Falha de compilação capturada no `dart analyze solution/api` (50 issues) pela ausência dos tipos e módulos.
- **Green**: `dart test test/unit/modules/workspace test/unit/modules/projects -r compact` -> 13/13 testes passando.

(c) saída do analyze:
- `dart analyze lib/src/modules/workspace lib/src/modules/projects test/unit/modules/workspace test/unit/modules/projects` -> 0 issues (`No issues found!`).

(d) o que ficou de fora e por quê:
- `workspace_service.dart`, `membership_guard.dart`, `project_service.dart` ficaram fora conforme §3 por dependerem de transporte/DTOs a serem especificados em `08.04b/08.05b`.

(e) confirmação de governança:
- `pubspec.yaml`, `pubspec.lock` e `lib/devtasks_api.dart` mantidos 100% intactos sem mutação externa.

