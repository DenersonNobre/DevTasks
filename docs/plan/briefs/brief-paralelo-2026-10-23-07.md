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
