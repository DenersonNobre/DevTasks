# tools/test.ps1
# Runner de testes headless e não-bloqueante em 1 comando (F0.3 / UC-00.03 / NC-08)
[CmdletBinding()]
param(
    [switch]$Coverage,
    [ValidateSet("all", "app", "server", "governance")]
    [string]$Target = "all",
    [switch]$Governance,
    [switch]$FailFast,
    [switch]$SimulateFailure,
    [bool]$NoPub = $true
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
Set-Location $RepoRoot

# Suprime telemetria e avisos de rede durante execuções automáticas
$env:FLUTTER_SUPPRESS_ANALYTICS = "true"
$env:CI = "true"

Write-Host "==> [DevTasks] Disparando Runner de Testes (Headless)..."
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

if ($SimulateFailure) {
    Write-Error "[TEST-FAIL] Falha simulada em teste de domínio para verificação de fail propagation."
    exit 1
}

$targets = @()
if ($Target -eq "all" -or $Target -eq "app") {
    $targets += @{ Name = "app"; Path = "solution/app" }
}
if ($Target -eq "all" -or $Target -eq "server") {
    $targets += @{ Name = "server"; Path = "solution/server" }
}

$hasFailure = $false
$failedMembers = @()

foreach ($t in $targets) {
    Write-Host "`n--> Executando testes de: $($t.Name) ($($t.Path))..."
    $argsList = @("test")
    if ($NoPub -and (Test-Path "$RepoRoot/pubspec.lock")) {
        $argsList += "--no-pub"
    }

    Push-Location $t.Path
    try {
        if ($t.Name -eq "server") {
            if ($Coverage) {
                & dart test --coverage=coverage
            } else {
                & dart test
            }
        } else {
            if ($Coverage) {
                & flutter test @argsList --coverage
            } else {
                & flutter test @argsList
            }
        }
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            $hasFailure = $true
            $failedMembers += $t.Name
            Write-Error "[FAIL] Testes de $($t.Name) falharam com exit code $exitCode."
            if ($FailFast) {
                break
            }
        } else {
            Write-Host "  [OK] Todos os testes de $($t.Name) passaram."
            if ($Coverage) {
                $lcovPath = Join-Path (Get-Location) "coverage/lcov.info"
                if (Test-Path $lcovPath) {
                    Write-Host "  [Coverage] Relatório gerado em $($t.Path)/coverage/lcov.info"
                }
            }
        }
    } finally {
        Pop-Location
    }
}

# Suíte de Governança e Infraestrutura (NC-08)
if ($Governance -or $Target -eq "governance") {
    Write-Host "`n--> Executando Suíte de Governança, CI, Docker e Claims..."
    $govSuites = @(
        "tools/tests/test_build_scripts.ps1",
        "tools/tests/test_test_runner.ps1",
        "tools/tests/test_git_governance.ps1",
        "tools/tests/test_ci_pipeline.ps1",
        "tools/tests/test_doc_governance.ps1",
        "docker/tests/test_docker_manifests.ps1"
    )

    foreach ($suite in $govSuites) {
        $fullPath = Join-Path $RepoRoot $suite
        if (Test-Path $fullPath) {
            Write-Host "  * Rodando: $suite..."
            $output = & pwsh -NoProfile -NonInteractive -File $fullPath 2>&1
            $code = $LASTEXITCODE
            if ($code -ne 0) {
                $hasFailure = $true
                $failedMembers += $suite
                Write-Error "[GOVERNANCE-FAIL] Falha em $suite (exit code $code):`n$output"
                if ($FailFast) { break }
            } else {
                Write-Host "    [OK] $suite passou."
            }
        }
    }
}

$elapsed = $stopwatch.Elapsed.TotalSeconds
Write-Host ("`n==> [DevTasks] Execução concluída em {0:N2}s" -f $elapsed)

if ($elapsed -gt 60) {
    Write-Warning "[NFR-03] Tempo total ($($elapsed)s) excedeu o teto estipulado de 60s!"
}

if ($hasFailure) {
    Write-Error "[TEST-SUITE-FAIL] Falha em membros/suítes: $($failedMembers -join ', ')."
    exit 1
}

Write-Host "==> [DevTasks] Suíte completa de testes VERDE!"
exit 0
