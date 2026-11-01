#+------------------------------------------------------------------+
#|  UTM Manager - installer / builder                                |
#|                                                                   |
#|  Local checkout : copies MQL5\ sources and compiles.              |
#|  Standalone     : downloads a GitHub release, then installs.      |
#|                                                                   |
#|  Usage:                                                           |
#|    pwsh -ExecutionPolicy Bypass -File .\tools\install.ps1         |
#|    .\tools\install.ps1 -Version v1.25 -IncludeTests               |
#+------------------------------------------------------------------+
[CmdletBinding()]
param(
    [string]$TerminalData = "",
    [string]$MetaEditor   = "",
    [string]$Version      = "",
    [string]$Repo         = "580132/utm",
    [switch]$Local,
    [switch]$IncludeTests,
    [switch]$NoCompile
)

$ErrorActionPreference = "Stop"

try {
    [Net.ServicePointManager]::SecurityProtocol =
        [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch { }

$repoRoot     = Split-Path -Parent $PSScriptRoot
$localInclude = Join-Path $repoRoot "MQL5\Include\UTM"
$localExpert  = Join-Path $repoRoot "MQL5\Experts\UTM Manager"
$hasLocal     = (Test-Path $localInclude) -and (Test-Path $localExpert)

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

function Get-GitHubHeaders
{
    $headers = @{ "User-Agent" = "utm-installer" }
    if ($env:GITHUB_TOKEN) { $headers["Authorization"] = "Bearer $($env:GITHUB_TOKEN)" }
    return $headers
}

function Get-LatestTagFromWeb([string]$RepoName)
{
    try
    {
        $resp = Invoke-WebRequest -Uri "https://github.com/$RepoName/releases/latest" -UseBasicParsing
    }
    catch
    {
        return ""
    }

    $final = ""
    try { $final = [string]$resp.BaseResponse.RequestMessage.RequestUri } catch { }
    if ([string]::IsNullOrWhiteSpace($final))
    {
        try { $final = [string]$resp.BaseResponse.ResponseUri } catch { }
    }
    if ($final -match '/tag/([^/?#]+)') { return $Matches[1] }
    if ($resp.Content -match '/releases/tag/([^"''<> ]+)') { return $Matches[1] }
    return ""
}

function Get-LatestTag([string]$RepoName)
{
    $headers = Get-GitHubHeaders
    try
    {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$RepoName/releases/latest" `
                                     -Headers $headers -UseBasicParsing
        if ($release.tag_name) { return [string]$release.tag_name }
    }
    catch
    {
        Write-Verbose "Latest release lookup failed: $($_.Exception.Message)"
    }

    $tag = Get-LatestTagFromWeb $RepoName
    if (-not [string]::IsNullOrWhiteSpace($tag)) { return $tag }

    throw "Could not determine the latest version of $RepoName."
}

function Save-SourceArchive([string]$RepoName, [string]$Tag, [string]$ZipPath)
{
    $refs = @()
    $tagCandidates = @($Tag)
    if ($Tag -notmatch '^[vV]') { $tagCandidates += "v$Tag" }
    if ($Tag -match '^[vV]')   { $tagCandidates += $Tag.Substring(1) }
    foreach ($t in $tagCandidates) { $refs += @{ Kind = "tags"; Name = $t } }
    $refs += @{ Kind = "heads"; Name = $Tag }

    foreach ($ref in $refs)
    {
        $url = "https://github.com/$RepoName/archive/refs/$($ref.Kind)/$($ref.Name).zip"
        try
        {
            Write-Host "Downloading" $url
            Invoke-WebRequest -Uri $url -OutFile $ZipPath -UseBasicParsing
            return
        }
        catch
        {
            Write-Verbose "Download failed: $url"
        }
    }
    throw "Could not download source for $RepoName ($Tag)."
}

function Expand-Source([string]$ZipPath, [string]$Dest)
{
    Expand-Archive -Path $ZipPath -DestinationPath $Dest -Force
    $dirs = @(Get-ChildItem $Dest -Directory)
    if ($dirs.Count -eq 1 -and (Test-Path (Join-Path $dirs[0].FullName "MQL5")))
    {
        return $dirs[0].FullName
    }
    if (Test-Path (Join-Path $Dest "MQL5")) { return $Dest }
    throw "Unexpected archive layout in $ZipPath."
}

function Remove-Target([string]$Path)
{
    if (-not (Test-Path $Path)) { return }
    $item = Get-Item $Path -Force
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
    {
        # junction / symlink: delete the link only
        $item.Delete()
    }
    else
    {
        Remove-Item $Path -Recurse -Force
    }
}

function Find-MetaEditor([string]$DataFolder)
{
    if (-not [string]::IsNullOrWhiteSpace($MetaEditor)) { return $MetaEditor }

    $paths = @()
    $origin = Join-Path (Split-Path $DataFolder -Parent) "origin.txt"
    if (Test-Path $origin) { $paths += (Get-Content $origin -TotalCount 1).Trim() }

    $uninstallKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($key in $uninstallKeys)
    {
        Get-ItemProperty $key -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like "MetaTrader*" -and $_.InstallLocation } |
            ForEach-Object { $paths += $_.InstallLocation }
    }

    $bases = @($env:ProgramFiles, ${env:ProgramFiles(x86)}, (Join-Path $env:LOCALAPPDATA "Programs"))
    foreach ($base in $bases)
    {
        if ([string]::IsNullOrWhiteSpace($base) -or -not (Test-Path $base)) { continue }
        Get-ChildItem $base -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "MetaTrader*" } |
            ForEach-Object { $paths += $_.FullName }
    }

    $paths += @(
        "C:\Program Files\MetaTrader 5",
        "C:\Program Files\MetaTrader 5 EXNESS",
        "C:\Program Files\MetaTrader 5 IC Markets"
    )

    foreach ($p in $paths)
    {
        $exe = Join-Path $p "MetaEditor64.exe"
        if (Test-Path $exe) { return $exe }
    }
    return ""
}

