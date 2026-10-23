# tools/build.ps1
# Automação de pré-flight de toolchain e build em 1 comando (F0.2 / UC-00.02)
[CmdletBinding()]
param(
    [switch]$PreflightOnly,
    [switch]$SimulateMissingFlutter,
    [string]$SimulateServerpodCliVersion,
    [switch]$SkipClientGen,
    [switch]$SkipCompile
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
Set-Location $RepoRoot

# Resolve o CLI `serverpod` sem depender de PATH do host: comando no PATH,
# binário do pub cache (Windows/Linux/Puro) ou `dart pub global run`.
function Resolve-ServerpodCli {
    $cmd = Get-Command "serverpod" -ErrorAction SilentlyContinue
    if ($cmd) {
        return [pscustomobject]@{
            Exe     = $cmd.Source
            Prefix  = @()
            Display = $cmd.Source
        }
    }

    $candidates = @()
    if ($env:LOCALAPPDATA) {
        $candidates += (Join-Path $env:LOCALAPPDATA "Pub\Cache\bin\serverpod.bat")
        $candidates += (Join-Path $env:LOCALAPPDATA "Pub\Cache\bin\serverpod")
    }
    if ($env:USERPROFILE) {
        $candidates += (Join-Path $env:USERPROFILE ".pub-cache\bin\serverpod")
    }
    if ($env:HOME) {
        $candidates += (Join-Path $env:HOME ".pub-cache\bin\serverpod")
    }
    if ($env:PUB_CACHE) {
        $candidates += (Join-Path $env:PUB_CACHE "bin\serverpod")
    }
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            return [pscustomobject]@{
                Exe     = $candidate
                Prefix  = @()
                Display = $candidate
            }
        }
    }

    $dart = Get-Command "dart" -ErrorAction SilentlyContinue
    if ($dart) {
        $installed = & dart pub global list 2>$null | Select-String -Pattern "^serverpod_cli\s"
        if ($installed) {
            return [pscustomobject]@{
                Exe     = $dart.Source
                Prefix  = @("pub", "global", "run", "serverpod_cli:serverpod")
                Display = "dart pub global run serverpod_cli:serverpod"
            }
        }
    }

    return $null
}

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

# Resolução rápida e offline de versão (evita git/network hanging do wrapper .bat)
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
    # Extrai parte semver x.y.z
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
# O CLI Serverpod é obrigatório: sem ele o client (contrato client↔server) não é
# gerado e o build entregaria um artefato sem contrato — gate mentiroso.
$serverpod = Resolve-ServerpodCli
if (-not $serverpod) {
    Write-Error "[FAIL-FAST] Serverpod CLI ausente. Provisione com 'dart pub global activate serverpod_cli 3.4.13' e garanta o binário no PATH (ou no pub cache)."
    exit 1
}
$cliVersion = $null
if ($SimulateServerpodCliVersion) {
    $cliVersion = $SimulateServerpodCliVersion
} else {
    try {
        $prefix = $serverpod.Prefix
        $cliVersionOut = & $serverpod.Exe @prefix --version 2>&1 | Out-String
        if ($cliVersionOut -match "Serverpod\s+version:\s*(\d+\.\d+\.\d+)") {
            $cliVersion = $Matches[1]
        }
    } catch {
        Write-Warning "Não foi possível obter a versão do Serverpod CLI via --version."
    }
}

$expectedCliVersion = "3.4.13"
$serverPubspecFile = Join-Path $RepoRoot "solution/server/pubspec.yaml"
if (Test-Path $serverPubspecFile) {
    $spContent = Get-Content $serverPubspecFile -Raw
    if ($spContent -match "(?m)^\s*serverpod:\s*(\d+\.\d+\.\d+)") {
        $expectedCliVersion = $Matches[1]
    }
}

if ($cliVersion -and $cliVersion -ne $expectedCliVersion) {
    Write-Error "[FAIL-FAST] Versão do Serverpod CLI ($cliVersion) diverge do pin exato ($expectedCliVersion) em solution/server/pubspec.yaml (INV-SEC-11). Atualize com: dart pub global activate serverpod_cli $expectedCliVersion"
    exit 1
}

