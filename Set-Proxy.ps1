function Set-EnvProxy {
    Param
    (
        [parameter(Mandatory = $true)][String]$Scope,
        [String]$Proxy,
        [String]$NoProxy
    )

    if ($Proxy -eq "") {
        Write-Output "Unset environment variables http_proxy / https_proxy"
        [Environment]::SetEnvironmentVariable("http_proxy", $null, $Scope)
        [Environment]::SetEnvironmentVariable("https_proxy", $null, $Scope)
    }
    else {
        Write-Output "Set environment variables http_proxy / https_proxy to '$Proxy'"
        [Environment]::SetEnvironmentVariable("http_proxy", $Proxy, $Scope)
        [Environment]::SetEnvironmentVariable("https_proxy", $Proxy, $Scope)
    }

    if ($NoProxy -eq "") {
        Write-Output "Unset environment variables no_proxy"
        [Environment]::SetEnvironmentVariable("no_proxy", $null, $Scope)
    }
    else {
        Write-Output "Set environment variables no_proxy to '$NoProxy'"
        [Environment]::SetEnvironmentVariable("no_proxy", $NoProxy, $Scope)
    }
}

function Set-GitProxy {
    Param
    (
        [parameter(Mandatory = $true)]$ProxyConfig
    )

    # Get content of .gitconfig
    $GitFile = "$($env:USERPROFILE)\.gitconfig"
    if (-not (Test-Path -Path $GitFile)) {
        Write-Output ".gitconfig does not exists"
        return
    }
    $GitConfig = Get-Content -Path $GitFile

    $LineNo = 0
    foreach ($line in $GitConfig) {
        # Evaluate the current section we are in
        if ($line -match '\[http\]') {
            $ProxyToUse = $ProxyConfig.Proxy
            $Output = "Set Git general proxy to '$ProxyToUse'"
        }
        elseif ($line -match '\[http (.*)\]') {
            $Server = $($Matches[1].Replace('"', ''))
            # If there is no proxy config for this server, use the general proxy setting
            if ($null -eq $ProxyConfig.$Server.Proxy) {
                $ProxyToUse = $ProxyConfig.Proxy
            }
            else {
                $ProxyToUse = $ProxyConfig.$Server.Proxy
            }
            $Output = "Set Git proxy for server '$Server' to '$ProxyToUse'"
        }
        elseif ($line -match '\[.*\]') {
            $ProxyToUse = $null
        }

        # Handle only lines for proxy
        if ($line -match "(proxy\s=)") {
            if ($null -ne $ProxyToUse) {
                $Pos = $line.IndexOf($Matches[1]) + $Matches[1].length
                $GitConfig[$LineNo] = $line.Substring(0, $Pos) + " ""$ProxyToUse"""
                Write-Output $Output
            }
        }
        $LineNo++
    }

    # Write the result
    $GitConfig | Out-File -FilePath $GitFile
}

enum  RunModes {
    User
    Machine
}

Write-Output "========== $(Get-Date) =========="
$Mode = [RunModes]::User
if ($env:USERNAME -eq "$($env:COMPUTERNAME)`$") {
    $Mode = [RunModes]::Machine
}
Write-Output "Running as user '$($env:USERNAME.ToUpper())' in mode '$Mode'"
$Locations = Get-NetConnectionProfile | ForEach-Object { $_.Name }
if ($Locations.Count -eq 0) {
    Write-Output "No locations found, exit!"
    exit 0
}
Write-Output "Current locations:"
$Locations

$Config = Get-Content -Path "$PSScriptRoot\ProxyConfig.json" | ConvertFrom-Json

$LocationHandled = $false
foreach ($LocationConfig in $Config.PSObject.Properties) {
    if ($Locations.Contains($LocationConfig.Name)) {
        $LocationHandled = $true
        Write-Output "Known location '$($LocationConfig.Name)'"
        Set-EnvProxy -Scope $Mode -Proxy $LocationConfig.Value.$Mode.env.proxy -NoProxy $LocationConfig.Value.$Mode.env.noproxy
        Set-GitProxy -ProxyConfig $LocationConfig.Value.$Mode.git
    }
}

if (-not $LocationHandled) {
    Write-Output "No known location found, using default"
    Set-EnvProxy -Scope $Mode -Proxy $Config.Default.$Mode.env.proxy -NoProxy $Config.Default.$Mode.env.noproxy
    Set-GitProxy -ProxyConfig $Config.Default.$Mode.git
}