#--- resolve the MT5 data folder ------------------------------------------
$TerminalData = Resolve-TerminalData $TerminalData

#--- obtain sources -------------------------------------------------------
$tempRoot = $null
try
{
    if ($Local -and -not $hasLocal)
    {
        throw "Local sources not found under $repoRoot. Remove -Local to download a release."
    }

    $useLocal = $hasLocal -and ($Local -or [string]::IsNullOrWhiteSpace($Version))

    if ($useLocal)
    {
        $srcRoot = $repoRoot
        $label   = "local checkout"
    }
    else
    {
        if ([string]::IsNullOrWhiteSpace($Version)) { $Version = Get-LatestTag $Repo }

        $tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("utm-src-" + [guid]::NewGuid().ToString("N"))
        New-Item -ItemType Directory -Path $tempRoot | Out-Null

        $zip = Join-Path $tempRoot "utm.zip"
        Save-SourceArchive -RepoName $Repo -Tag $Version -ZipPath $zip
        $srcRoot = Expand-Source -ZipPath $zip -Dest (Join-Path $tempRoot "extract")
        $label   = $Version
    }

    $srcInclude = Join-Path $srcRoot "MQL5\Include\UTM"
    $srcExpert  = Join-Path $srcRoot "MQL5\Experts\UTM Manager"
    $srcTests   = Join-Path $srcRoot "MQL5\Experts\UTM Tests"

    if (-not (Test-Path $srcExpert))  { throw "Source not found: $srcExpert" }
    if (-not (Test-Path $srcInclude)) { throw "Source not found: $srcInclude" }

    Write-Host "Installing from $label"

    #--- copy sources -----------------------------------------------------
    Remove-Target (Join-Path $TerminalData "Include\UTM")
    Copy-Item $srcInclude (Join-Path $TerminalData "Include\UTM") -Recurse -Force
    Write-Host "Installed Include\UTM"

    Remove-Target (Join-Path $TerminalData "Experts\UTM Manager")
    Copy-Item $srcExpert (Join-Path $TerminalData "Experts\UTM Manager") -Recurse -Force
    Write-Host "Installed Experts\UTM Manager"

    if ($IncludeTests -and (Test-Path $srcTests))
    {
        Remove-Target (Join-Path $TerminalData "Experts\UTM Tests")
        Copy-Item $srcTests (Join-Path $TerminalData "Experts\UTM Tests") -Recurse -Force
        Write-Host "Installed Experts\UTM Tests"
    }

    #--- report installed version ----------------------------------------
    $defines = Join-Path $TerminalData "Include\UTM\UTM_Defines.mqh"
    if (Test-Path $defines)
    {
        $m = Select-String -Path $defines -Pattern '#define\s+UTM_VERSION\s+"([^"]+)"' |
             Select-Object -First 1
        if ($m) { Write-Host "Installed UTM version:" $m.Matches[0].Groups[1].Value }
    }

    if ($NoCompile) { Write-Host "Skipping compilation (-NoCompile)"; return }

    #--- compile ----------------------------------------------------------
    $editor = Find-MetaEditor $TerminalData
    if ([string]::IsNullOrWhiteSpace($editor) -or -not (Test-Path $editor))
    {
        Write-Warning "MetaEditor64.exe not found. Open UTM_Manager.mq5 in MetaEditor and press F7."
        return
    }
    Write-Host "Using MetaEditor:" $editor

    $targets = @(Join-Path $TerminalData "Experts\UTM Manager\UTM_Manager.mq5")
    if ($IncludeTests) { $targets += (Join-Path $TerminalData "Experts\UTM Tests\UTM_SelfTest.mq5") }

    $log = Join-Path $env:TEMP "utm_build.log"
    if (Test-Path $log) { Remove-Item $log -Force }

    $margs = @()
    foreach ($t in $targets) { $margs += "/compile:`"$t`"" }
    $margs += "/log:`"$log`""

    $proc = Start-Process -FilePath $editor -ArgumentList $margs -Wait -PassThru
    Write-Host "MetaEditor exit code:" $proc.ExitCode

    if (Test-Path $log)
    {
        $lines = Get-Content $log -Encoding Unicode
        $issues = $lines | Where-Object { $_ -match ":\s*(error|warning)\s" }
        if ($issues) { $issues | ForEach-Object { Write-Host $_ } }
        $result = $lines | Where-Object { $_ -match "Result:" }
        if ($result) { Write-Host $result }
    }

    $ex5 = Join-Path $TerminalData "Experts\UTM Manager\UTM_Manager.ex5"
    if (Test-Path $ex5)
    {
        Write-Host "Build OK:" $ex5
        Write-Host "Attach 'UTM Manager' from the Navigator to a chart (Algo Trading enabled)."
    }
    else
    {
        Write-Warning "UTM_Manager.ex5 was not produced - check the compile log above."
        exit 1
    }
}
finally
{
    if ($tempRoot -and (Test-Path $tempRoot))
    {
        Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
