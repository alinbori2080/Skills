[CmdletBinding()]
param(
    [string]$ConfigPath,
    [string]$LogPath,
    [string]$CodexPath,
    [switch]$Force,
    [switch]$SkipDoctor
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Status {
    param([string]$Name, [string]$Value)
    Write-Output ("{0}={1}" -f $Name, $Value)
}

function Find-CodexCli {
    $bundledRoot = Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\bin'
    $bundled = Get-ChildItem -LiteralPath $bundledRoot -Filter 'codex.exe' -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1 -ExpandProperty FullName
    if ($bundled) { return $bundled }

    $fromPath = Get-Command codex -ErrorAction SilentlyContinue
    if ($fromPath) { return $fromPath.Source }
    return $null
}

function Test-ReconnectEvidence {
    param([string]$Path)

    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { return $false }
    $files = @()
    if ((Get-Item -LiteralPath $Path).PSIsContainer) {
        $files = @(Get-ChildItem -LiteralPath $Path -File -Recurse -ErrorAction SilentlyContinue)
    } else {
        $files = @(Get-Item -LiteralPath $Path)
    }
    if ($files.Count -eq 0) { return $false }

    $signals = @(
        'Reconnecting... 5/5',
        'websocket closed before response.completed',
        'stream disconnected before completion',
        'os error 10054',
        'unexpected EOF'
    )
    return $null -ne ($files | Select-String -SimpleMatch -Pattern $signals -ErrorAction SilentlyContinue | Select-Object -First 1)
}

$codexRoot = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
if (-not $ConfigPath) { $ConfigPath = Join-Path $codexRoot 'config.toml' }
if (-not $LogPath) {
    $today = Get-Date
    $LogPath = Join-Path $env:LOCALAPPDATA ("Codex\Logs\{0}\{1}\{2}" -f $today.ToString('yyyy'), $today.ToString('MM'), $today.ToString('dd'))
}

$hasEvidence = Test-ReconnectEvidence -Path $LogPath
Write-Status 'RECONNECT_EVIDENCE' ([string]$hasEvidence).ToLowerInvariant()
if (-not $hasEvidence -and -not $Force) {
    Write-Status 'RESULT' 'no-change'
    Write-Status 'REASON' 'no-known-reconnect-signal'
    exit 0
}

$originalExists = Test-Path -LiteralPath $ConfigPath
$original = if ($originalExists) { Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 } else { '' }

$providerLines = [regex]::Matches($original, '(?m)^\s*model_provider\s*=.*$')
if ($providerLines.Count -gt 1) {
    throw 'Multiple top-level model_provider entries found; no change was made.'
}

$providerHeader = '(?m)^\s*\[model_providers\.openai-http\]\s*$'
$providerBlock = @'
[model_providers.openai-http]
name = "OpenAI HTTPS"
base_url = "https://chatgpt.com/backend-api/codex"
wire_api = "responses"
requires_openai_auth = true
supports_websockets = false
'@

$hasProviderBlock = [regex]::IsMatch($original, $providerHeader)
if ($hasProviderBlock) {
    $section = [regex]::Match(
        $original,
        '(?ms)^\s*\[model_providers\.openai-http\]\s*$.*?(?=^\s*\[[^\]]+\]\s*$|\z)'
    ).Value
    $required = @(
        '(?m)^\s*base_url\s*=\s*"https://chatgpt\.com/backend-api/codex"\s*$',
        '(?m)^\s*wire_api\s*=\s*"responses"\s*$',
        '(?m)^\s*requires_openai_auth\s*=\s*true\s*$',
        '(?m)^\s*supports_websockets\s*=\s*false\s*$'
    )
    if (@($required | Where-Object { -not [regex]::IsMatch($section, $_) }).Count -gt 0) {
        throw 'An existing openai-http provider differs from the safe preset; no change was made.'
    }
}

$updated = $original
if ($providerLines.Count -eq 1) {
    $updated = [regex]::Replace($updated, '(?m)^\s*model_provider\s*=.*$', 'model_provider = "openai-http"', 1)
} else {
    $updated = "model_provider = `"openai-http`"`r`n" + $updated
}
if (-not $hasProviderBlock) {
    $updated = $updated.TrimEnd() + "`r`n`r`n" + $providerBlock + "`r`n"
}

if ($updated -eq $original) {
    Write-Status 'RESULT' 'already-configured'
    exit 0
}

$configDirectory = Split-Path -Parent $ConfigPath
if (-not (Test-Path -LiteralPath $configDirectory)) {
    New-Item -ItemType Directory -Path $configDirectory | Out-Null
}
$backupPath = $null
if ($originalExists) {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
    $backupPath = "$ConfigPath.codex-connection-doctor-$stamp.bak"
    Copy-Item -LiteralPath $ConfigPath -Destination $backupPath
    Write-Status 'BACKUP' $backupPath
}

try {
    Set-Content -LiteralPath $ConfigPath -Value $updated -Encoding utf8NoBOM

    if (-not $SkipDoctor) {
        $codexCli = if ($CodexPath) { $CodexPath } else { Find-CodexCli }
        if (-not $codexCli) { throw 'Codex CLI not found; cannot verify the repair.' }
        $doctorOutput = & $codexCli doctor --summary --no-color --ascii 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw ("Codex doctor failed: {0}" -f ($doctorOutput -join ' '))
        }
    }

    Write-Status 'RESULT' 'repaired'
    Write-Status 'ACTIVE_PROVIDER' 'openai-http'
}
catch {
    if ($originalExists -and $backupPath) {
        Copy-Item -LiteralPath $backupPath -Destination $ConfigPath -Force
    } elseif (Test-Path -LiteralPath $ConfigPath) {
        Remove-Item -LiteralPath $ConfigPath -Force
    }
    Write-Status 'RESULT' 'rolled-back'
    throw
}
