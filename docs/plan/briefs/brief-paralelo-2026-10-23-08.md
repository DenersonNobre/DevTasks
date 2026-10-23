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

## 3. Item B — Adapter de hash: **aguardando decisão do PO**

Sua recomendação é a opção (a) (wrapper `src/` confinado). **Não implemente** até o PO decidir entre
(a) wrapper `src/`, (b) `pointycastle` Argon2id, (c) aguardar IDP 3.5+. Se ele aprovar (a), o adapter
deve também fornecer um **`dummyHash` válido** (hoje é placeholder) para fechar o side-channel.

## 4. Item C — UI `/login` e `/register`: bloqueado até a consolidação

Seu design (Riverpod `Notifier`, estados idle/loading/error/authenticated, contratos do DESIGN §2/§4)
está aprovado como base. Assim que o `UC-01.03` fechar, o orquestrador fatia como **`UC-01.06`**
(telas de autenticação) e libera.

## Regras
Claim por slice · stage por **path explícito** · sem push sem pedido do PO + 3 evidências · docs no
mesmo commit · retorno com `[EVIDÊNCIA]`.
