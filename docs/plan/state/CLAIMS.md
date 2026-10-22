# Governança de Concorrência & Protocolo de Claims

> Fonte normativa: `~/.agents/rules/subagents.md` · Schema: `claims.schema.json` · Tooling: `tools/bin/claims`.

## 1. O que é um Claim?

Um **Claim** é uma reserva mecânica e exclusiva de Caso de Uso (`UC-XX.YY`) para um agente ou desenvolvedor durante a sua janela de execução (TTL padrão: 90 minutos).

O Git hook `tools/hooks/commit-msg` atua como um **poka-yoke mecânico**: qualquer commit contendo a assinatura `(UC-XX.YY)` no assunto é rejeitado se não houver um claim ativo correspondente no repositório.

## 2. Comandos Operacionais

O gerenciamento de claims é feito via `tools/bin/claims` (PowerShell, CMD ou Shell POSIX):

### Emitir um Claim (Início do UC)
```bash
# Via PowerShell
powershell.exe -ExecutionPolicy Bypass -File tools/bin/claims.ps1 claim -slice UC-01.01 -owner coder

# Via Windows CMD
tools\bin\claims.cmd claim -slice UC-01.01 -owner coder

# Via Shell POSIX
tools/bin/claims claim -slice UC-01.01 -owner coder
```

### Consultar Status de um Claim
```bash
tools/bin/claims check -slice UC-01.01
# Exit code 0 = ATIVO
# Exit code 1 = INATIVO OU EXPIRADO
```

### Listar Todos os Claims Ativos
```bash
tools/bin/claims list
```

### Liberar um Claim (Pós-Commit Consolidado)
```bash
tools/bin/claims release -slice UC-01.01
```

## 3. Localização do Estado

- Os claims vivos são armazenados em arquivos JSON temporários sob `.git/claims/<slice>.json`.
- Como vivem dentro de `.git/`, não poluem a working tree nem são commitados.
- O schema formal de validação é auditado por `docs/plan/state/claims.schema.json`.
