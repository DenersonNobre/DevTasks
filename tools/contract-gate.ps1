# tools/contract-gate.ps1
# Gate de Contrato OpenAPI 3.1 (D-08 / UC-08.06 / F8.6)
# Garante paridade bidirecional estrita entre o contrato e o código da API Shelf.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$SimulateFailure,

    [Parameter(Mandatory=$false)]
    [switch]$SkipTestRunner
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
Set-Location $RepoRoot

Write-Host "==> [Contract Gate] Validando contrato OpenAPI 3.1 e paridade com o servidor Shelf..."

if ($SimulateFailure) {
    [Console]::Error.WriteLine("[CONTRACT-GATE-FAIL] Falha simulada para prova negativa do gate de contrato.")
    exit 1
}

$contractPath = Join-Path $RepoRoot "docs/api/openapi.yaml"
if (-not (Test-Path $contractPath)) {
    [Console]::Error.WriteLine("[CONTRACT-GATE-FAIL] Arquivo de contrato não encontrado: $contractPath")
    exit 1
}

# 1. Extrai rotas documentadas em openapi.yaml
$rawContract = Get-Content -Raw -Encoding utf8 $contractPath
$contractRoutes = [System.Collections.Generic.HashSet[string]]::new()

$currentPath = $null
$lines = $rawContract -split "`r?`n"
$inPaths = $false

foreach ($line in $lines) {
    if ($line -match '^paths:') {
        $inPaths = $true
        continue
    }
    if ($inPaths -and $line -match '^[a-zA-Z]') {
        $inPaths = $false
        break
    }
    if ($inPaths) {
        if ($line -match '^\s{2}(/[^:]+):') {
            $currentPath = $matches[1]
        }
        elseif ($currentPath -and $line -match '^\s{4}(get|post|patch|put|delete):') {
            $method = $matches[1].ToUpper()
            $contractRoutes.Add("$method $currentPath") | Out-Null
        }
    }
}

Write-Host "  * Rotas encontradas no contrato OpenAPI: $($contractRoutes.Count)"

# 2. Extrai rotas declaradas no código da API (Shelf Router)
$routeFiles = @(
    "solution/api/lib/core/http/router.dart",
    "solution/api/lib/modules/auth/auth_routes.dart",
    "solution/api/lib/modules/workspace/workspace_routes.dart",
    "solution/api/lib/modules/projects/project_routes.dart"
)

$codeRoutes = [System.Collections.Generic.HashSet[string]]::new()
$routeRegex = [regex]"router\.(get|post|patch|put|delete)\(\s*'([^']+)'"

foreach ($rf in $routeFiles) {
    $fullPath = Join-Path $RepoRoot $rf
    if (-not (Test-Path $fullPath)) {
        [Console]::Error.WriteLine("[CONTRACT-GATE-FAIL] Arquivo de rota não encontrado: $rf")
        exit 1
    }
    $content = Get-Content -Raw -Encoding utf8 $fullPath
    $matches = $routeRegex.Matches($content)
    foreach ($m in $matches) {
        $method = $m.Groups[1].Value.ToUpper()
        $path = $m.Groups[2].Value
        # Transforma <param> do shelf em {param} do OpenAPI
        $normalizedPath = [regex]::Replace($path, '<([^>]+)>', '{$1}')
        $codeRoutes.Add("$method $normalizedPath") | Out-Null
    }
}

Write-Host "  * Rotas encontradas no código da API Shelf: $($codeRoutes.Count)"

# 3. Validação de paridade bidirecional
$missingInContract = @($codeRoutes | Where-Object { -not $contractRoutes.Contains($_) })
$missingInCode = @($contractRoutes | Where-Object { -not $codeRoutes.Contains($_) })

$hasDiscrepancy = $false

if ($missingInContract.Count -gt 0) {
    [Console]::Error.WriteLine("[CONTRACT-GATE-FAIL] Rotas presentes no código mas ausentes no OpenAPI:")
    foreach ($r in $missingInContract) {
        [Console]::Error.WriteLine("  - $r")
    }
    $hasDiscrepancy = $true
}

if ($missingInCode.Count -gt 0) {
    [Console]::Error.WriteLine("[CONTRACT-GATE-FAIL] Rotas presentes no OpenAPI mas não implementadas no código:")
    foreach ($r in $missingInCode) {
        [Console]::Error.WriteLine("  - $r")
    }
    $hasDiscrepancy = $true
}

if ($hasDiscrepancy) {
    exit 1
}

Write-Host "  [OK] Paridade bidirecional 1:1 verificada ($($codeRoutes.Count) rotas em perfeita sincronia)."

# 4. Executa os testes de contrato em Dart
if (-not $SkipTestRunner) {
    Write-Host "  * Executando suíte de testes de contrato (Dart)..."
    Push-Location (Join-Path $RepoRoot "solution/api")
    try {
        $testOutput = & dart test test/contract/openapi_contract_test.dart 2>&1
        $code = $LASTEXITCODE
        if ($code -ne 0) {
            [Console]::Error.WriteLine("[CONTRACT-GATE-FAIL] Falha na suíte de testes de contrato:`n$testOutput")
            exit 1
        }
        Write-Host "  [OK] Testes de contrato passaram com sucesso."
    } finally {
        Pop-Location
    }
}

Write-Host "==> [Contract Gate] Contrato OpenAPI 3.1 APROVADO com sucesso!"
exit 0

