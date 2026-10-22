# tools/bin/claims.ps1
# Gerenciamento de claims de Caso de Uso (F0.4 / UC-00.04)
[CmdletBinding()]
param(
    [Parameter(Position=0, Mandatory=$true)]
    [ValidateSet("claim", "release", "check", "list")]
    [string]$Action,

    [Parameter(Mandatory=$false)]
    [string]$Slice,

    [Parameter(Mandatory=$false)]
    [string]$Owner = "developer",

    [Parameter(Mandatory=$false)]
    [int]$Ttl = 90
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "../..")
$ClaimsDir = Join-Path $RepoRoot ".git/claims"

if (-not (Test-Path $ClaimsDir)) {
    New-Item -ItemType Directory -Path $ClaimsDir -Force | Out-Null
}

function Get-ClaimPath([string]$s) {
    if ($s -notmatch "^UC-\d{2}\.\d{2}$") {
        Write-Error "[CLAIMS-ERROR] Slice inválido '$s'. Padrão exigido: UC-XX.YY (ex: UC-00.04)"
        exit 1
    }
    return Join-Path $ClaimsDir "$s.json"
}

switch ($Action) {
    "claim" {
        if (-not $Slice) {
            Write-Error "[CLAIMS-ERROR] Parâmetro -Slice é obrigatório para claim."
            exit 1
        }
        $claimFile = Get-ClaimPath $Slice
        $now = [DateTime]::UtcNow
        $expires = $now.AddMinutes($Ttl)

        $claimData = @{
            slice = $Slice
            owner = $Owner
            claimed_at = $now.ToString("o")
            expires_at = $expires.ToString("o")
            ttl_minutes = $Ttl
            status = "active"
        }

        $json = $claimData | ConvertTo-Json -Depth 3
        Set-Content -Path $claimFile -Value $json -Force
        Write-Host "==> [Claims] Claim ativo criado: $Slice (owner: $Owner, expira em: $($expires.ToString('HH:mm:ss')) UTC)"
        exit 0
    }

    "release" {
        if (-not $Slice) {
            Write-Error "[CLAIMS-ERROR] Parâmetro -Slice é obrigatório para release."
            exit 1
        }
        $claimFile = Get-ClaimPath $Slice
        if (Test-Path $claimFile) {
            Remove-Item $claimFile -Force -ErrorAction SilentlyContinue
            Write-Host "==> [Claims] Claim liberado: $Slice"
        } else {
            Write-Host "==> [Claims] Nenhum claim ativo para $Slice"
        }
        exit 0
    }

    "check" {
        if (-not $Slice) {
            Write-Error "[CLAIMS-ERROR] Parâmetro -Slice é obrigatório para check."
            exit 1
        }
        $claimFile = Get-ClaimPath $Slice
        if (-not (Test-Path $claimFile)) {
            Write-Host "==> [Claims] Check: Inativo (arquivo inexistente para $Slice)"
            exit 1
        }

        try {
            $claim = Get-Content $claimFile -Raw | ConvertFrom-Json
            $expires = [DateTimeOffset]::Parse($claim.expires_at).UtcDateTime
            $now = [DateTime]::UtcNow

            if ($claim.status -eq "active" -and $now -lt $expires) {
                Write-Host "==> [Claims] Check: ATIVO para $Slice (owner: $($claim.owner))"
                exit 0
            } else {
                Write-Host "==> [Claims] Check: EXPIRADO para $Slice"
                exit 1
            }
        } catch {
            Write-Host "==> [Claims] Check: INVÁLIDO para $Slice"
            exit 1
        }
    }

    "list" {
        Write-Host "==> [Claims] Listando claims ativos..."
        $files = Get-ChildItem -Path $ClaimsDir -Filter "*.json" -ErrorAction SilentlyContinue
        $activeCount = 0
        $now = [DateTime]::UtcNow

        foreach ($f in $files) {
            try {
                $c = Get-Content $f.FullName -Raw | ConvertFrom-Json
                $expires = [DateTimeOffset]::Parse($c.expires_at).UtcDateTime
                if ($c.status -eq "active" -and $now -lt $expires) {
                    $activeCount++
                    Write-Host "  - $($c.slice) | Owner: $($c.owner) | Expira em: $($expires.ToString('HH:mm:ss')) UTC"
                }
            } catch {}
        }
        if ($activeCount -eq 0) {
            Write-Host "  (nenhum claim ativo no momento)"
        }
        exit 0
    }
}
