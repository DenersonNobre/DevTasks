# Epic 07 — Deploy & Medição (deploy)

> Status: ⏳ Pendente | Prioridade: Alta | Dependências: EPIC-00, EPIC-05, EPIC-06

## 1. Objetivo e Valor de Negócio

Publicar a demo viva e **medir** o que ela promete: deploy da stack (API + Postgres + Flutter Web
estático) e evidência numérica dos metas do PRD §6.1 — P95 < 500 ms e Lighthouse ≥ 90. Fecha o
produto como peça de portfólio (repo, CI e demo pública). Nota: o compose **local** de paridade é
EPIC-00 F0.5; aqui vive o ambiente de produção e sua publicação.

- **Stack**: D-ENG-08 — alvo Railway/Render + Flutter Web estático; Docker (reutiliza imagem da
  EPIC-00 F0.5) + Postgres gerenciado.
- **Invariantes/NFRs**: NFR-01 (P95 < 500 ms pós-deploy), PRD §6.1 (Lighthouse ≥ 90 em Performance,
  A11y, Best Practices, SEO), RNF-08 (HTTPS em produção).

## 2. Matriz de Features

| # | Feature | UCs/Histórias | Independência / Risco | Status |
|:---|:---|:---:|:---|:---:|
| F7.1 | Ambiente de produção (stack publicada) | 1 | Alto: custo/segredos de provedor | ⏳ |
| F7.2 | Pipeline de deploy contínuo (2 remotes em paridade) | 1 | Depende de F7.1; CI da EPIC-00 F0.6 | ⏳ |
| F7.3 | Medição de RNF-01 & Lighthouse (evidência do portfólio) | 1 | Meta quantitativa bloqueante | ⏳ |

---

## 3. Detalhamento das Features

### Feature 7.1 — Ambiente de Produção (D-ENG-08 / RNF-08)

**Descrição**: provisionar o alvo Railway/Render com Postgres gerenciado + imagem do Serverpod
(da EPIC-00 F0.5) e servir o Flutter Web estático buildado; HTTPS terminado pelo provedor
(RNF-08). Segredos (DB URL, auth key) só via variáveis de ambiente do provedor — nunca no repo.

**DoR**: EPIC-00 F0.5 ✅ (imagem Docker) · EPIC-01..06 ✅ (produto completo).
**DoD**: app acessível por URL pública com login funcionando; `docker compose -f docker-compose.prod.yml`
equivalente documentado para qualquer provedor.

#### User Story 7.1.1 — Demo pública viva

* **Identificador**: `UC-07.01`
* **Narrativa**:
  - **Como** visitante do portfólio (persona Bia avaliando o produto)
  - **Eu quero** acessar o DevTasks por uma URL pública e usá-lo
  - **Para que** eu avalie o produto sem instalar nada
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: stack publicada responde
    Dado o deploy em produção com Postgres
    Quando abro a URL pública
    Então sirvo o Flutter Web com API saudável e HTTPS ativo

  Cenário: segredos fora do repositório
    Dado o deploy configurado
    Quando inspeciono o repo
    Então nenhuma credencial ou URL de banco está commitada
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: compose de produção + variáveis obrigatórias validadas na subida ➔ Commit: `chore(deploy): add production compose`
  2. `TASK-02`: provisionamento do alvo + build do Flutter Web publicado ➔ Commit: `chore(deploy): publish web build and provision backend`
  3. `TASK-03`: smoke check de subida (login + CRUD de ponta a ponta) ➔ Commit: `test(deploy): add production smoke check`
* **Impacto & Arquivos Alvo**:
  - `docker/docker-compose.prod.yml` [NEW]
  - `scripts/deploy/**` [NEW]
  - `docs/api/deploy-runbook.md` [NEW]

---

### Feature 7.2 — Pipeline de Deploy Contínuo (F0.6 extensão / paridade de remotes)

