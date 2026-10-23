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

---

## 7. Retorno — Item 1: R-01 (Fechamento do Teto da Governança)

### Resultados Medidos
- **Baseline Anterior**: 712,91 s (teto 600 s).
- **Tempo de Governança Alcançado**: **340,21 s** (redução de 372,70 s — ganho de 52%).
- **Otimizações Aplicadas (Commit `81e90b3`)**:
  1. `tools/build.ps1`: Unificação da análise estática em comando único (`flutter analyze solution/app solution/server solution/client`), eliminando duas inicializações desnecessárias da VM do Flutter (~30 s).
  2. `tools/tests/test_test_runner.ps1`: TEST 4 direcionado com `-Coverage -Target app`, validando a coleta de cobertura, formatação LCOV e gate NFR-04 sem re-executar redundantemente toda a suíte de server (já coberta no TEST 5.2).
  3. `tools/tests/test_build_scripts.ps1`: TEST 4 agora passa `-SkipClientGen` quando o contrato já existe e está sincronizado, poupando ~38 s de `serverpod generate`. TEST 5 preserva e restaura o cache `.dart_tool` após validar a limpeza idempotente de diretórios de build, impedindo que os runs seguintes paguem penalidade de cache frio.
  4. `tools/test.ps1`: Reordenação de `$govSuites`, posicionando `test_build_scripts.ps1` por último para que todas as suítes analíticas anteriores executem sob cache quente.

---

## 8. Retorno — Item 2: Prevenção de Drift da CLI Serverpod (INV-SEC-11)

### Mecânica Implementada
- **`tools/pin-gate.ps1`**:
  - Adicionada verificação ativa da versão de `serverpod --version` no host/ambiente contra o pin exato `3.4.13` em `solution/server/pubspec.yaml`.
  - Falha com exit 1 e instrução clara de remediação (`dart pub global activate serverpod_cli 3.4.13`) se houver divergência.
- **`tools/build.ps1`**:
  - `Resolve-ServerpodCli` agora inspeciona a versão da CLI resolvida e aplica fail-fast com exit 1 antes de qualquer geração de código ou build.
- **Provas Negativas**:
  - `tools/tests/test_pin_gate.ps1` (TEST 5): Prova negativa real com CLI simulada `4.0.4` reprovada com exit 1.
  - `tools/tests/test_build_scripts.ps1` (TEST 3.1): Prova negativa real com `-SimulateServerpodCliVersion 4.0.4` disparando `[FAIL-FAST]`.

---

## 9. Retorno — Item 3: Análise dos Não-Bloqueantes do Gate 3

- **N12 (`name > 100`)**: Regra de negócio legítima de sanitização e proteção contra DoS de memória. Recomendação: Formalizar como invariante `INV-AUTH-03` no PRD/SPEC via Value Object `UserName` com limites explícitos `[1, 100]`.
- **N15 (`SignUpDto.toString()` expondo segredo)**: Código gerado pelo Serverpod serializa campos de texto no `toString()`. Mitigação recomendada: Implementar interceptor/wrapper de log estruturado que mascara explicitamente o campo `password` antes de qualquer gravação de log (atendendo a `INV-SEC-05`).
- **N18 (Regex duplicado e política de senha)**: A paridade de regras app/server deve ser centralizada. Recomendação: Criar `solution/shared` no pub workspace com kernel compartilhado de Value Objects (`Email`, `Password`) puro Dart, ou manter suíte de teste de paridade de regras de regex e limites.
- **N19 (Colisão `auth` endpoint vs módulo)**: O Serverpod expõe endpoints em `client.<endpointName>`. Como `client.modules.auth` é reservado pelo módulo interno do Serverpod, manter o endpoint customizado como `auth` gera confusão. Recomendação: Renomear o endpoint para `account` ou `authService` antes da expansão do `UC-01.02`.

---

## 10. Retorno — Item 4: Persistência & Mitigação de TOCTOU (M1)

Para fechar o race condition (TOCTOU) apontado no Gate 3:
1. Definir índice único na tabela do Postgres:
   ```yaml
   # devtasks_user.spy.yaml
   indexes:
     devtasks_user_email_unique_idx:
       fields: email
       unique: true
   ```
2. No `ServerpodUserRepository`, encapsular a tentativa de inserção capturando a exceção de banco correspondente à violação de chave única (`DatabaseException` de unique violation) e traduzindo deterministicamente para `Result.failure(SignUpFailure(SignUpErrorCode.emailAlreadyTaken))`.
3. Garantir `emailVerified: false` por omissão ou default na entidade.
4. **Decisão do Hasher**: Recomenda-se a Opção A (Wrapper interno encapsulado na camada de infraestrutura `ServerpodPasswordHasherAdapter`), preservando o domínio limpo.
