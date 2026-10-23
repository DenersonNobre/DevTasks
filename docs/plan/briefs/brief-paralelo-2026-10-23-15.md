# Brief paralelo — 2026-10-23 — 15

> **Para**: agente paralelo (`parallel-agent`) · **De**: orquestrador (`coder`).
> **Fatia**: **corrigir a medição do `NFR-03`** no harness (não é UC de produto; é governança).
> **Escopo**: `tools/test.ps1` · `.github/workflows/ci.yml` · `.gitea/workflows/ci.yml` · `LEARNINGS.md`.
> **Fence**: `solution/**` (nenhum código de produto), `docs/architecture/**`, `docs/plan/state/**`, `CHECKPOINT.md`.

## 1. Por que (evidência medida, máquina ociosa, 2026-10-23)

`tools/test.ps1` reprova `[NFR-03]` — core **71,81 s** × teto **60 s** — com **todos os testes verdes**
(server 79, app 66). A decomposição mostra que **o gate não mede o que o requisito define**:

| Medição | Tempo |
|---|---|
| app `flutter test` **com pub** | **110,0 s** |
| app `flutter test --no-pub` | 27,9 s (2ª: 23,5 s) |
| app `flutter test test/unit --no-pub` | 18,1 s |
| app `flutter test test/widget --no-pub` | 14,6 s |
| server `dart test` completo | 44,2 s |
| server `dart test test/unit` | **8,8 s** |
| server `dart test` (3 testes da raiz) | 6,4 s |

**Duas causas independentes**:

1. **`pub get` dentro da janela.** O `$stopwatch` começa em `tools/test.ps1:24` e `$coreElapsed` fecha em `:90`;
   `--no-pub` só entra se `-NoPub` for passado (ninguém passa). O CI **já** resolve dependências antes
   (`ci.yml:33-34` → `flutter pub get`) e chama o harness sem `-NoPub` (`:43`) — resolve tudo de novo dentro
   da medição. `pub` sozinho custa **~82 s** (110 − 27,9) no app.
2. **O gate mede mais que o requisito.** `SPEC.md:218` (NFR-03): *"domínio 100% sem I/O — **suíte unitária**
   roda com fakes … em **≤ 60 s** … **sem banco nem rede**"*. O harness roda `flutter test` **completo**
   (inclui `test/widget`) e `dart test` **completo**. Widget/integração não fazem parte da definição do NFR-03.

**Consequência**: o teto efetivo muda por ambiente (local 60 s sem coverage; CI 120 s com `-Coverage`) e o
número não é comparável entre execuções — gate não confiável, que é o pior tipo de gate.

## 2. Correção exigida

1. **Fora da janela**: no CI, manter `flutter pub get` no passo anterior **e** passar `-NoPub` ao harness; no
   script, para o server, aquecer o package config antes de iniciar o cronômetro (`dart pub get` fora da
   medição) e então rodar os testes.
2. **Separar por requisito** (o ponto principal):
   - **`-Unit` (gate NFR-03, ≤ 60 s)**: `flutter test test/unit --no-pub` (app) + `dart test test/unit` (server),
     **sem** banco/rede;
   - **`-Integration`/`all`**: `flutter test test/widget` + testes da raiz do server (`health_endpoint_test`,
     `client_contract_test`, `smoke_test`) com **teto próprio** (proposta: 120 s) — não é NFR-03.
3. **Tempo por membro**: imprimir `app=…s server=…s` (hoje só existe o total aninhado; um número agregado
   esconde a regressão e não diz de quem é a culpa).
4. **Calibração**: registrar no próprio script qual orçamento vale para quê, para não voltar a comparar
   números medidos de formas diferentes.
5. **Prova negativa**: um teste do harness (ou `-SimulateFailure` estendido) que **falhe** quando o tempo do
   membro excede o orçamento e **passe** quando dentro — gate que não pode falhar não é gate.

## 3. Restrições

- **Não aumentar teto para "passar"**: a correção é medir o que o requisito pede. Se, depois da separação,
  o `-Unit` ainda exceder 60 s, **pare e reporte** com a decomposição (aí a conversa é otimizar ou revisar o
  requisito com o PO — decisão dele, não do harness).
- Não tocar em código de produto; sem push; stage por path explícito.
- Atualizar `LEARNINGS.md` com o achado (janela incluía `pub`; gate media mais que o requisito).

## 4. Retorno esperado

```text
## Retorno — harness NFR-03
### Antes/depois (medido)
- `tools/test.ps1` (local, ocioso): antes <71,81 s / REPROVADO> → depois <…>
- `-Unit` (app+server, sem pub): <…> s   (teto 60 s)
- `-Integration`: <…> s                   (teto 120 s)
### Prova negativa
- <comando> → exit != 0 quando o orçamento é estourado (e exit 0 quando dentro)
### CI
- `ci.yml` (github + gitea): `-NoPub` e `pub get` fora da janela; budgets explícitos
### Desvios declarados
- <itens>
```
