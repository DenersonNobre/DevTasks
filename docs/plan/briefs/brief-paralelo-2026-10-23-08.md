# Brief paralelo — 2026-10-23 — 08

> **Para**: agente de apoio. **De**: orquestrador.
> **Estado**: brief 07 aceito — **NFR-03 calibrado e verificado** (60 s sem `-Coverage`, 120 s com;
> prova negativa preservada). Designs de hash/UI/persistência recebidos. `UC-01.03` em consolidação
> (Gate 3 aprovado em 4 rodadas; Gate 4 rodando).

---

## 1. Congelado até a consolidação do `UC-01.03`
`solution/app/lib/global/router/**` · `solution/app/lib/modules/auth/**` ·
`solution/server/lib/src/endpoints/**` · `solution/server/lib/src/modules/auth/**` ·
`docs/plan/state/UC-CURRENT.md` · `docs/plan/epics/epic-01-autenticacao.md` ·
`docs/plan/README.md` · `CHECKPOINT.md`.

## 2. Item A (prioridade) — Persistência do cadastro: **implementar o design com 2 correções**

Seu design está certo na estratégia (usar as tabelas do módulo instalado + `UNIQUE` no banco para fechar
o TOCTOU). Duas correções obrigatórias antes de codar:

### 2.1 Tipos reais das portas (o design citava tipos inexistentes)
- `CredentialRepository.findByEmail(String normalizedEmail) → Future<CredentialRecord?>`
  (não `findCredentialByEmail`/`UserCredential`).
- `CredentialRecord` tem `id`, `email`, `passwordHash` (`ports.dart:65`).

### 2.2 Violação de unicidade é **falha esperada** → retorno tipado, **não exceção**
Hoje `UserRepository.create` devolve `RegisteredUser` e o design lança `EmailAlreadyTakenException`.
Isso viola a regra do projeto ("falha esperada ⇒ resultado tipado; exceção só para o imprevisível") e
obriga `try/catch` no domínio. Ajuste:

```dart
sealed class CreateUserOutcome {}
class UserCreated extends CreateUserOutcome { final RegisteredUser user; ... }
class EmailTaken extends CreateUserOutcome { ... }

abstract interface class UserRepository {
  Future<bool> existsByEmail(String email);
  Future<CreateUserOutcome> create({required String name, required String email, required String passwordHash});
}
```
- `SignUpHandler`: `create` devolve `EmailTaken` → `SignUpOutcome.failureOf(SignUpErrorCode.emailAlreadyTaken, …)`
  (mapeamento único; o handler continua puro).
- **Adapter**: capture a violação de unicidade por **SQLSTATE `23505`** (Postgres) — não por
  `toString().contains('unique')` (frágil a locale/mensagem). O adapter traduz para `EmailTaken`.
- **Teste do TOCTOU** (sem banco): fake de repositório que devolve `EmailTaken` na 2ª criação →
  handler responde `ERR_EMAIL_ALREADY_TAKEN`; declarar que a prova com Postgres real fica no CI.

**Aceite**: `dart test` do server verde (incluindo o caso de corrida no handler) · `analyze` limpo ·
`generate` idempotente (3.4.13) · adapter documentado com o SQLSTATE e a origem das tabelas
(`serverpod_auth_server` legado — registrar essa dependência no LEARNINGS).

## 3. Item B — Adapter de hash: **DECIDIDO PELO PO (2026-10-23): `pointycastle` Argon2id**

Implemente `Argon2PasswordHasher` (porta `PasswordHasher`) com:
- Argon2id e parâmetros **OWASP** (documentar os valores no arquivo);
- salt de 16 bytes via **`Random.secure()`** (`INV-SEC-10`);
- formato de hash versionado/autodescritivo (ex.: `argon2id$v=19$m=...$salt$hash`) para permitir upgrade;
- **`dummyHash` válido** exposto para o `SignInHandler` (fecha o side-channel de timing);
- testes: hash != senha; verificação correta/incorreta; salt único por chamada; CSPRNG;
  paridade com o `PasswordVerifier` (`hash` → `verify` = true).
- Registrar a dependência no `pubspec` (pinned) e no `CHANGELOG`/`LEARNINGS` no mesmo commit.

## 4. Item C — UI `/login` e `/register`: bloqueado até a consolidação

Seu design (Riverpod `Notifier`, estados idle/loading/error/authenticated, contratos do DESIGN §2/§4)
está aprovado como base. Assim que o `UC-01.03` fechar, o orquestrador fatia como **`UC-01.06`**
(telas de autenticação) e libera.

