# DevTasks

SaaS de gestão de tarefas para equipes de desenvolvimento — projeto de portfólio full-stack em Dart:
quadro Kanban, prazos/prioridades, colaboração assíncrona (comentários/atribuição) e dashboard de indicadores.

> **Status**: quarteto em elaboração (`PRD` ✅ · `DESIGN` ✅ · `SPEC` ⏳ · `docs/plan/` ⏳) — **EPIC-00-FUNDACAO pendente**.
> Nenhum código de negócio pode iniciar antes do DoD da EPIC-00 (Gate Zero).

## Estrutura

```text
docs/product/          PRD.md + wireframe (Designer.png)
docs/architecture/     DESIGN.md (engenharia + UI) · SPEC.md (domínio — pendente)
docs/plan/             índice mestre de épicos (pendente)
solution/app/          Flutter (VSA: lib/modules/* + global/)
solution/server/       Serverpod (scaffold atual a substituir na EPIC-00)
solution/client/       gerado por `serverpod generate` (criado na EPIC-00)
```

## Pré-requisitos

- Flutter/Dart SDK `^3.13.5`
- Docker (paridade de ambiente — EPIC-00)

## Build e Testes

⏳ Definidos na `EPIC-00-FUNDACAO` (F0.2 build em 1 comando, F0.3 runner de testes em 1 comando).
Comandos serão gravados aqui no commit que implementar esses pilares.

## Documentação

- **Escopo/produto**: `docs/product/PRD.md`
- **Decisões de engenharia e design**: `docs/architecture/DESIGN.md`
- **Domínio/invariantes**: `docs/architecture/SPEC.md` (pendente)