**Descrição**: extensão dos workflows da EPIC-00 F0.6 (Gitea Actions primário + GitHub Actions em
paridade — decisão do PO 2026-10-21): deploy automático em push de `main` para o alvo de produção,
com o mesmo build/teste verde como pré-condição e health check pós-deploy.

**DoR**: F7.1 ✅ · EPIC-00 F0.6 ✅ (CI verde nos dois remotes).
**DoD**: push em `main` publica nos dois pipelines sem intervenção manual; falha de health check
derruba o pipeline (sem deploy quebrado silencioso).

#### User Story 7.2.1 — Deploy automático e auditável

* **Identificador**: `UC-07.02`
* **Narrativa**:
  - **Como** mantenedor do projeto
  - **Eu quero** que um push em `main` publique a demo automaticamente
  - **Para que** a demo nunca fique para trás do código versionado
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: merge em main publica
    Dado um push em main com suíte verde
    Quando o pipeline roda
    Então o deploy é publicado e o health check responde 200

  Cenário: pipeline quebrado não publica
    Dado um push em main com teste vermelho
    Quando o pipeline roda
    Então a etapa de deploy não roda e o status do remote fica vermelho
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: job de deploy nos dois workflows com guard de suíte verde ➔ Commit: `ci: add deploy jobs on main`
  2. `TASK-02`: health check pós-deploy (bloqueia publicação quebrada) ➔ Commit: `ci: gate deploy on health check`
* **Impacto & Arquivos Alvo**:
  - `.gitea/workflows/ci.yml` [MODIFY]
  - `.github/workflows/ci.yml` [MODIFY]

---

### Feature 7.3 — Medição de RNF-01 & Lighthouse (NFR-01 / PRD §6.1)

**Descrição**: evidência numérica dos metas do portfólio. **Decisão pendente do DESIGN** registrada
nesta feature: ferramenta de carga para P95 — candidatas `k6` (container, único comando) ou script
Dart `package:http` com percentis; e auditor Lighthouse CI (≥ 90 nas 4 categorias). O valor medido
entra no README/CHANGELOG como linha de base real.

**DoR**: F7.1 ✅ (ambiente público) · F7.2 ✅ (pipeline com artefato de resultado).
**DoD**: relatório de P95 por endpoint e nota Lighthouse versionados; falha do gate (P95 ≥ 500 ms
ou Lighthouse < 90) é sinal vermelho — meta bloqueante, não warning.

#### User Story 7.3.1 — Provar a meta em vez de prometer

* **Identificador**: `UC-07.03`
* **Narrativa**:
  - **Como** mantenedor / avaliador do portfólio
  - **Eu quero** relatório de latência P95 e nota Lighthouse versionados
  - **Para que** a meta de performance seja evidência, não slogan
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: medição de P95 nos endpoints CRUD
    Dado o ambiente público sob carga controlada
    Quando medo os endpoints CRUD
    Então o relatório registra P95 < 500 ms por endpoint

  Cenário: Lighthouse no app web
    Dado o Flutter Web publicado
    Quando rodo o Lighthouse
    Então as 4 categorias (Performance, A11y, Best Practices, SEO) marcam ≥ 90

  Cenário: meta estourada é sinal vermelho
    Dado um pipeline com P95 ≥ 500 ms ou nota < 90
    Quando o gate de medição roda
    Então o job falha (não é warning aceito)
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: decisão da ferramenta de carga + roda de medição reproduzível ➔ Commit: `chore(measure): add p95 load harness`
  2. `TASK-02`: Lighthouse CI no pipeline com limiar ≥ 90 ➔ Commit: `ci: add lighthouse budget gate`
  3. `TASK-03`: relatório versionado + linha de base no README/CHANGELOG ➔ Commit: `docs(measure): record baseline p95 and lighthouse`
* **Impacto & Arquivos Alvo**:
  - `scripts/measure/**` [NEW]
  - `.gitea/workflows/ci.yml`, `.github/workflows/ci.yml` [MODIFY]
  - `README.md`, `CHANGELOG.md` [MODIFY]
