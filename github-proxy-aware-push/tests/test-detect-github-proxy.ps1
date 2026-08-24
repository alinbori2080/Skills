$ErrorActionPreference = "Stop"

$scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) "scripts\detect-github-proxy.ps1"
. $scriptPath

$failures = [System.Collections.Generic.List[string]]::new()
$checks = 0

function Assert-Equal {
    param(
        [Parameter(Mandatory = $true)]$Actual,
        [Parameter(Mandatory = $true)]$Expected,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $script:checks++
    if ($Actual -ne $Expected) {
        $script:failures.Add("$Message (expected='$Expected', actual='$Actual')")
    }
}

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $script:checks++
    if (-not $Condition) {
        $script:failures.Add($Message)
    }
}

$plain = ConvertTo-NormalizedProxyUri -Value "127.0.0.1:7897"
Assert-Equal $plain.Proxy "http://127.0.0.1:7897" "A host and port should gain an HTTP scheme"
Assert-Equal $plain.HasCredentials $false "A plain local proxy should not report credentials"

$credentialedValue = "http://" + "sample-user" + ":" + "sample-password" + "@" + "127.0.0.1:7897"
$credentialed = ConvertTo-NormalizedProxyUri -Value $credentialedValue
Assert-Equal $credentialed.Proxy "http://127.0.0.1:7897" "Credentials must never appear in output"
Assert-Equal $credentialed.HasCredentials $true "Credential-bearing proxies should be flagged"

$winInet = Get-WinInetProxyValue -ProxyServer "http=127.0.0.1:8080;https=127.0.0.1:7897"
Assert-Equal $winInet "127.0.0.1:7897" "The HTTPS WinINET mapping should win for GitHub"

$winInetOnly = @(Select-ProxyCandidates -GitProxy "" -HttpsProxy "" -HttpProxy "" -AllProxy "" -WinInetEnabled $true -WinInetProxy "127.0.0.1:7897" -FallbackPort 7897 -SkipPortCheck)
Assert-Equal $winInetOnly.Count 1 "Duplicate fallback endpoints should be removed"
Assert-Equal $winInetOnly[0].Source "wininet" "WinINET should be selected before the fallback"

$ordered = @(Select-ProxyCandidates -GitProxy "http://127.0.0.1:9001" -HttpsProxy "http://127.0.0.1:9002" -HttpProxy "" -AllProxy "" -WinInetEnabled $true -WinInetProxy "127.0.0.1:7897" -FallbackPort 7897 -SkipPortCheck)
Assert-Equal $ordered[0].Source "git" "Git proxy configuration should have highest priority"
Assert-Equal $ordered[1].Source "environment:https_proxy" "HTTPS_PROXY should follow Git configuration"
Assert-Equal $ordered[2].Source "wininet" "WinINET should follow environment configuration"

$fallback = @(Select-ProxyCandidates -GitProxy "" -HttpsProxy "" -HttpProxy "" -AllProxy "" -WinInetEnabled $false -WinInetProxy "127.0.0.1:8000" -FallbackPort 7897 -SkipPortCheck)
Assert-Equal $fallback.Count 1 "A fallback candidate should exist when no proxy is configured"
Assert-Equal $fallback[0].Source "fallback" "A disabled WinINET proxy must be ignored"
Assert-Equal $fallback[0].Proxy "http://127.0.0.1:7897" "The Windows fallback should use port 7897"

$invalid = ConvertTo-NormalizedProxyUri -Value "not a valid proxy value"
Assert-True ($null -eq $invalid) "Invalid proxy values should be ignored"

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Error $failure
    }
    exit 1
}

Write-Output "PASS: $checks checks"
