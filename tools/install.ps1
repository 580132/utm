#+------------------------------------------------------------------+
#|  UTM Manager - installer / builder                                |
#|  Copies the sources into a MetaTrader 5 data folder and compiles. |
#+------------------------------------------------------------------+
[CmdletBinding()]
param(
    [string]$TerminalData = "",
    [string]$MetaEditor   = "",
    [switch]$IncludeTests,
    [switch]$NoCompile
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$srcInclude = Join-Path $root "MQL5\Include\UTM"
$srcExpert  = Join-Path $root "MQL5\Experts\UTM Manager"
$srcTests   = Join-Path $root "MQL5\Experts\UTM Tests"

if (-not (Test-Path $srcExpert)) { throw "Source not found: $srcExpert" }

#--- locate the MT5 data folder ------------------------------------------
if ([string]::IsNullOrWhiteSpace($TerminalData))
{
    $base = Join-Path $env:APPDATA "MetaQuotes\Terminal"
    if (-not (Test-Path $base)) { throw "MetaQuotes terminal folder not found. Pass -TerminalData." }

    $candidates = Get-ChildItem $base -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName "MQL5") } |
        Sort-Object LastWriteTime -Descending

    if (-not $candidates) { throw "No MT5 data folder found. Pass -TerminalData." }
    $TerminalData = Join-Path $candidates[0].FullName "MQL5"
    Write-Host "Using terminal data folder:" $TerminalData
}

$TerminalData = $TerminalData.TrimEnd('\')
if ((Split-Path $TerminalData -Leaf) -ne "MQL5")
{
    if (Test-Path (Join-Path $TerminalData "MQL5"))
    {
        $TerminalData = Join-Path $TerminalData "MQL5"
    }
}

#--- remove a previous copy or junction ----------------------------------
function Remove-Target([string]$path)
{
    if (-not (Test-Path $path)) { return }
    $item = Get-Item $path -Force
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
    {
        # junction / symlink: delete the link only
        $item.Delete()
    }
    else
    {
        Remove-Item $path -Recurse -Force
    }
}

#--- copy sources ---------------------------------------------------------
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

#--- locate MetaEditor ----------------------------------------------------
if ([string]::IsNullOrWhiteSpace($MetaEditor))
{
    $origin = Join-Path (Split-Path $TerminalData -Parent) "origin.txt"
    $paths = @()
    if (Test-Path $origin) { $paths += (Get-Content $origin -TotalCount 1).Trim() }
    $paths += @(
        "C:\Program Files\MetaTrader 5",
        "C:\Program Files\MetaTrader 5 EXNESS",
        (Join-Path $env:LOCALAPPDATA "Programs\MetaTrader 5")
    )
    foreach ($p in $paths)
    {
        $exe = Join-Path $p "MetaEditor64.exe"
        if (Test-Path $exe) { $MetaEditor = $exe; break }
    }
}

if ($NoCompile) { Write-Host "Skipping compilation (-NoCompile)"; return }
if ([string]::IsNullOrWhiteSpace($MetaEditor) -or -not (Test-Path $MetaEditor))
{
    Write-Warning "MetaEditor64.exe not found. Compile manually with F7."
    return
}

#--- compile --------------------------------------------------------------
$targets = @(Join-Path $TerminalData "Experts\UTM Manager\UTM_Manager.mq5")
if ($IncludeTests) { $targets += (Join-Path $TerminalData "Experts\UTM Tests\UTM_SelfTest.mq5") }

$log = Join-Path $env:TEMP "utm_build.log"
if (Test-Path $log) { Remove-Item $log -Force }

$margs = @()
foreach ($t in $targets) { $margs += "/compile:`"$t`"" }
$margs += "/log:`"$log`""

$proc = Start-Process -FilePath $MetaEditor -ArgumentList $margs -Wait -PassThru
Write-Host "MetaEditor exit code:" $proc.ExitCode

if (Test-Path $log)
{
    $lines = Get-Content $log -Encoding Unicode
    $errors = $lines | Where-Object { $_ -match "error|warning" }
    if ($errors) { $errors | ForEach-Object { Write-Host $_ } }
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
}
