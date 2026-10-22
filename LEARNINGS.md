# LEARNINGS — DevTasks

Diário técnico do projeto (Regra de Ouro do oráculo: aprendizado registrado **no commit da mudança**, nunca "depois").
Aprendizado transversal a qualquer projeto **não** vai aqui — vive em `~/.agents/rules/global_learnings.md`.

## Formato da entrada

```text
## YYYY-MM-DD — [Título curto do sintoma]
- **Sintoma**: o que falhou, observado por comando/log.
- **Causa raiz**: por que falhou (evidência, não suposição).
- **Fix**: correção aplicada.
- **Prevenção**: gate/teste que impede repetição.
```

## Entradas

## 2026-10-21 — Ciclo de UC iniciado na branch errada (main em vez de develop)

- **Sintoma**: os dois primeiros commits do ciclo pós-Gate Zero (`d09aa9a`, `05bf4aa`) caíram
  direto na `main`; o usuário apontou a violação ("main→develop como default").
- **Causa raiz**: o agente orquestrador assumiu `main` como branch de trabalho sem verificar
  a política de branches do repo — que estava no próprio backlog: `epic-00-fundacao.md` F0.4
  define branches canônicas `main`/`develop` e F0.6 dispara CI em push de `develop`/`main`
  (merge à main = release). A F0.4 ainda não executada não anulava a convenção.
- **Fix**: `develop` criada em `05bf4aa` (leva o ciclo); `main` devolvida ao baseline estável
  `17b69f4` (histórico local reescrito sem perda — nada publicado; commits preservados em
  `develop`).
- **Prevenção**: antes do primeiro commit de qualquer ciclo, checar `git branch -a` + a
  política de branches (épico/guides/AGENTS.md) e iniciar em `develop`/`feat/*`; a F0.4
  vai adicionar o poka-yoke (hook/pre-flight que rejeita commit de UC fora de `develop`).

## 2026-10-21 — Migração para o protocolo CHECKPOINT (oráculo) no ciclo Gate Zero

- **Sintoma**: o projeto nascera com `checkpoint.md` minúsculo gitignored (`.gitignore` com
  regras `checkpoint.md`/`resume.md`) — continuidade efêmera, sem poka-yoke.
- **Causa raiz**: o oráculo aprovou o protocolo `CHECKPOINT.md` (caixa alta, ≤60 linhas,
  ponteiro único de continuidade; `HANDOFF.md`/`RESUME.md` aposentados — INV-STATE-02/03
  com enforcement no health §15 do oráculo).
- **Fix**: `checkpoint.md` → `CHECKPOINT.md` versionado, reescrito como ponteiro (budget
  37/60 linhas); regras `checkpoint.md`/`resume.md` removidas do `.gitignore` (o arquivo
  agora tem de ser versionado; o scratch minúsculo é que continua descartável).
- **Prevenção**: ao clonar/iniciar outro projeto, nascer direto no protocolo — não criar
  checkpoint efêmero gitignored e depois migrar.

## 2026-10-22 — Saneamento pós QA-Review v0.1.0: Docker build, claims atômicos e cobertura

- **Sintoma**: Auditoria de QA (Gate 4) reprovou release v0.1.0 identificando falha de Docker build no CI (NC-01/NC-06), `.dockerignore` inerte por estar em subpasta (NC-07), healthcheck insatisfazível contra stub (NC-04), claims sem atomicidade nem código 2 de colisão (NC-05), cobertura do kernel abaixo de 70% (NC-14) e suites de governança órfãs (NC-08).
- **Causa raiz**: O builder Docker em imagem Dart pura tentava resolver o app Flutter do workspace monorepo; o daemon Docker exige `.dockerignore` na raiz do contexto; `claims.ps1` usava `Set-Content -Force` sem lock `O_EXCL` e `$ErrorActionPreference='Stop'` convertia `exit 2` em 1 ao interceptar `Write-Error`; `DateOnly` aceitava datas inexistentes (`2026-02-31`); `result.dart` carecia de testes em `flatMap`/`mapFailure`.
- **Fix**:
  1. Criado `.dockerignore` na raiz do repositório e isolado o workspace do server no `docker/Dockerfile`.
  2. Implementado servidor HTTP nativo (`dart:io`) em `solution/server/lib/main.dart` escutando na porta 8080 nos paths `/` e `/health`.
  3. `claims.ps1` refatorado com `FileMode.CreateNew` (`O_EXCL`), suporte dual a `claims/v1`, detecção de posse, `heartbeat` e retorno explícito de `exit 2` em conflito.
  4. Suíte de governança integrada via `tools/test.ps1 -Governance` e acoplada aos workflows de CI (`.github` e `.gitea`).
  5. `DateOnly` corrigido com validação de calendário e cobertura do domínio puro elevada para 94,04%.
- **Prevenção**: Alinhar o contexto Docker com `.dockerignore` na raiz, executar `tools/test.ps1 -Governance` como pré-flight obrigatório e manter a matriz §7 sempre sincronizada.
