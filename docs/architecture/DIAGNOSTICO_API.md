# Diagnóstico Arquitetural da API (`solution/api`)

> **Data**: 2026-10-24 · **Contexto**: Migração EPIC-08 (Serverpod $\rightarrow$ Dart/Shelf + PostgreSQL puro) · **Decisões**: D-02, D-07, D-08

---

## 1. Resumo Executivo de Conformidade

Este diagnóstico analisa a aderência técnica da API do DevTasks (`solution/api`) aos paradigmas e acordos operacionais do projeto: **VSA (Vertical Slice Architecture)**, **MVVM**, **Ports & Adapters (Hexagonal)**, **Object Calisthenics**, **SOLID** e **Clean Code**.

| Paradigma | Status | Nível de Aderência | Observação Principal |
| :--- | :---: | :---: | :--- |
| **Ports & Adapters (Hexagonal)** | Aprovado | **100%** | DIP/ISP estrito; domínio puro sem acoplamento a frameworks ou infraestrutura. |
| **Object Calisthenics** | Aprovado | **95%** | 1 indentação por método, sem `else`, VOs encapsulando primitivos e coleções de 1ª classe. |
| **SOLID** | Aprovado | **100%** | Segregação estrita (ex.: `CredentialRepository` vs `UserRepository`), inversão de dependência na fronteira. |
| **Clean Code** | Aprovado | **95%** | Early return, identificadores sem abreviações, falhas esperadas como valor (`Result`/`Outcome`). |
| **VSA (Vertical Slice)** | Em evolução | **70%** (Transição) | Módulos organizados por feature (`auth`, `workspace`, `projects`), mas camada HTTP atual ainda agregada centralmente. |
| **MVVM** | N/A | **N/A na API** | MVVM é o padrão da UI do App (`D-07`); na API adota-se Command $\rightarrow$ Handler $\rightarrow$ Outcome / Projection DTO. |

---

## 2. Análise Detalhada por Pilar

### 2.1 VSA (Vertical Slice Architecture)

- `[FATO]` **Modularização**: O código de negócio está estruturado por módulos funcionais em `solution/api/lib/src/modules/` (`auth`, `workspace`, `projects`), contendo suas respectivas entidades, value objects, portas e handlers.
- `[FATO]` **Camada HTTP**: A infraestrutura HTTP atual está concentrada em `lib/src/http/` (`router.dart`, `cors_middleware.dart`, `error_middleware.dart`, `json_response.dart`), expondo por enquanto apenas a rota central `/health`.
- `[INFERÊNCIA]` A transição para VSA completo se consolidará nas fatias `UC-08.03b`, `UC-08.04b` e `UC-08.05b`. Nelas, os handlers HTTP de cada caso de uso devem residir próximos à sua respectiva fatia (ex.: `lib/src/modules/auth/infrastructure/http/` ou `presentation/`), com extensões de roteamento locais (`Router authRoutes(...)`), evitando que o `router.dart` central se torne um ponto de acoplamento com múltiplos imports de domínio.

### 2.2 MVVM vs Camada da API

- `[FATO]` **Padrão de Interface do App**: A decisão `D-07` estabelece MVVM unidirecional para a apresentação do **App Móvel Flutter** (`solution/app`), onde 1 Caso de Uso = 1 ViewModel + State imutável + Intents via Riverpod.
- `[FATO]` **Padrão da API**: Na API Shelf (backend), o padrão canônico adotado é **Ports & Adapters + CQRS Light**:
  - **Comandos**: `SignUpCommand`, `SignInCommand` (dados brutos da fronteira).
  - **Handlers**: `SignUpHandler`, `SignInHandler` (orquestração do caso de uso).
  - **Resultados**: `SignUpOutcome`, `GuardOutcome` (modelagem de sucesso vs falha esperada como valor).
  - **Projeções de Fronteira**: `WorkspaceWithRole.toJson()`, `RegisteredUser` (representações desacopladas da persistência física).
- `[INFERÊNCIA]` A API não adota nem necessita de ViewModels de UI, mas suas projeções de saída cumprem de forma idêntica o papel de desacoplar o esquema de dados de transporte da estrutura interna do banco.

### 2.3 Ports & Adapters (Hexagonal / DIP)

- `[FATO]` **Pureza Total de Domínio**: Os subdiretórios `domain/` (`email.dart`, `password.dart`, `workspace_name.dart`, `workspace_entity.dart`, `workspace_member_role.dart`, `project_name.dart`, `project_entity.dart`) têm **zero** dependências externas — sem imports de `shelf`, `postgres`, `dart:io`, `serverpod` ou bibliotecas de I/O.
- `[FATO]` **Portas Granulares**: Cada módulo define suas necessidades estritamente via `abstract interface class` em `ports.dart`:
  - `auth`: `UserRepository`, `PasswordHasher`, `CredentialRepository`, `PasswordVerifier`, `SessionAuthenticator`, `SessionRepository`.
  - `workspace`: `WorkspaceRepository`.
  - `projects`: `ProjectRepository`.
  - `db`: `SqlExecutor`, `MigrationStore`.
