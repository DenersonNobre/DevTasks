# tools/dip-gate.ps1
# Gate de Inversão de Dependência (DIP - Dependency Inversion Principle)
# Garante que o Domínio e Shared Kernel permaneçam 100% puros (sem acoplamento com infraestrutura).
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string[]]$Paths
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
Set-Location $RepoRoot

Write-Host "==> [DIP Gate] Verificando isolamento de Domínio e Kernel (DIP)..."

# Lista de pacotes e bibliotecas de infraestrutura estritamente proibidos no núcleo de domínio
$prohibitedImports = @(
    "dart:io",
    "dart:ui",
    "dart:html",
    "package:flutter/",
    "package:http/",
    "package:http\b",
    "package:dio/",
    "package:sqflite",
    "package:serverpod",
    "package:shared_preferences",
    "package:path_provider"
)

# Se nenhum caminho for informado, busca automaticamente o kernel e módulos de domínio
$targetDirs = @()
if ($Paths -and $Paths.Count -gt 0) {
    foreach ($p in $Paths) {
        if (Test-Path $p) {
            $targetDirs += (Resolve-Path $p).Path
        }
    }
} else {
    # Alvos canônicos do DevTasks
    $kernelPath = Join-Path $RepoRoot "solution/app/lib/global/kernel"
    if (Test-Path $kernelPath) {
        $targetDirs += $kernelPath
    }

    # Busca pastas /domain em qualquer módulo
    $domainPaths = Get-ChildItem -Path (Join-Path $RepoRoot "solution") -Directory -Recurse -Filter "domain" -ErrorAction SilentlyContinue
    foreach ($d in $domainPaths) {
        $targetDirs += $d.FullName
    }
}

if ($targetDirs.Count -eq 0) {
    Write-Host "  [INFO] Nenhum diretório de domínio encontrado para análise."
    exit 0
}

$violations = @()

foreach ($dir in $targetDirs) {
    $files = Get-ChildItem -Path $dir -Filter "*.dart" -Recurse -File -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        $lines = Get-Content -Path $file.FullName
        $lineNum = 0
        foreach ($line in $lines) {
            $lineNum++
            $trimmed = $line.Trim()
            if ($trimmed -match "^import\s+['""]([^'""]+)['""]" -or $trimmed -match "^export\s+['""]([^'""]+)['""]") {
                $imported = $Matches[1]
                foreach ($prohibited in $prohibitedImports) {
                    if ($imported -match $prohibited) {
                        $relPath = Resolve-Path -Path $file.FullName -Relative
                        $violations += [PSCustomObject]@{
                            File = $relPath
                            Line = $lineNum
                            Import = $imported
                            Rule = $prohibited
                        }
                    }
                }
            }
        }
    }
}

if ($violations.Count -gt 0) {
    Write-Error @"
[DIP-VIOLATION] Foram encontradas $($violations.Count) violação(ões) do princípio de inversão de dependência (DIP)!
O Domínio e o Shared Kernel NUNCA devem importar infraestrutura, frameworks de apresentação ou banco de dados.

Violações detectadas:
$($violations | ForEach-Object { "  - $($_.File):$($_.Line) -> importa '$($_.Import)' (proibido: $($_.Rule))" } | Out-String)
"@
    exit 1
}

Write-Host "  [OK] Todos os arquivos analisados estão 100% puros e aderentes ao DIP."
Write-Host "==> [DIP Gate] Governança arquitetural aprovada!"
exit 0

