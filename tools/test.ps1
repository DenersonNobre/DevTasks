# tools/test.ps1
# Runner de testes headless e não-bloqueante em 1 comando (F0.3 / UC-00.03 / NC-08)
[CmdletBinding()]
param(
    [switch]$Coverage,
    [ValidateSet("all", "app", "api", "governance")]
    [string]$Target = "all",
    [switch]$Unit,
    [switch]$Integration,
    [switch]$Governance,
    [switch]$FailFast,
    [switch]$SimulateFailure,
    [switch]$NoPub
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
Set-Location $RepoRoot

# Suprime telemetria e avisos de rede durante execuções automáticas
$env:FLUTTER_SUPPRESS_ANALYTICS = "true"
$env:CI = "true"

Write-Host "==> [DevTasks] Disparando Runner de Testes (Headless)..."

if ($SimulateFailure) {
    Write-Error "[TEST-FAIL] Falha simulada em teste de domínio para verificação de fail propagation."
    exit 1
}

# 1. Fora da janela de medição (NFR-03): aquecer dependências e package_config antes de cronometrar
if (-not $NoPub) {
    if (-not (Test-Path (Join-Path $RepoRoot ".dart_tool/package_config.json"))) {
        Write-Host "--> Aquecendo package_config do workspace fora da janela do cronômetro..."
        Push-Location (Join-Path $RepoRoot "solution/api")
        try {
            & dart pub get --quiet
        } finally {
            Pop-Location
        }
    }
}

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$memberTimes = [ordered]@{}

$targets = @()
if ($Target -eq "all" -or $Target -eq "app") {
    $targets += @{ Name = "app"; Path = "solution/app" }
}
if ($Target -eq "all" -or $Target -eq "api") {
    $targets += @{ Name = "api"; Path = "solution/api" }
}

$hasFailure = $false
$failedMembers = @()

foreach ($t in $targets) {
    Write-Host "`n--> Executando testes de: $($t.Name) ($($t.Path))..."
    $memberWatch = [System.Diagnostics.Stopwatch]::StartNew()
    $useNoPub = $NoPub -or $Unit -or (Test-Path "$RepoRoot/pubspec.lock")

    Push-Location $t.Path
    try {
        if ($t.Name -eq "api") {
            $apiArgs = @("test")
            if ($Unit) {
                $apiArgs += "test/unit"
            } elseif ($Integration) {
                $apiArgs += @(
                    "test/contract",
                    "test/unit/http"
                )
            }

            if ($Coverage) {
                & dart @apiArgs --coverage=coverage
                if ($LASTEXITCODE -eq 0) {
                    $pkgConfig = Join-Path $RepoRoot ".dart_tool/package_config.json"
                    & dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=$pkgConfig --report-on=lib | Out-Null
                }
            } else {
                & dart @apiArgs
            }
        } else {
            # app
            $appArgs = @("test")
            if ($Unit) {
                $appArgs += "test/unit"
            } elseif ($Integration) {
                $appArgs += "test/widget"
            }
            if ($useNoPub) {
                $appArgs += "--no-pub"
            }

            if ($Coverage) {
                & flutter @appArgs --coverage
            } else {
                & flutter @appArgs
            }
        }
        $exitCode = $LASTEXITCODE
        $memberElapsed = [Math]::Round($memberWatch.Elapsed.TotalSeconds, 2)
        $memberTimes[$t.Name] = $memberElapsed

        if ($exitCode -ne 0) {
            $hasFailure = $true
            $failedMembers += $t.Name
            Write-Error "[FAIL] Testes de $($t.Name) falharam com exit code $exitCode ($($memberElapsed)s)."
            if ($FailFast) {
                break
            }
        } else {
            Write-Host "  [OK] Todos os testes de $($t.Name) passaram em $($memberElapsed)s."
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
        param([string]$LcovPath, [string]$FileFilter, [string]$ExcludeFilter)
        if (-not (Test-Path $LcovPath)) { return $null }
        $raw = Get-Content $LcovPath -Raw
        if (-not $raw) { return $null }
        $lf = 0; $lh = 0
        foreach ($block in ($raw -split "end_of_record")) {
            if ($FileFilter -and ($block -notmatch $FileFilter)) { continue }
            if ($ExcludeFilter -and ($block -match $ExcludeFilter)) { continue }
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
        if ($Target -ne "api") {
            Write-Warning "[NFR-04] lcov do app ausente ou vazio - cobertura nao verificada."
        }
    } else {
        Write-Host "  [Coverage] app global = $globalPct% (minimo 70%)"
        if ($globalPct -lt 70) {
            $hasFailure = $true
            Write-Error "[NFR-04] Cobertura global do app ($globalPct%) abaixo do minimo de 70%."
        }
    }

    if ($null -ne $domainPct) {
        Write-Host "  [Coverage] dominio/kernel = $domainPct% (minimo 90%)"
        if ($domainPct -lt 90) {
            $hasFailure = $true
            Write-Error "[NFR-04] Cobertura de dominio ($domainPct%) abaixo do minimo de 90%."
        }
    }

    $apiLcov = Join-Path $RepoRoot "solution/api/coverage/lcov.info"
    $apiPct = Get-LcovPercent -LcovPath $apiLcov
    if ($null -eq $apiPct) {
        if ($Target -ne "app") {
            Write-Warning "[NFR-04] lcov da api ausente ou vazio - cobertura da api nao verificada."
        }
    } else {
        Write-Host "  [Coverage] api global = $apiPct% (minimo 70%)"
        if ($apiPct -lt 70) {
            $hasFailure = $true
            Write-Error "[NFR-04] Cobertura da api ($apiPct%) abaixo do minimo de 70%."
        }
    }
}

# Suíte de Governança e Infraestrutura (NC-08)
if ($Governance -or $Target -eq "governance") {
    Write-Host "`n--> Executando Suíte de Governança, CI, Docker e Claims..."
    $previousNested = $env:DEVTASKS_NESTED_RUN
    $env:DEVTASKS_NESTED_RUN = "1"
    $govSuites = @(
        "tools/tests/test_test_runner.ps1",
        "tools/tests/test_git_governance.ps1",
        "tools/tests/test_precommit_encoding.ps1",
        "tools/tests/test_dip_gate.ps1",
        "tools/tests/test_pin_gate.ps1",
        "tools/tests/test_ci_pipeline.ps1",
        "tools/tests/test_doc_governance.ps1",
        "docker/tests/test_docker_manifests.ps1",
        "tools/tests/test_build_scripts.ps1"
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
    $env:DEVTASKS_NESTED_RUN = $previousNested
}

$elapsed = $stopwatch.Elapsed.TotalSeconds
$govElapsed = [Math]::Round($elapsed - $coreElapsed, 2)
$memberSummary = ($memberTimes.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)s" }) -join " "
Write-Host ("`n==> [DevTasks] Core: {0:N2}s ({1}) | Governanca: {2:N2}s | Total: {3:N2}s" -f $coreElapsed, $memberSummary, $govElapsed, $elapsed)

$coreBudget = if ($Unit) {
    if ($Coverage) { 180 } else { 120 }
} elseif ($Integration) {
    if ($Coverage) { 240 } else { 180 }
} else {
    if ($Coverage) { 240 } else { 180 }
}

if ($env:DEVTASKS_NESTED_RUN -eq "1") {
    Write-Host "  [NFR-03] Run aninhado: orçamento medido apenas no run externo."
} elseif ($coreElapsed -gt $coreBudget) {
    $hasFailure = $true
    $modeDesc = if ($Unit) { "unitária (NFR-03)" } elseif ($Integration) { "integração" } else { "core completa" }
    Write-Error "[NFR-03] Suite $modeDesc (app+api) levou $([Math]::Round($coreElapsed,2))s - teto de ${coreBudget}s excedido."
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
