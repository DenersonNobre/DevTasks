# Brief de trabalho paralelo — DevTasks (enquanto o UC-01.00 está em consolidação)

> **Para**: outro agente (Coder/DevOps ou QA).
> **De**: orquestrador do ciclo EPIC-01.
> **Data**: 2026-10-22.

---

## 1. Contexto

- **Repo**: `A:\Projetos\flutter\portfolio\devtasks` · branch **`develop`** · HEAD **`0e57b38`**
  (release `v0.1.0` publicada nos dois remotes: `origin` Gitea LAN + `github`).
- **EPIC-00 encerrada**; **EPIC-01 (Autenticação) aberta**. Auditoria de QA em
  `docs/plan/reviews/qa-review-v0.1.0.md` (26 achados; P0/P1 resolvidos; 5 seguem abertos).
- **Em voo agora (NÃO TOCAR)**: o slice **`UC-01.00` (F1.0 — Wiring do Stack Serverpod)** está
  **não commitado** na árvore. Gates 3 e 4 já passaram; falta a consolidação (commit + `claims release`).

## 2. Regras de convivência (obrigatórias)

1. **OP-01**: 1 Coder ativo por vez. Você entra em trabalho **disjunto** (abaixo).
2. **Claim antes de mutar**: `tools\bin\claims.cmd claim -Slice <UC-XX.YY> -Owner <papel>`
   (o shim atual aceita `-Action -Slice -Owner -Ttl`; **não** tem `-paths` — limitação conhecida).
   Exit ≠ 0 = slice ocupado → **aborte**, não insista.
3. **Stage por path explícito** (`git add <path> ...`); **nunca** `git add -A`/`-u` (árvore compartilhada).
4. **Commit assinado `(UC-XX.YY)` exige claim ativo** (hook `commit-msg`) e **branch `develop`** (D-04).
   Hook `pre-commit` valida encoding (UTF-8 estrito, U+FFFD, CJK, BOM-only).
5. **Push só com pedido explícito** do PO + 3 evidências (árvore limpa, sem concorrência, sem divergência).
6. Docs (`LEARNINGS.md`, `CHANGELOG.md`, plano) **no mesmo commit** da mudança.

## 3. Mapa de colisão — arquivos do slice em voo (evite)

`solution/**` · `docker/**` · `.github/workflows/**` · `.gitea/workflows/**` · `tools/build.ps1` ·
`.gitignore` · `pubspec.yaml` · `pubspec.lock` · `docs/plan/README.md` ·
`docs/plan/epics/epic-01-autenticacao.md` · `docs/plan/state/UC-CURRENT.md`

---

## 4. Trabalho 1 (recomendado) — validar o Docker de ponta a ponta

**Por quê**: é o **único** item do UC-01.00 sem prova local (Docker ausente no host do orquestrador);
o job `docker-build` do CI cobre, mas ninguém viu rodar. O Dockerfile mudou de stack (agora Serverpod).

**Como** (read-only sobre o repo — só roda e reporta):
```powershell
cd A:\Projetos\flutter\portfolio\devtasks
docker build -f docker/Dockerfile -t devtasks/server:local .          # deve sair 0
docker compose -f docker/docker-compose.yml up -d                      # sobe postgres + server
docker compose -f docker/docker-compose.yml ps                         # ambos "healthy"
curl.exe -s -o NUL -w "%{http_code}`n" http://localhost:8082/health    # esperado: 200
curl.exe -s http://localhost:8082/health                               # esperado: {"status":"healthy","service":"devtasks_server","version":"0.1.0"}
```
**Critérios de aceite**: build exit 0; containers `healthy`; `/health` → **200** com o payload acima.
**Fatos úteis**: o server expõe **8080** (API) e **8082** (web/`/health`); o `HEALTHCHECK` bate em
`http://localhost:8082/health`; o compose publica ambos em `0.0.0.0`; o banco é configurado por
**`SERVERPOD_DATABASE_*`** (sem o prefixo o Serverpod **ignora em silêncio** — verde falso de config).
**Se falhar**: reporte o erro literal + o passo; **não** edite o Dockerfile (é do meu slice) — devolva o
achado para eu corrigir na consolidação.

