# Brief de trabalho paralelo nº 2 — DevTasks (pós-NC-15/NC-24)

> **Para**: outro agente. **De**: orquestrador do ciclo EPIC-01. **Data**: 2026-10-22.
> **Contexto curto**: você entregou NC-15 (DIP gate) e NC-24 (hooks por `hooksPath`) — o orquestrador
> está **consolidando** isso agora. `UC-01.00` já foi commitado (`53ed8dd`) e o claim liberado.

---

## 1. Estado atual (fatos que você deve assumir como verdadeiros)

- Repo: `A:\Projetos\flutter\portfolio\devtasks` · branch **`develop`** · `UC-01.00` em `53ed8dd`.
- **Suíte local verde**: core **44,97 s** (teto 60 s) · governança **407,90 s** (teto 600 s) · total 452,88 s ·
  cobertura app/domínio **95,36%** (limites 70/90).
- **8 suítes de governança** agora (inclui `test_dip_gate.ps1`; o DIP gate está ligado ao runner).
- `serverpod` 3.4.13 pinado; `solution/client` versionado; `/health` em **8082** (API em 8080).
- Seu NC-15 foi **validado**: gate exit 0 na árvore canônica + 6 testes (3 provas negativas) verdes.
- Seu NC-24 **exigiu uma correção de integração** (feita pelo orquestrador): o teste de encoding
  passou a exigir `core.hooksPath` como fonte única e **ausência** de cópia em `.git/hooks`.

## 2. Regras de convivência (repetidas de propósito)

1. **OP-01**: um Coder ativo por vez. Pegue trabalho **disjunto** (lista abaixo).
2. **Claim** antes de mutar: `tools\bin\claims.cmd claim -Slice <UC-XX.YY> -Owner <papel>`
   (o shim **não** tem `-paths` — ver item D).
3. **Stage por path explícito**; nunca `git add -A`/`-u`.
4. Commit assinado `(UC-XX.YY)` exige claim ativo e branch `develop` (hooks ativos: `commit-msg` +
   `pre-commit` de encoding).
5. **Push só com pedido explícito** do PO + 3 evidências.
6. Docs (`LEARNINGS.md`, `CHANGELOG.md`, plano) no **mesmo commit**.

## 3. NÃO TOCAR agora (consolidação em voo do orquestrador)

`tools/test.ps1` · `tools/tests/test_test_runner.ps1` · `tools/tests/test_precommit_encoding.ps1` ·
`tools/install-hooks.ps1` · `tools/dip-gate.ps1` · `tools/tests/test_dip_gate.ps1` ·
`docs/plan/reviews/qa-review-v0.1.0.md` · `CHANGELOG.md` · `CHECKPOINT.md` ·
`docs/plan/epics/epic-00-fundacao.md` (F0.7)

> `docs/plan/state/UC-CURRENT.md` também: o orquestrador vai reescrevê-lo ao abrir o `UC-01.01`.

---

## 4. A — Docker E2E do novo stack Serverpod (prioridade máxima, read-only)

**Por quê**: é o **único** item do `UC-01.00` sem prova local (Docker ausente no host do orquestrador).
O CI cobre, mas ninguém viu rodar.

