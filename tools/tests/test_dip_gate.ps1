# tools/tests/test_dip_gate.ps1
# Test suite for Dependency Inversion Principle Gate (DIP Gate - NC-15)
# Valida pureza estrita do domínio com provas negativas automatizadas.

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "../..")
Set-Location $RepoRoot

$psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell.exe" }
$DipGateScript = Join-Path $RepoRoot "tools/dip-gate.ps1"

Write-Host "=== TEST 1: Verificar existência do tools/dip-gate.ps1 ==="
if (-not (Test-Path $DipGateScript)) {
    throw "FAIL: tools/dip-gate.ps1 não existe."
}
Write-Host "Pass: Script do DIP Gate encontrado."

Write-Host "`n=== TEST 2: Validação da base de código canônica atual (exit 0) ==="
& $psExe -ExecutionPolicy Bypass -NoProfile -File $DipGateScript
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: DIP Gate falhou na árvore de código canônica (exit code $LASTEXITCODE)."
}
Write-Host "Pass: Domínio/Kernel canônico atual 100% puro e conforme."

# Diretório de fixture temporária para testes negativos
$tempFixtureDir = Join-Path ([System.IO.Path]::GetTempPath()) "devtasks_dip_fixtures_$(Get-Random)"
New-Item -ItemType Directory -Path $tempFixtureDir -Force | Out-Null

try {
    Write-Host "`n=== TEST 3: Prova Negativa - Violação com 'dart:io' deve falhar (exit 1) ==="
    $fileIo = Join-Path $tempFixtureDir "io_violation.dart"
    Set-Content -Path $fileIo -Value "import 'dart:io';`nvoid doSomething() {}"
    
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $out1 = & $psExe -ExecutionPolicy Bypass -NoProfile -File $DipGateScript -Paths @($tempFixtureDir) 2>&1 | Out-String
    $code1 = $LASTEXITCODE
    $ErrorActionPreference = $prevEap

    if ($code1 -eq 0) {
        throw "FAIL: DIP Gate aceitou incorretamente import de 'dart:io' (exit code 0)."
    }
    Write-Host "Pass: Violação com 'dart:io' bloqueada com exit code $code1."

    Write-Host "`n=== TEST 4: Prova Negativa - Violação com 'package:flutter/material.dart' deve falhar (exit 1) ==="
    Remove-Item $fileIo -Force
    $fileFlutter = Join-Path $tempFixtureDir "flutter_violation.dart"
    Set-Content -Path $fileFlutter -Value "import 'package:flutter/material.dart';`nclass MyEntity {}"

    $ErrorActionPreference = "Continue"
    $out2 = & $psExe -ExecutionPolicy Bypass -NoProfile -File $DipGateScript -Paths @($tempFixtureDir) 2>&1 | Out-String
    $code2 = $LASTEXITCODE
    $ErrorActionPreference = $prevEap

    if ($code2 -eq 0) {
        throw "FAIL: DIP Gate aceitou incorretamente import de 'package:flutter' (exit code 0)."
    }
    Write-Host "Pass: Violação com 'package:flutter' bloqueada com exit code $code2."

    Write-Host "`n=== TEST 5: Prova Negativa - Violação com 'package:serverpod' deve falhar (exit 1) ==="
    Remove-Item $fileFlutter -Force
    $fileServerpod = Join-Path $tempFixtureDir "serverpod_violation.dart"
    Set-Content -Path $fileServerpod -Value "import 'package:serverpod/serverpod.dart';`nclass ServerEntity {}"

    $ErrorActionPreference = "Continue"
    $out3 = & $psExe -ExecutionPolicy Bypass -NoProfile -File $DipGateScript -Paths @($tempFixtureDir) 2>&1 | Out-String
    $code3 = $LASTEXITCODE
    $ErrorActionPreference = $prevEap

    if ($code3 -eq 0) {
        throw "FAIL: DIP Gate aceitou incorretamente import de 'package:serverpod' (exit code 0)."
    }
    Write-Host "Pass: Violação com 'package:serverpod' bloqueada com exit code $code3."

    Write-Host "`n=== TEST 6: Fixture limpa com imports intra-domínio deve passar (exit 0) ==="
    Remove-Item $fileServerpod -Force
    $fileClean = Join-Path $tempFixtureDir "clean_entity.dart"
    Set-Content -Path $fileClean -Value "import 'clock.dart';`nimport 'failures.dart';`nclass PureEntity {}"

    & $psExe -ExecutionPolicy Bypass -NoProfile -File $DipGateScript -Paths @($tempFixtureDir)
    if ($LASTEXITCODE -ne 0) {
        throw "FAIL: Fixture limpa foi reprovada indevidamente (exit code $LASTEXITCODE)."
    }
    Write-Host "Pass: Fixture limpa aprovada com exit code 0."

} finally {
    if (Test-Path $tempFixtureDir) {
        Remove-Item -Path $tempFixtureDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`n>>> ALL DIP GATE ACCEPTANCE TESTS PASSED SUCCESSFULLY! <<<"
exit 0

