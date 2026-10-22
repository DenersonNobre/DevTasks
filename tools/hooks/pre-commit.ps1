# tools/hooks/pre-commit.ps1
# Validacao de encoding dos arquivos STAGED (F0.4 / UC-00.04 / NC-13).
#
# Reprova: bytes invalidos em UTF-8, U+FFFD (encoding duplo), contaminacao CJK e
# arquivo truncado (apenas BOM UTF-8 = 3 bytes). Binarios (NUL) sao ignorados.

$ErrorActionPreference = "Stop"

function Get-StagedFiles {
    $raw = & git diff --cached --name-only --diff-filter=ACM 2>$null
    if (-not $raw) { return @() }
    return @($raw | Where-Object { $_ -and (Test-Path $_) })
}

function Test-TextBytes {
    param([byte[]]$Bytes)
    return -not ($Bytes -contains 0)
}

$offenders = @()
foreach ($file in Get-StagedFiles) {
    $bytes = [System.IO.File]::ReadAllBytes($file)
    if ($bytes.Length -eq 0) { continue }
    if (-not (Test-TextBytes -Bytes $bytes)) { continue }

    # Arquivo truncado: apenas BOM UTF-8 (EF BB BF) e nada mais.
    if ($bytes.Length -le 3 -and $bytes.Length -ge 3 -and
        $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $offenders += "$file -> arquivo truncado (apenas BOM UTF-8)"
        continue
    }

    $utf8Strict = [System.Text.UTF8Encoding]::new($false, $true)
    try {
        $text = $utf8Strict.GetString($bytes)
    } catch {
        $offenders += "$file -> bytes invalidos em UTF-8"
        continue
    }

    if ($text.Contains([char]0xFFFD)) {
        $offenders += "$file -> U+FFFD presente (encoding duplo/corrompido)"
    }
    if ($text -match '[\u4e00-\u9fff]') {
        $offenders += "$file -> contaminacao CJK (encoding incorreto)"
    }
}

if ($offenders.Count -gt 0) {
    Write-Host "==> [DevTasks] pre-commit: encoding reprovado nos arquivos staged:" -ForegroundColor Red
    foreach ($o in $offenders) { Write-Host "  - $o" -ForegroundColor Red }
    Write-Host "Corrija o encoding (UTF-8 sem BOM, sem U+FFFD/CJK) antes de commitar." -ForegroundColor Yellow
    exit 1
}

exit 0
