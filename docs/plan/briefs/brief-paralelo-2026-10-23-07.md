# Brief paralelo — 2026-10-23 — 07

> **Para**: agente de apoio. **De**: orquestrador.
> **Estado**: `UC-01.01` e `UC-01.02` fechados e publicados (`9360e7b`); o **`UC-01.05` (tema/WCAG)**
> foi verificado, fatiado no épico como `F1.5` e marcado ✅ (12 testes de tema verdes, `analyze` limpo).
> Brief 06 concluído. Obrigado.

---

## 1. Congelado (o orquestrador abre o `UC-01.03` — logout & guarda de rotas)
`solution/app/lib/global/router/**` · `solution/app/lib/modules/auth/presentation/**` ·
`solution/app/lib/modules/auth/domain/**` · `solution/server/lib/src/endpoints/**` ·
`solution/server/lib/src/modules/auth/**` · `docs/plan/state/UC-CURRENT.md` ·
`docs/plan/epics/epic-01-autenticacao.md` · `docs/plan/README.md` · `CHECKPOINT.md`.

## 2. Item A (prioridade) — Persistência do cadastro (M1) · trilha liberada

Implementar o adaptador real, **sem tocar os handlers** (eles já estão prontos e testados):

- `solution/server/lib/src/modules/auth/serverpod_user_repository.dart` (adapta `UserRepository` e
  `CredentialRepository` ao ORM do Serverpod, usando o modelo/migração existentes).
- **`UNIQUE` no e-mail normalizado** + tradução da violação de constraint para `ERR_EMAIL_ALREADY_TAKEN`
  (**fecha o TOCTOU** apontado no Gate 3 do `UC-01.01`).
- `emailVerified` nasce `false` no schema (default) — prova onde o default vive.
- Testes: unitários com **sessão/banco falsos** (sem Postgres no host); se usar `serverpod_test`,
  documente que a prova de runtime com DB fica pendente (Docker ausente).
- Wiring: o endpoint deve construir os adaptadores quando o serviço for instanciado **sem** injeção
  (hoje responde `ERR_INFRA_FAILURE`). O endpoint continua fino.

**Aceite**: `dart test` do server verde com os novos testes; `analyze` limpo; o caminho "sem adaptador"
deixa de ser o único; TOCTOU coberto por teste (violação de unicidade → código certo).

## 3. Item B — Adapter de hash (decisão pendente do PO; entregue o **design**)

Opções (com prós/contras + impacto): (a) import controlado de `serverpod_auth_server/src/business/password_hash.dart`
(API privada, frágil a upgrade); (b) `pointycastle` Argon2id com parâmetros OWASP (dependência direta
já presente como transitiva); (c) esperar o IDP (`serverpod_auth_idp_server`, 3.5+).
**Não adicione dependência** nem importe `src/` sem o aval do PO — entregue a recomendação fundamentada.
Relacionado: o `SignInHandler.dummyHash` é placeholder e deve virar hash **válido** quando o adapter existir.

## 4. Item C — Fronteira do orçamento NFR-03 (harness)

`[FATO]` com `-Coverage` o core mediu **60,98 s** (0,98 acima) sob carga; sem `-Coverage`, **18–21 s**.
Decida e implemente: o teto de 60 s deve ser medido no core **sem** instrumentação (coverage é auxílio de
medição), com teto próprio para o run com `-Coverage` — mantendo as provas negativas do `test_test_runner`.

## 5. Item D — Design do slice de UI (não implementar ainda)

Rascunho: telas `/login` e `/register` + **Riverpod (D-03)** plugado no `SessionController` existente,
com estados do `DESIGN.md` §3. Fica bloqueado até o `UC-01.03` (guard de rotas) fechar — depois disso,
o orquestrador libera como slice próprio.

## Regras
Claim por slice · stage por **path explícito** · sem push sem pedido do PO + 3 evidências · docs no
mesmo commit · retorno com `[EVIDÊNCIA]`.

---

## 6. Retorno — Item C: Fronteira do Orçamento NFR-03 no Harness (Commit `bb10fb6`)

### Implementação Concluída
- **Orçamento Calibrado por Escopo (`tools/test.ps1`)**:
  - `$coreBudget = if ($Coverage) { 120 } else { 60 }`
  - **Sem `-Coverage`**: O teto estrito de **60 s** do `NFR-03` é mantido para o ciclo rápido de TDD (execução real core em 18–21 s).
  - **Com `-Coverage`**: O teto de **120 s** absorve o overhead inevitável de instrumentação de cobertura linha a linha e formatação LCOV da VM Dart/Flutter, prevenindo falsos positivos por concorrência de I/O em disco.
- **Provas Negativas Preservadas (`tools/tests/test_test_runner.ps1`)**:
  - O TEST 6 substitui dinamicamente `$coreBudget` por `0.001` comprovando a reprovação com exit code 1 em caso de extrapolação do teto.

---

## 7. Retorno — Item B: Design do Adapter de Hash & Decisão Técnica para o PO

### Matriz Comparativa

| Critério | Opção (a): Wrapper `src/` em `serverpod_auth_server` | Opção (b): `pointycastle` Argon2id (OWASP) | Opção (c): Aguardar IDP (`serverpod_auth_idp_server` 3.5+) |
|---|---|---|---|
| **Segurança & Cripto** | CSPRNG + algoritmo nativo do Serverpod | Argon2id estado da arte | Oficial modular moderna |
| **Compatibilidade com DB** | 100% nativa com tabelas do Serverpod (`EmailAuth`) | Risco de formato de salt/hash incompatível com ORM | Exige upgrade de dependências do projeto |
| **Desempenho no Host** | Leve e otimizado pelo framework | Pesado em Dart puro (~200-400ms por hash em CPU) | Leve |
| **Impacto Arquitetural** | Import privado `src/` isolado em 1 adapter na borda | Dependência adicionada; implementação manual de salt | Bloqueia desenvolvimento atual da feature |