## 5. Trabalho 2 — fechar 2 achados do laudo (disjunto)

**NC-15 — gate de DIP** (domínio não pode importar infra): crie `tools/dip-gate.ps1` que falha
(exit ≠ 0) se `solution/app/lib/global/kernel/**` (e futuros módulos de domínio) importarem
`dart:io`, `dart:ui`, `package:flutter/`, `package:http`, `sqflite`, `serverpod*`. Prove com
**teste negativo versionado** (`tools/tests/test_dip_gate.ps1`: injeta um import proibido em fixture
temporária → exit 1) e **ligue ao runner** de governança.
⚠️ **Atenção**: `tools/test.ps1` (lista de suítes) **é do meu slice agora** — coordene comigo antes de
editá-lo, ou entregue o gate + teste e eu ligo na lista na consolidação.

**NC-24 — hook por `hooksPath`** (hoje `install-hooks.ps1` também **copia** para `.git/hooks`, o que
pode defasar do versionado): avalie remover a cópia ou documentar a salvaguarda; se mexer em
`tools/install-hooks.ps1`, **não** toque em `tools/build.ps1` (meu).

## 6. Trabalho 3 — plano de teste do `UC-01.01` a partir do Gate 2.5

O **Gate 2.5** já foi invocado para auth. Achados (resumo): **SEC-01** enumeração por timing/erro ·
**SEC-02** rate limit ausente no sign-up · **SEC-03** política de senha indefinida · **SEC-04** PII em
logs · **SEC-05** token em URL · **SEC-06** CSPRNG não verificado · **SEC-07** pin da dependência ·
**SEC-08** flag `emailVerified`. Invariantes propostas: `INV-SEC-01..12`.

**Entregue como rascunho** (arquivo de scratch fora do repo, ou texto): a matriz
`achado → teste automatizado → asserção exata` para o `UC-01.01`, priorizando
**INV-SEC-04** (mesmo `Result.Fail` e mesmo caminho de código para e-mail existente/inexistente),
**INV-SEC-08** (senha 12..128 + minúscula/maiúscula/dígito → `ERR_VALIDATION` 400) e
**INV-SEC-09** (DTO aceita **apenas** `name`/`email`/`password`; `role`/`workspaceId` no payload → 400).
Não edite o épico (é do meu slice); me entregue o rascunho e eu incorporo.

## 7. Trabalho 4 — vigiar o CI da consolidação

Depois do meu push, o run do GitHub Actions em `develop` valida: `Lint, Test & DAG Gate` e
**`Docker Build Validation`** (é o que prova o Dockerfile novo). Reporte o desfecho (run id + conclusão).

---

## 8. Não fazer agora

- **NC-17** (tema/WCAG) e **NC-22** (placeholder "Money-like NãoExiste aqui" em `epic-00:269`):
  dependem de edição de docs de plano que podem colidir com a consolidação.
- **NC-25** (`UC-CURRENT.md` cita 42 linhas; real 35–36): o arquivo **é** o hand-off do meu slice —
  só depois da consolidação.
- Qualquer edição em `solution/**`, `docker/**`, workflows, `pubspec*`, `tools/build.ps1`.

## 9. Anexo — achados do laudo ainda abertos

| ID | Resumo | Onde |
|---|---|---|
| NC-15 | sem gate de DIP versionado | `tools/` (ver Trabalho 2) |
| NC-17 | RNF-05/06/07 (tema base/WCAG) não entregues | `docs/architecture/DESIGN.md` §11, `docs/plan/README.md:111` |
| NC-22 | placeholder de template no épico | `docs/plan/epics/epic-00-fundacao.md:269` |
| NC-24 | cópia do hook vs `hooksPath` | `tools/install-hooks.ps1` |
| NC-25 | contagem de linhas desatualizada | `docs/plan/state/UC-CURRENT.md:46` |

**Formato de retorno**: cadeia `[EVIDÊNCIA]` (Leitura → Verificação → Confirmação) + o que ficou
verde/falhou + arquivos tocados. Sem silêncio: se travar, reporte o estado parcial.
