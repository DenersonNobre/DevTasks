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
