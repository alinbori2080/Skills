[CmdletBinding()]
param(
    [ValidateRange(1, 65535)]
    [int]$FallbackPort = 7897,
    [switch]$SkipPortCheck
)

$ErrorActionPreference = "Stop"

function ConvertTo-NormalizedProxyUri {
    [CmdletBinding()]
    param([AllowEmptyString()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    $candidate = $Value.Trim()
    if ($candidate -notmatch "^[a-zA-Z][a-zA-Z0-9+.-]*://") {
        $candidate = "http://$candidate"
    }

    try {
        $uri = [Uri]$candidate
    }
    catch {
        return $null
    }

    if (-not $uri.IsAbsoluteUri -or [string]::IsNullOrWhiteSpace($uri.Host)) {
        return $null
    }

    $supportedSchemes = @("http", "https", "socks5", "socks5h")
    if ($uri.Scheme -notin $supportedSchemes) {
        return $null
    }

    if ($uri.AbsolutePath -ne "/" -or $uri.Query -or $uri.Fragment) {
        return $null
    }

    $hostText = $uri.Host
    if ($hostText.Contains(":")) {
        $hostText = "[$hostText]"
    }

    [pscustomobject]@{
        Proxy          = "{0}://{1}:{2}" -f $uri.Scheme.ToLowerInvariant(), $hostText, $uri.Port
        HasCredentials = -not [string]::IsNullOrWhiteSpace($uri.UserInfo)
        Host           = $uri.Host
        Port           = $uri.Port
    }
}

function Get-WinInetProxyValue {
    [CmdletBinding()]
    param([AllowEmptyString()][string]$ProxyServer)

    if ([string]::IsNullOrWhiteSpace($ProxyServer)) {
        return $null
    }

    if ($ProxyServer -notmatch "=") {
        return $ProxyServer.Trim()
    }

    $mapped = @{}
    foreach ($part in ($ProxyServer -split ";")) {
        $pair = $part -split "=", 2
        if ($pair.Count -eq 2 -and -not [string]::IsNullOrWhiteSpace($pair[1])) {
            $mapped[$pair[0].Trim().ToLowerInvariant()] = $pair[1].Trim()
        }
    }

    foreach ($scheme in @("https", "http", "socks")) {
        if ($mapped.ContainsKey($scheme)) {
            return $mapped[$scheme]
        }
    }

    return $null
}

function Test-LocalProxyPort {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$HostName,
        [Parameter(Mandatory = $true)][int]$Port,
        [int]$TimeoutMilliseconds = 500
    )

    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $connection = $client.BeginConnect($HostName, $Port, $null, $null)
        if (-not $connection.AsyncWaitHandle.WaitOne($TimeoutMilliseconds, $false)) {
            return $false
        }
        $client.EndConnect($connection)
        return $true
    }
    catch {
        return $false
    }
    finally {
        $client.Dispose()
    }
}

function Select-ProxyCandidates {
    [CmdletBinding()]
    param(
        [AllowEmptyString()][string]$GitProxy,
        [AllowEmptyString()][string]$HttpsProxy,
        [AllowEmptyString()][string]$HttpProxy,
        [AllowEmptyString()][string]$AllProxy,
        [bool]$WinInetEnabled,
        [AllowEmptyString()][string]$WinInetProxy,
        [ValidateRange(1, 65535)][int]$FallbackPort = 7897,
        [switch]$SkipPortCheck
    )

    $rawCandidates = @(
        [pscustomobject]@{ Source = "git"; Value = $GitProxy }
        [pscustomobject]@{ Source = "environment:https_proxy"; Value = $HttpsProxy }
        [pscustomobject]@{ Source = "environment:http_proxy"; Value = $HttpProxy }
        [pscustomobject]@{ Source = "environment:all_proxy"; Value = $AllProxy }
    )

    if ($WinInetEnabled) {
        $rawCandidates += [pscustomobject]@{ Source = "wininet"; Value = $WinInetProxy }
    }
    $rawCandidates += [pscustomobject]@{ Source = "fallback"; Value = "127.0.0.1:$FallbackPort" }

    $seen = @{}
    $priority = 0
    foreach ($raw in $rawCandidates) {
        $normalized = ConvertTo-NormalizedProxyUri -Value $raw.Value
        if ($null -eq $normalized -or $seen.ContainsKey($normalized.Proxy)) {
            continue
        }

        $seen[$normalized.Proxy] = $true
        $priority++
        $isLoopback = $normalized.Host -in @("127.0.0.1", "localhost", "::1")
        $listening = "not-checked"
        if ($isLoopback -and -not $SkipPortCheck) {
            $listening = if (Test-LocalProxyPort -HostName $normalized.Host -Port $normalized.Port) { "true" } else { "false" }
        }

        [pscustomobject]@{
            Priority       = $priority
            Source         = $raw.Source
            Proxy          = $normalized.Proxy
            Listening      = $listening
            HasCredentials = $normalized.HasCredentials
        }
    }
}

function Invoke-GitHubProxyDetection {
    [CmdletBinding()]
    param(
        [ValidateRange(1, 65535)][int]$FallbackPort = 7897,
        [switch]$SkipPortCheck
    )

    $gitProxy = ""
    try {
        $gitProxy = (& git config --get-urlmatch http.proxy "https://github.com/" 2>$null | Select-Object -First 1)
    }
    catch {
        $gitProxy = ""
    }

    $winInetEnabled = $false
    $winInetProxy = ""
    try {
        $settings = Get-ItemProperty -LiteralPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
        $winInetEnabled = [int]$settings.ProxyEnable -eq 1
        if ($winInetEnabled) {
            $winInetProxy = Get-WinInetProxyValue -ProxyServer ([string]$settings.ProxyServer)
        }
    }
    catch {
        $winInetEnabled = $false
    }

    $candidates = @(Select-ProxyCandidates `
        -GitProxy $gitProxy `
        -HttpsProxy ([string]$env:HTTPS_PROXY) `
        -HttpProxy ([string]$env:HTTP_PROXY) `
        -AllProxy ([string]$env:ALL_PROXY) `
        -WinInetEnabled $winInetEnabled `
        -WinInetProxy $winInetProxy `
        -FallbackPort $FallbackPort `
        -SkipPortCheck:$SkipPortCheck)

    [pscustomobject]@{
        Result     = if ($candidates.Count -gt 0) { "candidates-found" } else { "no-candidates" }
        Platform   = "windows"
        Candidates = $candidates
    } | ConvertTo-Json -Depth 4
}

if ($MyInvocation.InvocationName -ne ".") {
    Invoke-GitHubProxyDetection -FallbackPort $FallbackPort -SkipPortCheck:$SkipPortCheck
}