```powershell
cd A:\Projetos\flutter\portfolio\devtasks
docker build -f docker/Dockerfile -t devtasks/server:local .        # esperado: exit 0
docker compose -f docker/docker-compose.yml up -d                   # esperado: postgres + server
docker compose -f docker/docker-compose.yml ps                      # esperado: ambos "healthy"
curl.exe -s -o NUL -w "%{http_code}`n" http://localhost:8082/health # esperado: 200
curl.exe -s http://localhost:8082/health                            # esperado: {"status":"healthy","service":"devtasks_server","version":"0.1.0"}
docker compose -f docker/docker-compose.yml down                    # limpeza
```

**Fatos úteis**: API 8080 · web/`/health` 8082 · `HEALTHCHECK` bate em `localhost:8082/health` ·
compose publica ambos em `0.0.0.0` · banco por **`SERVERPOD_DATABASE_*`** (sem o prefixo o Serverpod
ignora em silêncio).
**Se falhar**: reporte o erro literal + o passo; **não edite** `docker/**` (é do slice do orquestrador).

## 5. B — Matriz de teste do `UC-01.01` (rascunho, sem escrever no épico)

O **Gate 2.5** de auth já foi invocado. Converta os achados em casos de teste:

| Achado | Invariante | Caso de teste exigido |
|---|---|---|
| SEC-01 | INV-SEC-04 | e-mail existente e inexistente → **mesmo** `Result.Fail(ERR_EMAIL_ALREADY_TAKEN)` e mesmo caminho (hash sempre computado); login → `ERR_INVALID_CREDENTIALS` único |
| SEC-03 | INV-SEC-08 | senha 12–128 + minúscula/maiúscula/dígito; fora disso → `ERR_VALIDATION` 400 |
| SEC-04 | INV-SEC-05 | log estruturado **não** contém e-mail/nome/senha em claro |
| SEC-06 | INV-SEC-10 | geração de salt/pepper usa `Random.secure` |
| SEC-08 | INV-SEC-12 | cadastro → `emailVerified == false` |
| SEC-09 | INV-SEC-09 | DTO aceita **apenas** `name`/`email`/`password`; `role`/`workspaceId` → 400 |

Entregue como **rascunho** (arquivo fora do repo, ou texto): `achado → teste → asserção exata`.

## 6. C — NC-22 (limpeza documental, 1 linha)

Remover o placeholder vazado em `docs/plan/epics/epic-00-fundacao.md:269`:
`"Money-like NãoExiste aqui"` → apenas remover o termo (o resto da frase fica). Commit `docs(plan): …`.

## 7. D — `claims.ps1` ganhar `-paths` (alinhar o shim ao tool canônico)

Hoje `tools/bin/claims.ps1` aceita só `-Action/-Slice/-Owner/-Ttl`; o tool canônico Go do oráculo tem
`-paths` (arquivos-alvo do slice) — é o que permite detectar sobreposição de **arquivos**, não só de UC.
Adicione `-Paths` (gravar no JSON do claim) + teste em `tools/tests/test_git_governance.ps1`
(⚠️ esse arquivo não está na minha lista de congelados — pode editar).

## 8. E — Só DEPOIS do commit do orquestrador: performance/cobertura da governança

- **R-01 (duração)**: a governança está em **407,9 s** contra teto de **600 s** — porque
  `test_test_runner.ps1` re-executa a suíte core ~5× e `test_build_scripts.ps1` roda o build completo
  (`serverpod generate` ≈38 s + `dart compile`). Reduza sem perder prova (ex.: alvo `-Target app` nos
  probes, fixtures menores, cache do build) **mantendo as provas negativas reais**.
- **R-03 (cobertura do server)**: `dart test --coverage` emite JSON, não `lcov` → o gate NFR-04 avisa e
  não mede o server. Converta (`dart run coverage:format_coverage --lcov`) e inclua no gate.

## 9. Formato de retorno

`[EVIDÊNCIA]` (Leitura → Verificação → Confirmação) + arquivos tocados + o que ficou verde/falhou.
Sem silêncio: se travar, reporte o estado parcial. Se pegar um slice, **abra claim** antes.

---

## 10. Retorno — Item B: Matriz de Testes de Segurança — UC-01.01 (Gate 2.5)

### 1. Mapeamento Direto: Achados do Gate 2.5 ➔ Invariantes ➔ Testes & Asserções

A tabela abaixo atende estritamente à conversão dos achados do Gate 2.5 em casos de teste unitários/integração com asserções exatas:

| Achado (Gate 2.5) | Invariante | Camada / Alvo | Caso de Teste Exigido | Asserção Exata (Código Dart / Domínio) |
|---|---|---|---|---|
| **SEC-01** (Anti-Enumeração & Timing) | **INV-SEC-04** | Serverpod Endpoint (`SignUpEndpoint`) | `test_register_uniform_error_and_timing_defense` | E-mail existente e inexistente retornam o **mesmo** `Result.Fail(ERR_EMAIL_ALREADY_TAKEN)` no cadastro com caminho de computação de hash idêntico (evita side-channel timing attack). No login, erro opaco único `ERR_INVALID_CREDENTIALS`.<br>```dart<br>expect(res.isFailure, isTrue);<br>expect(res.failure.code, equals('ERR_EMAIL_ALREADY_TAKEN'));<br>expect(dummyHashExecuted, isTrue);<br>``` |
| **SEC-03** (Política de Senha Fraca) | **INV-SEC-08** | App & Server (`Password` VO) | `test_password_policy_validation_boundaries` | Senha de 12 a 128 caracteres exigindo minúscula, maiúscula e dígito; fora dessa especificação: `ERR_VALIDATION` (400) imediato sem chamada de banco ou rede.<br>```dart<br>expect(Password.create('curta1!').failure.code, equals('ERR_VALIDATION'));<br>expect(Password.create('A' * 129 + '1a!').failure.code, equals('ERR_VALIDATION'));<br>expect(Password.create('semminuscula123!').failure.code, equals('ERR_VALIDATION'));<br>expect(Password.create('Valida@2026!Pass').isSuccess, isTrue);<br>``` |
| **SEC-04** (Vazamento de PII em Logs) | **INV-SEC-05** | Server Logging Middleware / Interceptor | `test_structured_log_redaction_pii_and_secrets` | O log estruturado **nunca** contém senha, token ou e-mail cru em texto claro.<br>```dart<br>expect(capturedLogs, isNot(contains(rawPassword)));<br>expect(capturedLogs, isNot(contains(rawEmail)));<br>expect(capturedLogMap['password'], equals('[REDACTED]'));<br>``` |
| **SEC-06** (Entropia Criptográfica) | **INV-SEC-10** | Server Cryptography Adapter | `test_salt_generation_uses_secure_random` | Geração de salt/pepper utiliza obrigatoriamente `Random.secure()` nativo do Dart.<br>```dart<br>expect(saltGenerator.isSecure, isTrue);<br>expect(saltBytes.length, greaterThanOrEqualTo(16));<br>expect(saltBytes1, isNot(equals(saltBytes2)));<br>``` |
| **SEC-08** (Confirmação Pendente) | **INV-SEC-12** | Postgres Entity (`devtasks_user`) | `test_user_registration_sets_unverified_status` | Ao persistir o usuário no banco, `emailVerified == false` e o status nasce pendente de confirmação.<br>```dart<br>expect(persistedUser.emailVerified, isFalse);<br>expect(persistedUser.status, equals(UserStatus.pendingVerification));<br>``` |
| **SEC-09** (Mass Assignment) | **INV-SEC-09** | Server DTO (`SignUpRequestDto`) | `test_signup_dto_mass_assignment_protection` | DTO aceita **apenas** `name`, `email` e `password`; injeção de `role`, `workspaceId` ou `isVerified` é bloqueada na desserialização com HTTP 400.<br>```dart<br>expect(response.statusCode, equals(400));<br>expect(persistedUser.role, isNull);<br>expect(persistedUser.workspaceId, isNull);<br>``` |

---

### 2. Coberturas Adicionais Identificadas no Gate 2.5

| Achado | Invariante | Camada | Caso de Teste | Asserção |
|---|---|---|---|---|
| **SEC-02** (Rate Limiting) | **INV-SEC-02** | Server Middleware | `test_register_rate_limit_exceeded` | Mais de 10 requisições/minuto do mesmo IP disparam HTTP 429.<br>```expect(res11.statusCode, equals(429)); expect(res11.failure.code, equals('ERR_RATE_LIMIT_EXCEEDED'));``` |
| **SEC-07** (Pinning Cripto) | **INV-SEC-07** | Server `pubspec.yaml` | `test_crypto_dependency_pinned` | Pacote criptográfico pinado sem versão aberta em aberto.<br>```expect(serverPubspec['dependencies']['cryptography'], matches(r'^\^?[0-9]+\.[0-9]+\.[0-9]+$'));``` |

---

### 3. Especificação BDD / Gherkin Pronta para Red-Before-Green

#### Cenário 1: Cadastro com Sucesso e Hash Seguro (Happy Path)
```gherkin
Dado que o visitante envia nome "Alice Dev", e-mail "alice@devtasks.io" e senha "F0rtress!Pass2026"
Quando a requisição de cadastro é processada
Então o usuário é persistido no banco com e-mail "alice@devtasks.io"
E a senha persistida no banco é um hash com salt (nunca texto plano)
E o campo emailVerified é gravado como false
E a resposta retorna status 201 com o UserId gerado
E nenhuma senha ou dado sensível vaza nos logs
```

#### Cenário 2: Rejeição Estrita de Senha Fraca (INV-SEC-08)
```gherkin
Dado que o visitante tenta cadastrar com a senha "curta1!" (menor que 12 caracteres)
Quando a validação de domínio do Value Object Password executa
Então o resultado é Failure(ValidationFailure)
E o código do erro é "ERR_VALIDATION" e o campo é "password"
E nenhuma chamada ao banco de dados ou computação de hash é executada
```

#### Cenário 3: Proteção contra E-mail Duplicado sem Enumeração (INV-SEC-04)
```gherkin
Dado que o e-mail "bob@devtasks.io" já está cadastrado no sistema
Quando outro visitante tenta se cadastrar com o mesmo e-mail "bob@devtasks.io"
Então o endpoint executa a rotina de hash para manter timing equivalente
E a requisição retorna Failure com "ERR_EMAIL_ALREADY_TAKEN"
E a resposta não vaza dados cadastrais nem detalhes internos do usuário pré-existente
```

#### Cenário 4: Imunidade a Mass Assignment (INV-SEC-09)
```gherkin
Dado que um atacante envia payload com {"name": "Hacker", "email": "h@test.io", "password": "StrongPassword123!", "role": "owner", "workspaceId": "ws-root"}
Quando o endpoint processa a requisição
Então o payload é rejeitado com status 400 por campos desconhecidos
E nenhum usuário é persistido com permissões administrativas
```
