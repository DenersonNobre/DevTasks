# Brief paralelo — 2026-10-23 — 05

> **Para**: agente de apoio. **De**: orquestrador. O `UC-01.01` está em **Gate 4 (QA)**; a consolidação
> vem em seguida. Seu brief 04 foi concluído (claims `CLAIMS_DIR`/`reap`, pin gate, lcov do server,
> D-05/D-06, R-01 isolado) — obrigado.

---

## 1. Congelado até a minha consolidação
`solution/**` · `docs/plan/epics/epic-01-autenticacao.md` · `docs/plan/README.md` · `CHECKPOINT.md` ·
`docs/plan/state/UC-CURRENT.md`.

## 2. Item 1 (prioridade) — R-01: fechar o teto da governança
`[FATO]` `tools/test.ps1 -Coverage -Governance` = **712,91 s** × teto **600 s** (9/9 suítes funcionais
verdes). O isolamento do run aninhado já entrou; falta **reduzir tempo de verdade**: os probes do
`test_test_runner` reexecutam a suíte core ~5×, o `test_build_scripts` roda o build completo
(`generate` ≈38 s + `dart compile`) e há `pub get`/`generate` repetidos.
**Aceite**: ≤ 600 s (ideal ≤300) em **2 execuções consecutivas**, mantendo todas as provas negativas.

## 3. Item 2 (novo, achado de hoje) — **drift da CLI do Serverpod**
`[FATO]` o `Resolve-ServerpodCli` do `tools/build.ps1` **prefere a PATH**; ela estava em
**4.0.4** enquanto o projeto pina **3.4.13** → `serverpod generate` produziu `protocol.dart` para a API
4.x (`DatabaseSerializationManager`) e quebrou 23 erros de análise. Só foi detectado na mão
(`dart pub global activate serverpod_cli 3.4.13`).
**Entregue**: (a) `build.ps1`/CI comparam `serverpod --version` com o pin de
`solution/server/pubspec.yaml` e **falham alto** se divergirem; (b) teste negativo (CLI falsa no PATH →
exit ≠ 0); (c) registrar no `LEARNINGS.md` (gate que valida a declaração, não a capacidade).

## 4. Item 3 — não-bloqueantes do Gate 3 (depois do meu congelamento)
- **N12**: limite `name > 100` é regra não prevista em SPEC/PRD — leve ao `arch` (VO de nome) ou proponha remoção.
- **N15**: `SignUpDto.toString()` (gerado) serializa `password` em claro → teste de log capturado que
  assevere a ausência; considere wrapper de log no endpoint.
- **N18**: regex de e-mail duplicado (app × server) além da política de senha → pacote compartilhado
  (ex.: `solution/shared`) ou teste de paridade das regras.
- **N19**: colisão `auth` (endpoint × módulo) — no client, `client.auth` é o endpoint e o módulo só via
  `client.modules.auth`. Renomear o endpoint é barato **antes** do `UC-01.02`.

## 5. Item 4 — persistência do `UC-01.01` (seu design do brief 04 já existe)
Implementar `ServerpodUserRepository` (ORM) com **`UNIQUE(email)` normalizado** + tradução da violação
para `ERR_EMAIL_ALREADY_TAKEN` (**fecha o TOCTOU** apontado no Gate 3) + default `emailVerified=false`.
Hasher: apresente a decisão (src/ do framework × pointycastle × esperar IDP 3.5+) — **o PO decide**.

## 6. Fila
UI `/register` · slice de tema/WCAG (D-06, proposta já registrada) · estudo de migração para
`serverpod_auth_idp_server` (3.5+/4.x).

## Regras
Claim por slice · stage por path explícito · sem push sem pedido do PO + 3 evidências · docs no mesmo
commit · retorno com `[EVIDÊNCIA]`.
