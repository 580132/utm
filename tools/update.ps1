#+------------------------------------------------------------------+
#|  UTM Manager - updater                                            |
#|                                                                   |
#|  Compares the installed UTM version with the latest GitHub        |
#|  release, then downloads and installs it when a newer one exists. |
#|                                                                   |
#|  Usage:                                                           |
#|    pwsh -ExecutionPolicy Bypass -File .\tools\update.ps1          |
#|    .\tools\update.ps1 -Force                                      |
#|    .\tools\update.ps1 -CheckOnly                                  |
#+------------------------------------------------------------------+
[CmdletBinding()]
param(
    [string]$TerminalData = "",
    [string]$MetaEditor   = "",
    [string]$Repo         = "580132/utm",
    [switch]$IncludeTests,
    [switch]$NoCompile,
    [switch]$Force,
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"

try {
    [Net.ServicePointManager]::SecurityProtocol =
        [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch { }

#--- helpers --------------------------------------------------------------
function Resolve-TerminalData([string]$Path)
{
    if ([string]::IsNullOrWhiteSpace($Path))
    {
        $base = Join-Path $env:APPDATA "MetaQuotes\Terminal"
        if (-not (Test-Path $base)) { throw "MetaQuotes terminal folder not found. Pass -TerminalData." }

        $candidates = Get-ChildItem $base -Directory |
            Where-Object { Test-Path (Join-Path $_.FullName "MQL5") } |
            Sort-Object LastWriteTime -Descending

        if (-not $candidates) { throw "No MT5 data folder found. Pass -TerminalData." }
        $Path = Join-Path $candidates[0].FullName "MQL5"
        Write-Host "Using terminal data folder:" $Path
    }

    $Path = $Path.TrimEnd('\')
    if ((Split-Path $Path -Leaf) -ne "MQL5")
    {
        if (Test-Path (Join-Path $Path "MQL5")) { $Path = Join-Path $Path "MQL5" }
    }
    return $Path
}

function Get-InstalledVersion([string]$DataFolder)
{
    $defines = Join-Path $DataFolder "Include\UTM\UTM_Defines.mqh"
    if (-not (Test-Path $defines)) { return "" }

    $m = Select-String -Path $defines -Pattern '#define\s+UTM_VERSION\s+"([^"]+)"' |
         Select-Object -First 1
    if ($m) { return $m.Matches[0].Groups[1].Value }
    return ""
}

function ConvertTo-Version([string]$Value)
{
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    $text = $Value.Trim()
    if ($text -match '^[vV]') { $text = $text.Substring(1) }
    try { return [version]$text } catch { return $null }
}

function Test-SameVersion([string]$A, [string]$B)
{
    $va = ConvertTo-Version $A
    $vb = ConvertTo-Version $B
    if ($va -and $vb) { return $va -eq $vb }
    $sa = $A.Trim().TrimStart('v', 'V')
    $sb = $B.Trim().TrimStart('v', 'V')
    return $sa -eq $sb
}

function Get-LatestRelease([string]$RepoName)
{
    $headers = @{ "User-Agent" = "utm-updater" }
    if ($env:GITHUB_TOKEN) { $headers["Authorization"] = "Bearer $($env:GITHUB_TOKEN)" }

    try
    {
        return Invoke-RestMethod -Uri "https://api.github.com/repos/$RepoName/releases/latest" `
                                 -Headers $headers -UseBasicParsing
    }
    catch
    {
        Write-Verbose "Release lookup failed: $($_.Exception.Message)"
    }

    $tags = @(Invoke-RestMethod -Uri "https://api.github.com/repos/$RepoName/tags" `
                                -Headers $headers -UseBasicParsing)
    if ($tags.Count -gt 0)
    {
        return [pscustomobject]@{ tag_name = [string]$tags[0].name; body = "" }
    }
    throw "Could not determine the latest version of $RepoName."
}

function Get-InstallerScript([string]$Tag, [string]$RepoName)
{
    $local = Join-Path $PSScriptRoot "install.ps1"
    if (Test-Path $local) { return $local }

    $temp = Join-Path ([IO.Path]::GetTempPath()) ("utm-install-" + [guid]::NewGuid().ToString("N") + ".ps1")
    $url  = "https://raw.githubusercontent.com/$RepoName/$Tag/tools/install.ps1"
    Write-Host "Downloading installer from $url"
    Invoke-WebRequest -Uri $url -OutFile $temp -UseBasicParsing
    return $temp
}

#--- compare versions -----------------------------------------------------
$TerminalData = Resolve-TerminalData $TerminalData
$installed    = Get-InstalledVersion $TerminalData
$release      = Get-LatestRelease $Repo
$latest       = [string]$release.tag_name

if ([string]::IsNullOrWhiteSpace($latest)) { throw "GitHub returned an empty release tag." }

if ([string]::IsNullOrWhiteSpace($installed))
{
    Write-Host "UTM is not installed in $TerminalData"
    if ($CheckOnly) { Write-Host "Latest available: $latest"; exit 1 }
    Write-Host "Installing $latest ..."
}
elseif ((Test-SameVersion $installed $latest) -and -not $Force)
{
    Write-Host "UTM $installed is already up to date (latest: $latest)."
    exit 0
}
else
{
    Write-Host "UTM update available: $installed -> $latest"
    if ($CheckOnly) { exit 0 }
    if ($release.body) { Write-Host ""; Write-Host $release.body; Write-Host "" }
}

#--- run the installer ----------------------------------------------------
$installer = Get-InstallerScript $latest $Repo
$installArgs = @{
    TerminalData = $TerminalData
    MetaEditor   = $MetaEditor
    Version      = $latest
    Repo         = $Repo
}
if ($IncludeTests) { $installArgs.IncludeTests = $true }
if ($NoCompile)    { $installArgs.NoCompile    = $true }

& $installer @installArgs
if (-not $?) { exit 1 }
