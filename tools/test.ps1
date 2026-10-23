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

$coreElapsed = $stopwatch.Elapsed.TotalSeconds

# Gate de cobertura (NFR-04 / NC-14): global >= 70% e dominio (kernel) >= 90%.
if ($Coverage) {
    function Get-LcovPercent {
        param([string]$LcovPath, [string]$FileFilter)
        if (-not (Test-Path $LcovPath)) { return $null }
        $raw = Get-Content $LcovPath -Raw
        if (-not $raw) { return $null }
        $lf = 0; $lh = 0
        foreach ($block in ($raw -split "end_of_record")) {
            if ($FileFilter -and ($block -notmatch $FileFilter)) { continue }
            if ($block -match "LF:(\d+)") { $lf += [int]$Matches[1] }
            if ($block -match "LH:(\d+)") { $lh += [int]$Matches[1] }
        }
        if ($lf -eq 0) { return $null }
        return [Math]::Round(100 * $lh / $lf, 2)
    }

    $appLcov = Join-Path $RepoRoot "solution/app/coverage/lcov.info"
    $globalPct = Get-LcovPercent -LcovPath $appLcov
    $domainPct = Get-LcovPercent -LcovPath $appLcov -FileFilter "kernel"

    if ($null -eq $globalPct) {
        Write-Warning "[NFR-04] lcov do app ausente ou vazio - cobertura nao verificada."
    } else {
        Write-Host "  [Coverage] app global = $globalPct% (minimo 70%)"
        if ($globalPct -lt 70) {
            $hasFailure = $true
            Write-Error "[NFR-04] Cobertura global ($globalPct%) abaixo do minimo de 70%."
        }
    }

    if ($null -ne $domainPct) {
        Write-Host "  [Coverage] dominio/kernel = $domainPct% (minimo 90%)"
        if ($domainPct -lt 90) {
            $hasFailure = $true
            Write-Error "[NFR-04] Cobertura de dominio ($domainPct%) abaixo do minimo de 90%."
        }
    }

    $serverLcov = Join-Path $RepoRoot "solution/server/coverage/lcov.info"
    if (-not (Test-Path $serverLcov) -or (Get-Item $serverLcov).Length -eq 0) {
        Write-Warning "[NFR-04] server sem lcov (dart test emite JSON, nao lcov) - cobertura do server nao verificada."
    }
}

# Suíte de Governança e Infraestrutura (NC-08)
if ($Governance -or $Target -eq "governance") {
    Write-Host "`n--> Executando Suíte de Governança, CI, Docker e Claims..."
    $govSuites = @(
        "tools/tests/test_build_scripts.ps1",
        "tools/tests/test_test_runner.ps1",
        "tools/tests/test_git_governance.ps1",
        "tools/tests/test_precommit_encoding.ps1",
        "tools/tests/test_dip_gate.ps1",
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
$govElapsed = [Math]::Round($elapsed - $coreElapsed, 2)
Write-Host ("`n==> [DevTasks] Core (app+server) em {0:N2}s | Governanca em {1:N2}s | Total {2:N2}s" -f $coreElapsed, $govElapsed, $elapsed)

# NFR-03: o teto de 60s vale para a suite CORE; a suite de governanca (opt-in) tem teto proprio.
if ($coreElapsed -gt 60) {
    $hasFailure = $true
    Write-Error "[NFR-03] Suite core (app+server) levou $([Math]::Round($coreElapsed,2))s - teto de 60s excedido."
}
if (($Governance -or $Target -eq "governance") -and $govElapsed -gt 600) {
    $hasFailure = $true
    Write-Error "[NFR-03] Suite de governanca levou ${govElapsed}s - teto de 600s excedido."
}

if ($hasFailure) {
    Write-Error "[TEST-SUITE-FAIL] Falha em membros/suítes: $($failedMembers -join ', ')."
    exit 1
}

Write-Host "==> [DevTasks] Suíte completa de testes VERDE!"
exit 0
