# Matriz de Testes de Segurança — UC-01.01 (Gate 2.5)

> **De**: Agente de Apoio Paralelo  
> **Para**: Orquestrador do Ciclo DevTasks  
> **Data**: 2026-10-22  
> **Origem**: Seção 5 (Item B) de `brief-paralelo-2026-10-22-02.md`  
> **Destino sugerido no repo**: `docs/plan/epics/epic-01-autenticacao.md` (sob `UC-01.01`)

---

## 1. Mapeamento Direto: Achados do Gate 2.5 ➔ Invariantes ➔ Testes & Asserções

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

## 2. Coberturas Adicionais Identificadas no Gate 2.5

| Achado | Invariante | Camada | Caso de Teste | Asserção |
|---|---|---|---|---|
| **SEC-02** (Rate Limiting) | **INV-SEC-02** | Server Middleware | `test_register_rate_limit_exceeded` | Mais de 10 requisições/minuto do mesmo IP disparam HTTP 429.<br>```expect(res11.statusCode, equals(429)); expect(res11.failure.code, equals('ERR_RATE_LIMIT_EXCEEDED'));``` |
| **SEC-07** (Pinning Cripto) | **INV-SEC-07** | Server `pubspec.yaml` | `test_crypto_dependency_pinned` | Pacote criptográfico pinado sem versão aberta em aberto.<br>```expect(serverPubspec['dependencies']['cryptography'], matches(r'^\^?[0-9]+\.[0-9]+\.[0-9]+$'));``` |

---

## 3. Especificação BDD / Gherkin Pronta para Red-Before-Green

### Cenário 1: Cadastro com Sucesso e Hash Seguro (Happy Path)
```gherkin
Dado que o visitante envia nome "Alice Dev", e-mail "alice@devtasks.io" e senha "F0rtress!Pass2026"
Quando a requisição de cadastro é processada
Então o usuário é persistido no banco com e-mail "alice@devtasks.io"
E a senha persistida no banco é um hash com salt (nunca texto plano)
E o campo emailVerified é gravado como false
E a resposta retorna status 201 com o UserId gerado
E nenhuma senha ou dado sensível vaza nos logs
```

### Cenário 2: Rejeição Estrita de Senha Fraca (INV-SEC-08)
```gherkin
Dado que o visitante tenta cadastrar com a senha "curta1!" (menor que 12 caracteres)
Quando a validação de domínio do Value Object Password executa
Então o resultado é Failure(ValidationFailure)
E o código do erro é "ERR_VALIDATION" e o campo é "password"
E nenhuma chamada ao banco de dados ou computação de hash é executada
```

### Cenário 3: Proteção contra E-mail Duplicado sem Enumeração (INV-SEC-04)
```gherkin
Dado que o e-mail "bob@devtasks.io" já está cadastrado no sistema
Quando outro visitante tenta se cadastrar com o mesmo e-mail "bob@devtasks.io"
Então o endpoint executa a rotina de hash para manter timing equivalente
E a requisição retorna Failure com "ERR_EMAIL_ALREADY_TAKEN"
E a resposta não vaza dados cadastrais nem detalhes internos do usuário pré-existente
```

### Cenário 4: Imunidade a Mass Assignment (INV-SEC-09)
```gherkin
Dado que um atacante envia payload com {"name": "Hacker", "email": "h@test.io", "password": "StrongPassword123!", "role": "owner", "workspaceId": "ws-root"}
Quando o endpoint processa a requisição
Então o payload é rejeitado com status 400 por campos desconhecidos
E nenhum usuário é persistido com permissões administrativas
```
