# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-08-migracao-shelf.md`.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-08.02** — Persistência (migrations + pool + runner) · `EPIC-08 · F8.2`. Status: **Concluído ✅ (com pendência declarada)**.

**Gate 2.5: PULADO** — schema novo, sem superfície de auth. Cercas de invariante aplicadas no DDL
(`UNIQUE (email)` INV-08, `CHECK role` INV-06, `UNIQUE (workspace_id,user_id)` INV-09, FKs `ON DELETE CASCADE` INV-01).

## Escopo (DoD da F8.2)

- [x] `migrations/0001_initial.sql` com as 5 tabelas + índices + cercas de invariante.
- [x] `loadMigrations` determinístico (`<versao>_<nome>.sql`), recusa versão duplicada/não numérica.
- [x] `Migrator.up()` idempotente, ordem por versão, `skipped` correto.
- [x] `SqlMigrationStore` em `schema_migrations` (`ON CONFLICT DO NOTHING`).
- [x] `tools/db.ps1` (`up|status|reset`, reset exige `-Force` + `DEVTASKS_ALLOW_RESET=true`).
- [ ] **Prova contra Postgres real** — bloqueada: não há banco na máquina. Teste de integração existe
      e é **declaradamente pulado** sem `DEVTASKS_TEST_DATABASE_URL`. Nada de "validado" sem isso.

## Interfaces & Portas

- `SqlExecutor` (`execute`/`query`) + `PgSqlExecutor` + `openPool(dsn)`.
- `MigrationStore` (`ensureReady`/`appliedVersions`/`markApplied`) + `SqlMigrationStore`.
- `Migrator({sql, store, migrations})` → `MigrationReport(applied, skipped)`.
- `loadMigrations(Directory)` → `List<Migration>`, com `MigrationFormatException`.

## Bug encontrado e corrigido (pelo teste)

`MigrationReport.skipped` lia o tamanho da coleção **viva** devolvida pelo store (aliasing): após
marcar, `skipped` virava o total. Corrigido com snapshot (`{...appliedVersions()}`) e cálculo antes do
loop. O teste que pegou isso permanece (migrator: "aplica pendentes em ordem...").

## Evidência

```text
[EVIDÊNCIA] (UC-08.02)
- Verificação: dart analyze lib/src/db bin/migrate.dart test/unit/db test/integration/db → No issues found.
- Confirmação: dart test test/unit/db → 20/20 passed.
- Cobertura: ordem por versão, skip de aplicadas, idempotência, duplicata recusada, loader (padrão,
  ordenação, arquivo inválido, versão não numérica, diretório ausente), DDL (5 tabelas + cercas).
- Pendente: integração real (skip explícito sem DEVTASKS_TEST_DATABASE_URL).
```

## Próximo passo

1. **`UC-08.03a` em voo** (Agente B): port do módulo auth base para `solution/api/lib/src/modules/auth/**`.
2. Depois: `08.03b` repositórios SQL + rotas → `08.04` → `08.05` → `08.06b` (gate de contrato) → `08.07` (app) → `08.08`.
3. **Bloqueio transversal**: para validar persistência e E2E precisamos de Postgres (Docker, binário portátil sem admin, ou hospedado).
