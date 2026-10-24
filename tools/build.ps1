# tools/build.ps1
# Automação de pré-flight de toolchain e build em 1 comando (F0.2 / UC-00.02)
[CmdletBinding()]
param(
    [switch]$PreflightOnly,
    [switch]$SimulateMissingFlutter,
    [switch]$SkipCompile
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
Set-Location $RepoRoot

Write-Host "==> [DevTasks] Verificando Toolchain (Preflight)..."

# 1. Verificação do Flutter
if ($SimulateMissingFlutter) {
    Write-Error "[FAIL-FAST] Flutter SDK ausente no PATH ou simulação de ambiente quebrado ativada."
    exit 1
}

$flutterCmd = Get-Command "flutter" -ErrorAction SilentlyContinue
if (-not $flutterCmd) {
    Write-Error "[FAIL-FAST] Flutter SDK ausente no PATH. Instale o Flutter SDK versão >= 3.47.x."
    exit 1
}

# Resolução rápida e offline de versão
$flutterVersionStr = $null
$flutterBin = Split-Path $flutterCmd.Source -Parent
$flutterRoot = Split-Path $flutterBin -Parent
$flutterVersionFile = Join-Path $flutterRoot "version"

if (Test-Path $flutterVersionFile) {
    $flutterVersionStr = (Get-Content $flutterVersionFile -Raw).Trim()
}

if (-not $flutterVersionStr) {
    $env:PUB_ENVIRONMENT = "devtasks_preflight"
    $rawOut = & flutter --version --no-version-check 2>&1 | Out-String
    if ($rawOut -match "Flutter\s+(\d+\.\d+\.\d+)") {
        $flutterVersionStr = $Matches[1]
    }
}

if ($flutterVersionStr) {
    if ($flutterVersionStr -match "^(\d+\.\d+\.\d+)") {
        $flutterVersion = [version]$Matches[1]
        $minFlutterVersion = [version]"3.47.0"
        if ($flutterVersion -lt $minFlutterVersion) {
            Write-Error "[FAIL-FAST] Versão do Flutter ($flutterVersion) é inferior à mínima requerida ($minFlutterVersion)."
            exit 1
        }
        Write-Host "  [OK] Flutter: $flutterVersion (>= $minFlutterVersion)"
    } else {
        Write-Host "  [OK] Flutter: $flutterVersionStr"
    }
} else {
    Write-Host "  [OK] Flutter detectado em $($flutterCmd.Source)"
}

# 2. Verificação do Dart
$dartCmd = Get-Command "dart" -ErrorAction SilentlyContinue
if (-not $dartCmd) {
    Write-Error "[FAIL-FAST] Dart SDK ausente no PATH. Instale o Dart SDK versão >= 3.13.x."
    exit 1
}

$dartVersionStr = $null
$dartVersionFile = Join-Path $flutterRoot "bin/cache/dart-sdk/version"
if (Test-Path $dartVersionFile) {
    $dartVersionStr = (Get-Content $dartVersionFile -Raw).Trim()
}

if ($dartVersionStr) {
    if ($dartVersionStr -match "^(\d+\.\d+\.\d+)") {
        $dartVersion = [version]$Matches[1]
        $minDartVersion = [version]"3.13.0"
        if ($dartVersion -lt $minDartVersion) {
            Write-Error "[FAIL-FAST] Versão do Dart ($dartVersion) é inferior à mínima requerida ($minDartVersion)."
            exit 1
        }
        Write-Host "  [OK] Dart: $dartVersion (>= $minDartVersion)"
    } else {
        Write-Host "  [OK] Dart: $dartVersionStr"
    }
} else {
    Write-Host "  [OK] Dart detectado em $($dartCmd.Source)"
}

# 3. Ferramentas Complementares
$dockerCmd = Get-Command "docker" -ErrorAction SilentlyContinue
if ($dockerCmd) {
    Write-Host "  [OK] Docker: $($dockerCmd.Source)"
} else {
    Write-Host "  [INFO] Docker não detectado no host atual (necessário para containerização F0.5)."
}

# 4. Verificação do Contrato OpenAPI 3.1
$openApiFile = Join-Path $RepoRoot "docs/api/openapi.yaml"
if (-not (Test-Path $openApiFile)) {
    Write-Error "[FAIL-FAST] Contrato OpenAPI ausente: docs/api/openapi.yaml (fonte única da verdade)."
    exit 1
}
Write-Host "  [OK] Contrato OpenAPI 3.1: docs/api/openapi.yaml"

if ($PreflightOnly) {
    Write-Host "==> [Preflight] Toolchain validada com sucesso!"
    exit 0
}

# 5. Execução do Build
Write-Host "`n==> [DevTasks] Executando resolução de dependências no workspace raiz..."
& dart pub get
if ($LASTEXITCODE -ne 0) {
    Write-Error "[BUILD-FAIL] 'dart pub get' falhou no workspace raiz."
    exit $LASTEXITCODE
}

Write-Host "==> [DevTasks] Analisando membros do workspace..."
& flutter analyze solution/app
if ($LASTEXITCODE -ne 0) {
    Write-Error "[BUILD-FAIL] 'flutter analyze' falhou em solution/app."
    exit $LASTEXITCODE
}

& dart analyze solution/api
if ($LASTEXITCODE -ne 0) {
    Write-Error "[BUILD-FAIL] 'dart analyze' falhou em solution/api."
    exit $LASTEXITCODE
}

# 6. Artefato de build: compila a API shelf e ASSERE o artefato gerado.
if (-not $SkipCompile) {
    Write-Host "`n==> [DevTasks] Compilando artefato da API (dart compile exe)..."
    $buildDir = Join-Path $RepoRoot "solution/builds"
    New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
    $artifact = Join-Path $buildDir "devtasks-api.exe"
    if (Test-Path $artifact) { Remove-Item $artifact -Force }

    Push-Location "solution/api"
    try {
        & dart compile exe bin/server.dart -o $artifact
        if ($LASTEXITCODE -ne 0) {
            Write-Error "[BUILD-FAIL] 'dart compile exe' falhou para a API."
            exit $LASTEXITCODE
        }
    } finally {
        Pop-Location
    }

    if (-not (Test-Path $artifact)) {
        Write-Error "[BUILD-FAIL] Artefato esperado ausente: solution/builds/devtasks-api.exe"
        exit 1
    }
    $artifactSize = (Get-Item $artifact).Length
    if ($artifactSize -le 0) {
        Write-Error "[BUILD-FAIL] Artefato gerado está vazio: solution/builds/devtasks-api.exe"
        exit 1
    }
    Write-Host "  [OK] Artefato: solution/builds/devtasks-api.exe ($([Math]::Round($artifactSize / 1MB, 2)) MB)"
}

Write-Host "`n==> [DevTasks] Build concluído com sucesso!"
exit 0
