# tools/bin/claims.ps1
# Gerenciamento de claims atômicos de Caso de Uso (F0.4 / UC-00.04 / NC-05 / D-04)
[CmdletBinding()]
param(
    [Parameter(Position=0, Mandatory=$true)]
    [ValidateSet("claim", "release", "check", "list", "heartbeat", "reap")]
    [string]$Action,

    [Parameter(Mandatory=$false)]
    [string]$Slice,

    [Parameter(Mandatory=$false)]
    [string]$Owner = "developer",

    [Parameter(Mandatory=$false)]
    [int]$Ttl = 90,

    [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
    [string[]]$Paths = @(),

    [Parameter(Mandatory=$false)]
    [switch]$DryRun,

    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "../..")

$ClaimsDir = if ($env:CLAIMS_DIR -and $env:CLAIMS_DIR.Trim() -ne "") {
    if ([System.IO.Path]::IsPathRooted($env:CLAIMS_DIR)) {
        $env:CLAIMS_DIR
    } else {
        Join-Path $RepoRoot $env:CLAIMS_DIR
    }
} else {
    Join-Path $RepoRoot ".git/claims"
}

if (-not (Test-Path $ClaimsDir)) {
    New-Item -ItemType Directory -Path $ClaimsDir -Force | Out-Null
}

function Emit-Error([string]$msg, [int]$exitCode = 1) {
    [Console]::Error.WriteLine($msg)
    exit $exitCode
}

function Validate-Slice([string]$s) {
    if ($s -notmatch "^UC-\d{2}\.\d{2}$") {
        Emit-Error "[CLAIMS-ERROR] Slice inválido '$s'. Padrão exigido: UC-XX.YY (ex: UC-00.04)" 1
    }
}

function Find-ClaimFile([string]$s) {
    $direct = Join-Path $ClaimsDir "$s.json"
    if (Test-Path $direct) {
        return $direct
    }
    $files = Get-ChildItem -Path $ClaimsDir -Filter "*.json" -ErrorAction SilentlyContinue
    foreach ($f in $files) {
        try {
            $rawText = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
            $content = $rawText | ConvertFrom-Json
            if ($content.slice -eq $s) {
                return $f.FullName
            }
        } catch {}
    }
    return $null
}

function Parse-DateTime([string]$str) {
    if ([string]::IsNullOrWhiteSpace($str)) { return $null }
    try {
        return [DateTimeOffset]::Parse($str, [System.Globalization.CultureInfo]::InvariantCulture).UtcDateTime
    } catch {
        try {
            return [DateTime]::Parse($str, [System.Globalization.CultureInfo]::InvariantCulture)
        } catch {
            return $null
        }
    }
}

function Parse-Claim([string]$filePath) {
    if (-not (Test-Path $filePath)) {
        return $null
    }
    try {
        $rawText = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
        $data = $rawText | ConvertFrom-Json
        $now = [DateTime]::UtcNow
        $expires = $null

        if ($data.expires_at) {
            $expires = Parse-DateTime $data.expires_at
        } elseif ($data.heartbeatUtc -and $data.ttlMinutes) {
            $hb = Parse-DateTime $data.heartbeatUtc
            if ($hb) { $expires = $hb.AddMinutes($data.ttlMinutes) }
        } elseif ($data.startedUtc -and $data.ttlMinutes) {
            $st = Parse-DateTime $data.startedUtc
            if ($st) { $expires = $st.AddMinutes($data.ttlMinutes) }
        }

        $isActive = ($expires -ne $null) -and ($now -lt $expires)
        if ($data.status -and $data.status -ne "active") {
            $isActive = $false
        }

        $claimPaths = @()
        if ($data.paths) {
            $claimPaths = @($data.paths)
        }

        return [PSCustomObject]@{
            FilePath = $filePath
            Slice = [string]$data.slice
            Owner = [string]$data.owner
            Expires = $expires
            IsActive = [bool]$isActive
            Paths = $claimPaths
            Raw = $data
        }
    } catch {
        return $null
    }
}

switch ($Action) {
    "claim" {
        if (-not $Slice) {
            Emit-Error "[CLAIMS-ERROR] Parâmetro -Slice é obrigatório para claim." 1
        }
        Validate-Slice $Slice
        $claimFile = Join-Path $ClaimsDir "$Slice.json"
        $now = [DateTime]::UtcNow
        $expires = $now.AddMinutes($Ttl)

        $normalizedPaths = @()
        if ($Paths -and $Paths.Count -gt 0) {
            foreach ($p in $Paths) {
                if ($p -match ",") {
                    $normalizedPaths += ($p -split ",") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
                } else {
                    $trimmed = $p.Trim()
                    if ($trimmed -ne "") {
                        $normalizedPaths += $trimmed
                    }
                }
            }
        }

        $claimData = @{
            schema = "claims/v1"
            slice = $Slice
            owner = $Owner
            pid = $PID
            claimed_at = $now.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            startedUtc = $now.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            heartbeatUtc = $now.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            expires_at = $expires.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            ttl_minutes = $Ttl
            ttlMinutes = $Ttl
            paths = $normalizedPaths
            status = "active"
        }
        $json = $claimData | ConvertTo-Json -Depth 3

        # 1. Checa se já existe claim ativo no diretório
        $existingPath = Find-ClaimFile $Slice
        if ($existingPath) {
            $existing = Parse-Claim $existingPath
            if ($existing -and $existing.IsActive) {
                if ($existing.Owner -eq $Owner) {
                    # Renovação pelo mesmo dono (heartbeat com eventual atualização de paths)
                    if ($normalizedPaths.Count -eq 0 -and $existing.Paths.Count -gt 0) {
                        $claimData.paths = $existing.Paths
                        $json = $claimData | ConvertTo-Json -Depth 3
                    }
                    [System.IO.File]::WriteAllText($existingPath, $json, [System.Text.Encoding]::UTF8)
                    Write-Host "==> [Claims] Claim renovado pelo dono ($Owner): $Slice (expira em: $($expires.ToString('HH:mm:ss')) UTC)"
                    exit 0
                } else {
                    # Conflito ativo com outro agente/dono: EXIT CODE 2 OBRIGATÓRIO
                    Emit-Error "[CLAIMS-CONFLICT] Conflito de claim! O slice '$Slice' já pertence ativamente a '$($existing.Owner)' até $($existing.Expires.ToString('HH:mm:ss')) UTC." 2
                }
            }
        }

        # 2. Criação atômica via FileMode::CreateNew (O_CREATE | O_EXCL)
        try {
            $stream = [System.IO.File]::Open(
                $claimFile,
                [System.IO.FileMode]::CreateNew,
                [System.IO.FileAccess]::Write,
                [System.IO.FileShare]::None
            )
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Flush()
            $stream.Close()
            $stream.Dispose()
            Write-Host "==> [Claims] Claim ativo criado (atômico): $Slice (owner: $Owner, expira em: $($expires.ToString('HH:mm:ss')) UTC)"
            exit 0
        } catch [System.IO.IOException] {
            $existing = Parse-Claim $claimFile
            if ($existing -and $existing.IsActive -and $existing.Owner -ne $Owner) {
                Emit-Error "[CLAIMS-CONFLICT] Conflito de corrida atômica! Slice '$Slice' capturado por '$($existing.Owner)'." 2
            }
            [System.IO.File]::WriteAllText($claimFile, $json, [System.Text.Encoding]::UTF8)
            Write-Host "==> [Claims] Claim reassumido após expiração: $Slice (owner: $Owner)"
            exit 0
        }
    }

    "release" {
        if (-not $Slice) {
            Emit-Error "[CLAIMS-ERROR] Parâmetro -Slice é obrigatório para release." 1
        }
        Validate-Slice $Slice
        $foundPath = Find-ClaimFile $Slice
        if ($foundPath -and (Test-Path $foundPath)) {
            Remove-Item $foundPath -Force -ErrorAction SilentlyContinue
            Write-Host "==> [Claims] Claim liberado: $Slice"
        } else {
            Write-Host "==> [Claims] Nenhum claim ativo para $Slice"
        }
        exit 0
    }

    "check" {
        if (-not $Slice) {
            Emit-Error "[CLAIMS-ERROR] Parâmetro -Slice é obrigatório para check." 1
        }
        Validate-Slice $Slice
        $foundPath = Find-ClaimFile $Slice
        if (-not $foundPath) {
            Write-Host "==> [Claims] Check: Inativo (arquivo inexistente para $Slice)"
            exit 1
        }

        $parsed = Parse-Claim $foundPath
        if ($parsed -and $parsed.IsActive) {
            Write-Host "==> [Claims] Check: ATIVO para $Slice (owner: $($parsed.Owner))"
            exit 0
        } else {
            Write-Host "==> [Claims] Check: EXPIRADO para $Slice"
            exit 1
        }
    }

    "heartbeat" {
        if (-not $Slice) {
            Emit-Error "[CLAIMS-ERROR] Parâmetro -Slice é obrigatório para heartbeat." 1
        }
        Validate-Slice $Slice
        $foundPath = Find-ClaimFile $Slice
        if (-not $foundPath) {
            Emit-Error "[CLAIMS-ERROR] Claim inexistente para renovação: $Slice" 1
        }

        $existing = Parse-Claim $foundPath
        if (-not $existing -or -not $existing.IsActive) {
            Emit-Error "[CLAIMS-ERROR] Claim expirado para $Slice. Use 'claim' para reabrir." 1
        }
        if ($existing.Owner -ne $Owner) {
            Emit-Error "[CLAIMS-CONFLICT] Impossível renovar: pertence a '$($existing.Owner)'." 2
        }

        $now = [DateTime]::UtcNow
        $expires = $now.AddMinutes($Ttl)
        $existing.Raw.heartbeatUtc = $now.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $existing.Raw.expires_at = $expires.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $json = $existing.Raw | ConvertTo-Json -Depth 3
        [System.IO.File]::WriteAllText($foundPath, $json, [System.Text.Encoding]::UTF8)
        Write-Host "==> [Claims] Heartbeat OK: $Slice renovado até $($expires.ToString('HH:mm:ss')) UTC"
        exit 0
    }

    "list" {
        Write-Host "==> [Claims] Listando claims ativos..."
        $files = Get-ChildItem -Path $ClaimsDir -Filter "*.json" -ErrorAction SilentlyContinue
        $activeCount = 0

        foreach ($f in $files) {
            $parsed = Parse-Claim $f.FullName
            if ($parsed -and $parsed.IsActive) {
                $activeCount++
                $pathsStr = if ($parsed.Paths.Count -gt 0) { " | Paths: $($parsed.Paths -join ', ')" } else { "" }
                Write-Host "  - $($parsed.Slice) | Owner: $($parsed.Owner)$pathsStr | Expira em: $($parsed.Expires.ToString('HH:mm:ss')) UTC"
            }
        }
        if ($activeCount -eq 0) {
            Write-Host "  (nenhum claim ativo no momento)"
        }
        exit 0
    }

    "reap" {
        $files = Get-ChildItem -Path $ClaimsDir -Filter "*.json" -ErrorAction SilentlyContinue
        $reapedCount = 0
        $activeCount = 0
        $orphanedFiles = @()

        foreach ($f in $files) {
            $parsed = Parse-Claim $f.FullName
            if ($null -eq $parsed) {
                $orphanedFiles += @{ File = $f; Slice = $f.BaseName; Reason = "corrompido/inválido" }
            } elseif (-not $parsed.IsActive) {
                $orphanedFiles += @{ File = $f; Slice = $parsed.Slice; Reason = "expirado em $($parsed.Expires.ToString('HH:mm:ss')) UTC" }
            } else {
                $activeCount++
            }
        }

        if ($DryRun -or (-not $Force)) {
            if ($orphanedFiles.Count -eq 0) {
                Write-Host "==> [Claims reap] Nenhum claim órfão ou expirado para limpar."
            } else {
                Write-Host "==> [Claims reap (DryRun)] $($orphanedFiles.Count) claim(s) expirado(s)/órfão(s) encontrado(s):"
                foreach ($item in $orphanedFiles) {
                    Write-Host "  - $($item.Slice) ($($item.Reason)) -> $($item.File.FullName)"
                }
                Write-Host "Execute com -Force para remover os arquivos."
            }
            exit 0
        }

        # Com -Force: remove apenas os órfãos/expirados
        foreach ($item in $orphanedFiles) {
            Remove-Item -Path $item.File.FullName -Force -ErrorAction SilentlyContinue
            Write-Host "==> [Claims reap] Removido claim expirado: $($item.Slice)"
            $reapedCount++
        }

        Write-Host "==> [Claims reap] Concluído: $reapedCount claim(s) removido(s), $activeCount ativo(s) preservado(s)."
        exit 0
    }
}