- `[FATO]` **Segregação de Interfaces (ISP)**: O `CredentialRepository` (que expõe o hash para o login) é completamente segregado do `UserRepository` (que apenas cadastra e checa unicidade). O `SignUpHandler` não tem acesso a métodos que retornem hashes de senha.

### 2.4 Object Calisthenics

1. **Apenas 1 nível de indentação por método**: 100% dos métodos de negócio analisados respeitam a regra por meio de early returns, guards e pattern matching (`switch`).
2. **Não use a palavra-chave ELSE**: Zero ocorrências de `else` nos handlers e Value Objects inspecionados.
3. **Encapsule todos os tipos primitivos**:
   - E-mail encapsulado em `Email` (com normalização e mascaramento no `toString()`).
   - Senha encapsulada em `Password` (com validação estrita de política).
   - Nomes de workspace e projeto encapsulados em `WorkspaceName` e `ProjectName`.
4. **Coleções de primeira classe**: `InMemoryRateLimiter` encapsula a lista duplamente ligada LRU e o mapa de contadores sob uma abstração fechada com teto de memória garantido em O(1).
5. **Um ponto por linha (Lei de Demeter)**: Handlers e serviços interagem apenas com suas portas diretas sem navegações profundas.
6. **Não abrevie**: Identificadores autoexplicativos (`SignUpHandler`, `RegisteredUser`, `SessionRecord`).
7. **Mantenha as entidades pequenas**: Todas as classes possuem tamanho reduzido (abaixo de 150 LOC).
8. **Não use classes com mais de 2 variáveis de instância no domínio**: Quase a totalidade das entidades de domínio possui 1 ou 2 atributos essenciais (ex.: `Email.value`, `WorkspaceName.value`, `WorkspaceEntity.id, .name`).
9. **Sem Getters/Setters anêmicos**: Imutabilidade estrita (`final`, `const`).

### 2.5 SOLID

- **Single Responsibility Principle (SRP)**: Cada classe desempenha uma única função bem delimitada:
  - `Argon2PasswordHasher`: derivação e verificação criptográfica Argon2id.
  - `TokenGenerator`: geração de entropia (CSPRNG) e cálculo de digest SHA-256 canônico.
  - `SessionGuard`: proteção de acesso por sessão.
  - `Migrator`: coordenação determinística de scripts SQL versionados.
- **Open/Closed Principle (OCP)**: Handlers e serviços são abertos para extensão via adaptadores (ex.: Postgres real, SQLite de teste, repositórios em memória) sem necessidade de alterar o código de negócio.
- **Liskov Substitution Principle (LSP)**: As implementações fake criadas para os testes unitários (`_FakeUserRepository`, `InMemorySessionRepository`, `_FakeWorkspaceRepository`, `_FakeProjectRepository`) satisfazem 100% dos contratos das portas sem comportamentos anômalos.
- **Interface Segregation Principle (ISP)**: Interfaces pequenas e focadas nas reais necessidades de cada consumidor.
- **Dependency Inversion Principle (DIP)**: O fluxo de controle aponta sempre para abstrações, com injeção de dependência via construtor.

### 2.6 Clean Code & Segurança Defensiva

- `[FATO]` **Result / Outcome vs Exceções**: No domínio, falhas de negócio esperadas (validação de formato, credenciais incorretas, e-mail já em uso) são modeladas como tipos de retorno explícitos (`SignUpOutcome`, `GuardOutcome`), preservando exceções apenas para anomalias não previsíveis da infraestrutura.
- `[FATO]` **Fronteira Segura contra Vazamentos (`INV-SEC-05`)**: O middleware central `errorMiddleware()` intercepta exceções não tratadas e formata a resposta como `500 ERR_INFRA_FAILURE` genérico, impedindo que detalhes de infraestrutura ou stack traces cheguem ao cliente.
- `[FATO]` **Mitigação de Timing Attack (`INV-SEC-04`)**:
  - `SignInHandler`: Quando o e-mail não existe, o handler executa a verificação contra `SignInHandler.dummyHash`, garantindo que o tempo de resposta seja constante mesmo quando não há usuário.
  - `SignUpHandler`: O cálculo do hash da senha é executado antes da verificação de e-mail duplicado para não vazar a existência da conta por tempo de computação.

---

## 3. Recomendações e Próximos Passos (`UC-08.03b`+)

1. **Roteamento por Slice (VSA)**: Ao construir as rotas de auth (`/auth/sign-up`, `/auth/sign-in`, etc.) no `UC-08.03b`, criar os endpoints dentro de `lib/src/modules/auth/infrastructure/http/` e apenas montar os roteadores locais no pipeline central de `router.dart`.
2. **Desserialização com Value Objects**: No binding dos corpos HTTP para DTOs, utilizar diretamente os VOs de domínio (`Email.parse`, `Password.validate`, `WorkspaceName.create`) para fail-early uniforme antes de atingir os handlers.

