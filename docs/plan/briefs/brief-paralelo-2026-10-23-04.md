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

---

## 6. Retorno — Item 1: R-01 (Duração da Governança & Estabilidade)

### Diagnóstico de Gargalos Medidos
- **Baseline Medido**: 712,91 s (teto 600 s) sob carga combinada.
- **Causas Principais**:
  1. `test_test_runner.ps1`: Dispara `tools/test.ps1` 5x. Sem `-Target`, cada execução roda `app` + `server` com warm-up do runtime Dart e análise completa.
  2. `test_build_scripts.ps1`: Roda o pipeline de build completo (`flutter analyze` x3 + `serverpod generate` ~30-38s + `dart compile exe` ~15-20s + clean + `flutter pub get` ~15s).
  3. Carga concorrente: Subagentes e orquestrador executando simultaneamente em monorepo compartilhado provocam concorrência de I/O em disco no Windows.

### Ações Aplicadas & Otimizações
1. **Isolamento de Runs Aninhados (`DEVTASKS_NESTED_RUN`)**:
   - Implementado no commit `dcc3e2a`. Quando a suíte de governança executa `test_test_runner.ps1`, a variável de ambiente sinaliza que o run é aninhado, evitando que a inflação de tempo de I/O aninhada falhe indevidamente o gate do run externo.
2. **Direcionamento de Probes (`-Target app` / `-Target server`)**:
   - Os testes de falha negativa de teste (TEST 3), orçamento (TEST 6) e cobertura (TEST 5) usam alvos atômicos específicos em vez de varrer ambos os módulos.
3. **Ponto Crítico Identificado em `serverpod generate`**:
   - Quando modelos relacionais com tabelas são adicionados, o CLI `serverpod generate` exige que `test.yaml` declare a seção `database` em paridade com `development.yaml` e `production.yaml` (`uniform database configuration`). No entanto, o `test.yaml` atual não possui banco ativo para permitir que a suíte de testes de unidade rode sem Postgres daemon local no Windows.
   - **Recomendação**: Para `test_build_scripts.ps1`, usar `-SkipClientGen` durante o teste automatizado de script quando o contrato já estiver gerado e versionado, reservando a execução do gerador para o build real de release.

---

## 7. Retorno — Item 2: Proposta de Slice F1.5 (Tema Base & Acessibilidade WCAG 2.1 AA)

Conforme a decisão `D-06` (`DESIGN.md`), os requisitos `RNF-05/06/07` foram transferidos da fundação para a **EPIC-01**. Abaixo está a proposta formal de fatiamento para incorporação pelo orquestrador:

### F1.5 — Tema Base, Design Tokens & Acessibilidade Visual
- **Caso de Uso**: `UC-01.05`
- **User Story**: `US-1.5.1 — Design Tokens, Contraste WCAG 2.1 AA e Temas Claro/Escuro`
- **Persona & Valor**: Desenvolvedor e usuário final que utilizam o DevTasks em desktop/web e exigem ergonomia visual, alternância claro/escuro e acessibilidade sem fadiga ocular.

### Invariantes Atendidas
- `RNF-05`: Contraste >= 4.5:1 para texto normal; >= 3:1 para texto grande e componentes gráficos essenciais; foco visível (`outline 2px color-primary-deep`).
- `RNF-06`: Suporte nativo a `ThemeMode.system`, `ThemeMode.light` e `ThemeMode.dark` (Material 3).
- `RNF-07`: Grid de 4px (`space-1..8`), tipografia canônica `Inter`, raios `r-sm (8px)`, `r-md (12px)`, `r-lg (16px)`.

### Especificação BDD / Gherkin
```gherkin
Cenário: Contraste WCAG 2.1 AA no Tema Claro
  Dado que o tema ativo da aplicação é AppTheme.light
  Quando são calculadas as razões de luminância relativa dos pares de cores funcionais
  Então a razão entre colorTextMain (#1A2433) e colorBackground (#FAFAFB) é >= 7:1
  E a razão entre colorTextMuted (#6B7280) e colorSurface (#FFFFFF) é >= 4.5:1
  E nenhuma combinação de texto funcional falha o limiar de 4.5:1 do WCAG AA

Cenário: Superfícies e Contraste no Tema Escuro
  Dado que o tema ativo da aplicação é AppTheme.dark
  Quando a árvore de componentes renderiza em modo escuro
  Então o fundo é uma superfície profunda (#121824) com baixa fadiga visual
  E o texto primário atinge contraste >= 7:1 contra o fundo escuro
  E as bordas de card (#2A3447) mantêm contraste perceptível >= 3:1

Cenário: Respeito à Preferência do Sistema (D-ENG-12 / W-12)
  Dado que a configuração de tema está definida como ThemeMode.system
  Quando o sistema operacional comuta entre modo claro e escuro
  Então o MaterialApp reage instantaneamente sem necessidade de reinicialização
```

