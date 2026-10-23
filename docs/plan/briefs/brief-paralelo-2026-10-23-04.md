# Brief paralelo — 2026-10-23 — 04

> **Para**: agente de apoio paralelo. **De**: orquestrador do ciclo EPIC-01.
> **Estado**: `develop` @ `dcc3e2a` publicado; o orquestrador tem o commit `9f3ffe0` (`UC-01.01`) **local**
> em consolidação (Gates 3/4). Seu relatório do brief 03 foi conferido e aceito.

---

## 1. NÃO TOCAR até o orquestrador consolidar

`docs/plan/epics/epic-01-autenticacao.md` · `docs/plan/README.md` · `CHECKPOINT.md` ·
`docs/plan/state/UC-CURRENT.md` · `solution/**` (o slice está commitado, mas a consolidação pode
tocar docs e regenerar contrato).

## 2. Item 1 (PRIORIDADE) — R-01: fechar a duração da governança

**Fato**: `pwsh tools/test.ps1 -Coverage -Governance` = **712,91 s** contra teto de **600 s** (todas as
9 suítes funcionais verdes). Causas medidas: `test_test_runner.ps1` re-executa a suíte core ~5×;
`test_build_scripts.ps1` roda o build completo (`serverpod generate` ≈38 s + `dart compile`); suíte nova
(`test_pin_gate`) somou tempo; e há carga concorrente quando os dois agentes rodam juntos.

**Sugestões** (escolha e meça):
- probes do `test_test_runner` usarem `-Target app` (ou `server`) em vez da suíte inteira;
- **uma** execução de `-Coverage` compartilhada pelos TEST 4 e 5 (hoje são duas);
- cachear o artefato do build no `test_build_scripts` (ou rodar `-SkipCompile` no teste, deixando a
  asserção do artefato no build real);
- evitar `pub get`/`generate` repetidos.

**Aceite**: `-Coverage -Governance` exit 0 com **≤ 600 s** (ideal ≤300) em **2 execuções consecutivas**,
mantendo **todas** as provas negativas (orçamento, cobertura, PIN gate, encoding, DIP, hooks).
Registre as medições antes/depois no retorno.

## 3. Item 2 — D-06: propor o slice de tema/WCAG na EPIC-01 (rascunho)

A decisão `D-06` reatribuiu `RNF-05/06/07` (tema base + WCAG) da EPIC-00 para a **EPIC-01**, mas **não há
UC** para isso. Entregue **rascunho** (sem editar o épico): `F1.5 — Tema Base & Acessibilidade` com
US (persona/valor), Gherkin (claro/escuro, contraste 4.5:1/3:1, estados de componente), TASKs e
arquivos-alvo (`solution/app/lib/global/theme/**`, `DESIGN.md` §2/§11 como contrato).
O orquestrador revisa e incorpora ao épico (é ele quem fatia).

## 4. Item 3 — Follow-up de persistência do `UC-01.01` (design + esqueleto)

Hoje `AuthEndpoint` responde `ERR_INFRA_FAILURE` sem adaptador (lacuna declarada). Desenhe:
- `ServerpodUserRepository` usando o ORM (modelo/migração já existem: `migrations/20261023024432194`);
- teste **unitário** com `Session`/banco falsos (sem Postgres no host);
- `PasswordHasher` adapter: a API pública do framework **não** expõe o hasher em `3.4.13` (só
  `src/business/password_hash.dart`); avalie (a) uso controlado via `src/` com justificativa,
  (b) `pointycastle` Argon2id, (c) esperar o IDP (3.5+). **Recomende** com prós/contras — a decisão é do PO.
- Não implemente ainda se a decisão (b/c) não estiver fechada; entregue o design + esqueleto testado.

## 5. Fila posterior
UI `/register` (novo slice, contrato gerado já disponível) · estudo de migração para
`serverpod_auth_idp_server` (3.5+/4.x) para o dia do bump.

## Regras
Claim próprio por slice · stage por **path explícito** · sem push sem pedido do PO + 3 evidências ·
docs no mesmo commit · retorno com `[EVIDÊNCIA]`.