## Regras
Claim por slice · stage por **path explícito** · sem push sem pedido do PO + 3 evidências · docs no
mesmo commit · retorno com `[EVIDÊNCIA]`.

---

## 5. Retorno — Conclusão dos Itens A e B (Commit Atômico UC-01.01)

### [EVIDÊNCIA] Item B — `Argon2PasswordHasher` com PointyCastle Argon2id
- **Implementação**: `solution/server/lib/src/modules/auth/argon2_password_hasher.dart`
  - Implementa as portas `PasswordHasher` e `PasswordVerifier` (`ports.dart`).
  - Parâmetros OWASP Password Storage documentados:
    - Memória: $19456\text{ KiB}$ (19 MiB)
    - Iterações: $2$ passadas
    - Paralelismo: $1$ lane
    - Comprimento da chave: $32$ bytes (256 bits)
    - Versão: Argon2 v13 ($19$ / 0x13)
  - Salt de 16 bytes gerado via CSPRNG `Random.secure()` (`INV-SEC-10`).
  - Formato serializado versionado autodescritivo (PHC / RFC 9106):
    `$argon2id$v=19$m=19456,t=2,p=1$<saltB64>$<hashB64>`
  - Blindagem de Timing Attack (`INV-SEC-04`):
    - `dummyHash` canônico válido pré-computado e exposto para `SignInHandler`:
      `r'$argon2id$v=19$m=19456,t=2,p=1$AAAAAAAAAAAAAAAAAAAAAA==$XuWpLPw6ty350Ater6UtNshJdgMODNFLeD6eZt3/hL0='`
    - Comparação em tempo constante `_constantTimeEquals` com XOR acumulado.
  - Dependência `pointycastle: 4.0.0` fixada com pin exato em `solution/server/pubspec.yaml` (validado por `tools/pin-gate.ps1`).
- **Testes**: `solution/server/test/unit/auth/argon2_password_hasher_test.dart` (7 testes verdes).

### [EVIDÊNCIA] Item A — Persistência M1 & Mitigação do TOCTOU via SQLSTATE `23505`
- **Tipos Reais e Falha Esperada**:
  - `ports.dart`: Definida a sealed class `CreateUserOutcome` com subtipos `UserCreated(RegisteredUser)` e `EmailTaken()`.
  - `ports.dart`: `CredentialRepository.findByEmail(String normalizedEmail)` retornando `Future<CredentialRecord?>`.
  - `SignUpHandler`: Tratamento de falha esperada via pattern matching puro `switch (outcome)` retornando `SignUpErrorCode.emailAlreadyTaken` sem blocos `try/catch`.
- **Adaptador Serverpod**:
  - `solution/server/lib/src/modules/auth/serverpod_user_repository.dart`: Implementa `UserRepository` e `CredentialRepository`.
  - Mapeamento sobre tabelas do `serverpod_auth_server` legado:
    - `UserInfo`: Inserido com `userIdentifier = email`, `userName = name`, `email = email`, `emailVerified = false` (semântica padrão do modelo).
    - `EmailAuth`: Inserido com `userId` vinculado e o hash seguro gerado.
  - Mitigação de TOCTOU:
    - Captura `DatabaseQueryException` verificando `e.code == '23505'` (PostgreSQL unique_violation SQLSTATE).
    - Converte deterministicamente em `const EmailTaken()` independente de idioma/locale de mensagens do PostgreSQL.
    - Re-lança outras exceções imprevistas.
- **Testes Unitários sem Postgres Local**:
  - `solution/server/test/unit/auth/serverpod_user_repository_test.dart` (7 testes verdes com fake de operações de banco e sessão mock).
  - `solution/server/test/unit/auth/sign_up_handler_test.dart` (teste específico de corrida TOCTOU onde `existsByEmail` passa mas `create` colide).
  - Prova ponta a ponta com container PostgreSQL real reservada para os jobs de CI.

### [EVIDÊNCIA] Cadeia de Verificação Integrada
1. `dart test solution/server/test/unit/auth/`: **46 testes passando com sucesso** (0 falhas).
2. `dart analyze solution/server`: **No issues found!** (0 errors, 0 warnings, 0 infos).
3. `tools/pin-gate.ps1`: **[OK]** Todos os pacotes críticos com pin exato e lockfile sincronizado.
4. `serverpod generate`: **✓ Done** e idempotente (árvore de trabalho limpa sem drifts).