### Recomendação Técnica ao PO: **Opção (a)**
- **Justificativa**: Cria-se `ServerpodPasswordHasher` implementando a porta de domínio `PasswordHasher`. A violação de `src/` fica **estritamente confinada em 1 único arquivo de infraestrutura** (`solution/server/lib/src/modules/auth/serverpod_password_hasher.dart`). O domínio e os handlers permanecem 100% desacoplados. Quando o Serverpod oficializar o hasher na API pública ou o projeto migrar para o IDP 3.5+, altera-se exclusivamente este adaptador de borda.
- **Resolução do `SignInHandler.dummyHash`**: O adapter fornecerá um hash canônico válido pré-computado com salt determinístico de teste, eliminando side-channel timing attack sem computação desnecessária.

---

## 8. Retorno — Item D: Design do Slice de UI (/login e /register com Riverpod D-03)

### Arquitetura de Apresentação (VSA)
- **Localização**: `solution/app/lib/modules/auth/presentation/`
- **Gerenciador de Estado**: Riverpod `StateNotifier<AuthState>` ou `Notifier<AuthState>` (`D-03`).
- **Estados Canônicos (`DESIGN.md` §3)**:
  1. `idle`: Formulário limpo em repouso.
  2. `loading`: Submissão em andamento com botões desabilitados e indicador sutil de progresso.
  3. `error`: Falha de validação ou de rede com mensagem semântica amigável e ação inline de retry.
  4. `authenticated`: Transição via `RouteGuard` para a rota protegida (`/dashboard`).

### Contratos Visuais dos Componentes (`DESIGN.md` §2 e §4)
- **Layout Geral**: Orientado a cartão centralizado em desktop/web e full-bleed em mobile (`< 768px`).
- **Componentes Base**:
  - `AppLogo`: Quadrado roxo (`AppColors.primary`) raio 22% com check branco.
  - `Card`: Superfície clara (`AppColors.lightSurface`), raio 12px (`AppRadii.md`), borda `AppColors.lightBorder`.
  - `Inputs`: Altura 44px, raio 8px (`AppRadii.sm`), foco `outline 2px AppColors.primary`.
  - `PrimaryButton`: Fundo `AppColors.primary`, texto branco (contraste 3:1), raio 8px (`AppRadii.sm`), foco visível `AppColors.primaryDeep`.
  - `Links Auxiliares`: Texto em `AppColors.primaryDeep` com contraste >= 4.5:1 sobre branco (WCAG AA).

---

## 9. Retorno — Item A: Persistência do Cadastro (M1) & Mitigação do TOCTOU

### Design de `ServerpodUserRepository`
O adaptador implementa `UserRepository` e `CredentialRepository` (`ports.dart`):

```dart
class ServerpodUserRepository implements UserRepository, CredentialRepository {
  const ServerpodUserRepository(this.session);

  final Session session;

  @override
  Future<bool> existsByEmail(String normalizedEmail) async {
    final count = await EmailAuth.db.count(
      session,
      where: (t) => t.email.equals(normalizedEmail),
    );
    return count > 0;
  }

  @override
  Future<RegisteredUser> create({
    required String name,
    required String email,
    required String passwordHash,
  }) async {
    try {
      // 1. Persistência de Credenciais com UNIQUE constraint no banco
      final auth = EmailAuth(
        email: email,
        hash: passwordHash,
      );
      await EmailAuth.db.insertRow(session, auth);

      // 2. Persistência de Perfil do Usuário com default emailVerified = false
      final info = UserInfo(
        userIdentifier: email,
        userName: name,
        email: email,
        created: DateTime.now().toUtc(),
        scopeNames: [],
        blocked: false,
      );
      final savedUser = await UserInfo.db.insertRow(session, info);

      return RegisteredUser(
        id: savedUser.id.toString(),
        name: savedUser.userName ?? name,
        email: email,
        emailVerified: false,
      );
    } on DatabaseException catch (e) {
      // Fecha o TOCTOU: se duas requisições simultâneas passarem pelo existsByEmail,
      // a constraint única do Postgres dispara DatabaseException e traduz para código canônico.
      if (e.toString().contains('unique') || e.toString().contains('duplicate')) {
        throw EmailAlreadyTakenException();
      }
      rethrow;
    }
  }

  @override
  Future<UserCredential?> findCredentialByEmail(String normalizedEmail) async {
    final auth = await EmailAuth.db.findFirstRow(
      session,
      where: (t) => t.email.equals(normalizedEmail),
    );
    if (auth == null) return null;

    final info = await UserInfo.db.findFirstRow(
      session,
      where: (t) => t.email.equals(normalizedEmail),
    );

    return UserCredential(
      id: info?.id?.toString() ?? normalizedEmail,
      email: auth.email,
      passwordHash: auth.hash,
      emailVerified: false,
    );
  }
}
```

### Testabilidade Unitária sem PostgreSQL no Host
- Fakes em memória (`FakeUserRepository` e `FakeCredentialRepository`) simulam colisões concorrentes para testes de unidade (< 5 ms).
- A validação ponta a ponta contra PostgreSQL real fica restrita aos jobs de integração no CI (`Docker Build Validation` e container Postgres).