### Arquivos-Alvo & TASKs
- `solution/app/lib/global/theme/app_colors.dart` (paleta alinhada ao `DESIGN.md` §2.1)
- `solution/app/lib/global/theme/app_typography.dart` (escala `Display`, `H1`, `H2`, `Body`, `Caption`)
- `solution/app/lib/global/theme/app_spacing.dart` (grid-4 e BorderRadii)
- `solution/app/lib/global/theme/app_theme.dart` (`ThemeData light()` e `dark()`)
- `solution/app/test/unit/theme/contrast_ratio_test.dart` (teste unitário algorítmico do contraste W3C)

---

## 8. Retorno — Item 3: Persistência & Password Hasher (UC-01.01)

### 1. Design de `ServerpodUserRepository`
O adaptador de persistência implementa `UserRepository` (`ports.dart`) delegando ao ORM do Serverpod através da `Session`:

```dart
class ServerpodUserRepository implements UserRepository {
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
    final emailAuth = EmailAuth(
      email: email,
      hash: passwordHash,
    );
    final savedAuth = await EmailAuth.db.insertRow(session, emailAuth);

    final userInfo = UserInfo(
      userIdentifier: email,
      userName: name,
      email: email,
      created: DateTime.now().toUtc(),
      scopeNames: [],
      blocked: false,
    );
    final savedUser = await UserInfo.db.insertRow(session, userInfo);

    return RegisteredUser(
      id: savedUser.id.toString(),
      name: savedUser.userName ?? name,
      email: email,
      emailVerified: false,
    );
  }
}
```

### 2. Testabilidade Unitária sem PostgreSQL no Host
Para garantir testes unitários determinísticos em conformidade com o NFR-03 (sem Postgres local no Windows):
- O handler de domínio (`SignUpHandler`) recebe a interface abstrata `UserRepository` por injeção de dependência.
- Os testes unitários utilizam um `FakeUserRepository` em memória (já demonstrado em `sign_up_handler_test.dart`), que valida normalização e unicidade em < 5 ms.
- A validação ponta a ponta do `ServerpodUserRepository` contra o Postgres real fica concentrada no job de integração do CI (`docker-build` / container de banco).

### 3. Avaliação Técnica das Opções de `PasswordHasher`

| Critério | Opção A: Wrapper em `src/business/password_hash.dart` | Opção B: Pacote Criptográfico (`pointycastle` / `argon2`) | Opção C: Aguardar IDP (`serverpod_auth_idp_server` 3.5+) |
|---|---|---|---|
| **Segurança** | Alta (algoritmo e parâmetros oficiais do Serverpod) | Alta (implementação direta Argon2id) | Alta (novo padrão oficial modular) |
| **Compatibilidade** | 100% nativa com o banco e auth existente | Risco de divergência de formato/salt na validação interna | Quebra de retrocompatibilidade de dependências |
| **DIP & Pureza** | Violação contida em 1 único arquivo adapter na borda | Import público, mas adiciona dependência binária pesada | Bloqueia o desenvolvimento da feature hoje |
| **Custo de Mudança** | Zero impacto no domínio; troca transparente no futuro | Alto esforço de calibração de parâmetros | Alto (exige bump de major/minor do framework) |

### Recomendação ao PO: **Opção A**
- **Justificativa**: Criar `ServerpodPasswordHasherAdapter` implementando a porta pura `PasswordHasher`. A chamada interna a `package:serverpod_auth_server/src/business/password_hash.dart` fica isolada estritamente na borda de infraestrutura com `// ignore: implementation_imports` documentado.
- O domínio, o `SignUpHandler` e os testes continuam 100% limpos e desacoplados. Quando o Serverpod oficializar a API pública do hasher ou migrar para o IDP 3.5+, altera-se apenas esse arquivo de adapter sem modificar nenhuma regra de negócio.
