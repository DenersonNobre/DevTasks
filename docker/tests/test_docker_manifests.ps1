# Test suite for Docker Containerization & Parity Manifests
# Implements Gherkin acceptance criteria for UC-00.05 (US-0.5.1)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "../..")
Set-Location $RepoRoot

$Dockerfile = Join-Path $RepoRoot "docker/Dockerfile"
$ComposeFile = Join-Path $RepoRoot "docker/docker-compose.yml"
# O Docker procura .dockerignore na RAIZ DO BUILD CONTEXT (compose `context: ..` /
# CI `docker build ... .`), nunca ao lado do Dockerfile — ver NC-07 do qa-review-v0.1.0.
$Dockerignore = Join-Path $RepoRoot ".dockerignore"
$StaleDockerignore = Join-Path $RepoRoot "docker/.dockerignore"

Write-Host "=== TEST 1: Verificar existência dos manifestos Docker ==="
if (-not (Test-Path $Dockerfile)) {
    throw "RED EXPECTED: docker/Dockerfile does not exist yet."
}
if (-not (Test-Path $ComposeFile)) {
    throw "RED EXPECTED: docker/docker-compose.yml does not exist yet."
}
if (-not (Test-Path $Dockerignore)) {
    throw "RED EXPECTED: .dockerignore (raiz do build context) does not exist yet."
}
if (Test-Path $StaleDockerignore) {
    throw "FAIL: docker/.dockerignore e inerte (context = raiz); manter apenas o .dockerignore da raiz."
}

Write-Host "=== TEST 2: Validação de Anti-Colisão (devops-docker.md) no Compose ==="
$composeContent = Get-Content $ComposeFile -Raw

# 2.1 Projeto name
if ($composeContent -notmatch "(?m)^name:\s*devtasks") {
    throw "FAIL: docker-compose.yml deve declarar 'name: devtasks' no topo."
}

# 2.2 Containers nomeados
if ($composeContent -notmatch "container_name:\s*devtasks[_-](api|server)") {
    throw "FAIL: Container do backend deve seguir convenção anti-colisão (devtasks-api ou devtasks-server)."
}
if ($composeContent -notmatch "container_name:\s*devtasks[_-]postgres") {
    throw "FAIL: Container do postgres deve seguir convenção anti-colisão (devtasks-postgres ou devtasks_postgres)."
}

# 2.3 Rede nomeada
if ($composeContent -notmatch "devtasks_net") {
    throw "FAIL: Rede deve seguir convenção 'devtasks_net'."
}

# 2.4 Volume nomeado
if ($composeContent -notmatch "devtasks_postgres_data") {
    throw "FAIL: Volume deve seguir convenção 'devtasks_postgres_data'."
}
Write-Host "Pass: Convenção de nomenclatura anti-colisão atendida."

Write-Host "=== TEST 3: Validação de Binding LAN (0.0.0.0) ==="
if ($composeContent -match "127\.0\.0\.1:") {
    throw "FAIL: Portas não podem ser amarradas a 127.0.0.1 (restringe teste LAN; deve usar 0.0.0.0)."
}
if ($composeContent -notmatch "0\.0\.0\.0:") {
    throw "FAIL: Portas devem explicitar binding em 0.0.0.0 para acesso de outros dispositivos na LAN."
}
Write-Host "Pass: Binding 0.0.0.0 para LAN verificado."

Write-Host "=== TEST 4: Validação Multi-Stage no Dockerfile ==="
$dockerfileContent = Get-Content $Dockerfile -Raw
if ($dockerfileContent -notmatch "(?i)FROM\s+.*dart.*AS\s+(build|builder)") {
    throw "FAIL: Dockerfile deve conter estágio de build Dart (multi-stage)."
}
if ($dockerfileContent -notmatch "(?i)FROM\s+.*(slim|alpine|distroless|runner|runtime)") {
    throw "FAIL: Dockerfile deve conter estágio final runtime slim."
}
Write-Host "Pass: Dockerfile multi-stage verificado."

Write-Host "=== TEST 5: Validação do .dockerignore ==="
$dockerignoreContent = Get-Content $Dockerignore -Raw
$requiredIgnores = @("\.git", "\.dart_tool", "build", "coverage")
foreach ($req in $requiredIgnores) {
    if ($dockerignoreContent -notmatch $req) {
        throw "FAIL: .dockerignore deve excluir '$req' para evitar sobrecarga de contexto."
    }
}
# 5.1 O filtro só vale para o contexto da raiz — se o contexto mudar, o arquivo acima fica inerte.
if ($composeContent -notmatch "(?m)^[ \t]*context:[ \t]*\.\.[ \t]*\r?$") {
    throw "FAIL: build.context do compose deve ser '..' (raiz do repo) — é a raiz que o Docker filtra."
}
foreach ($wf in @(".gitea/workflows/ci.yml", ".github/workflows/ci.yml")) {
    $wfPath = Join-Path $RepoRoot $wf
    if (-not (Test-Path $wfPath)) { continue }
    if ((Get-Content $wfPath -Raw) -notmatch "(?m)^.*docker build[^\r\n]*[ \t]\.\r?$") {
        throw "FAIL: $wf deve usar a raiz como build context ('docker build ... .')."
    }
}
Write-Host "Pass: .dockerignore cobre artefatos obrigatórios e vive na raiz do contexto."

Write-Host "`n>>> ALL UC-00.05 ACCEPTANCE TESTS PASSED SUCCESSFULLY! <<<"
exit 0