Write-Host "  [OK] Serverpod CLI: $($serverpod.Display) ($cliVersion)"

$dockerCmd = Get-Command "docker" -ErrorAction SilentlyContinue
if ($dockerCmd) {
    Write-Host "  [OK] Docker: $($dockerCmd.Source)"
} else {
    Write-Host "  [INFO] Docker não detectado no host atual (necessário para containerização F0.5)."
}

if ($PreflightOnly) {
    Write-Host "==> [Preflight] Toolchain validada com sucesso!"
    exit 0
}

# 4. Execução do Build
Write-Host "`n==> [DevTasks] Executando resolução de dependências no workspace raiz..."
& flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Error "[BUILD-FAIL] 'flutter pub get' falhou no workspace raiz."
    exit $LASTEXITCODE
}

Write-Host "==> [DevTasks] Analisando membros do workspace..."
& flutter analyze solution/app solution/server solution/client
if ($LASTEXITCODE -ne 0) {
    Write-Error "[BUILD-FAIL] 'flutter analyze' falhou nos membros do workspace."
    exit $LASTEXITCODE
}




# 5. Geração do client Serverpod (TASK-02): o contrato gerado é entregue como
# código versionado; gerar é passo obrigatório do build, não opcional.
$clientEntry = Join-Path $RepoRoot "solution/client/lib/devtasks_client.dart"
if ($SkipClientGen) {
    if (-not (Test-Path $clientEntry)) {
        Write-Error "[BUILD-FAIL] -SkipClientGen pedido, mas solution/client não está gerado (contrato ausente)."
        exit 1
    }
    Write-Host "`n==> [DevTasks] Geração do client ignorada (-SkipClientGen); contrato existente validado."
} else {
    Write-Host "`n==> [DevTasks] Gerando client Serverpod (serverpod generate)..."
    Push-Location "solution/server"
    try {
        $prefix = $serverpod.Prefix
        & $serverpod.Exe @prefix generate
        $generateExitCode = $LASTEXITCODE
    } finally {
        Pop-Location
    }

    if ($generateExitCode -ne 0) {
        Write-Error "[BUILD-FAIL] Falha em 'serverpod generate' (exit $generateExitCode)."
        exit $generateExitCode
    }

    if (-not (Test-Path $clientEntry)) {
        Write-Error "[BUILD-FAIL] Client gerado ausente: solution/client/lib/devtasks_client.dart"
        exit 1
    }
    Write-Host "  [OK] Client gerado: solution/client (membro do workspace)"
}

# 6. Artefato de build (F0.2 / NC-10): compila o server e ASSERE o artefato esperado.
if (-not $SkipCompile) {
    Write-Host "`n==> [DevTasks] Compilando artefato do server (dart compile exe)..."
    $buildDir = Join-Path $RepoRoot "solution/builds"
    New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
    $artifact = Join-Path $buildDir "devtasks-server.exe"
    if (Test-Path $artifact) { Remove-Item $artifact -Force }

    Push-Location "solution/server"
    try {
        & dart compile exe lib/main.dart -o $artifact
        if ($LASTEXITCODE -ne 0) {
            Write-Error "[BUILD-FAIL] 'dart compile exe' falhou para o server."
            exit $LASTEXITCODE
        }
    } finally {
        Pop-Location
    }

    if (-not (Test-Path $artifact)) {
        Write-Error "[BUILD-FAIL] Artefato esperado ausente: solution/builds/devtasks-server.exe"
        exit 1
    }
    $artifactSize = (Get-Item $artifact).Length
    if ($artifactSize -le 0) {
        Write-Error "[BUILD-FAIL] Artefato gerado esta vazio: solution/builds/devtasks-server.exe"
        exit 1
    }
    Write-Host "  [OK] Artefato: solution/builds/devtasks-server.exe ($([Math]::Round($artifactSize / 1MB, 2)) MB)"
}

Write-Host "`n==> [DevTasks] Build concluído com sucesso!"
exit 0
