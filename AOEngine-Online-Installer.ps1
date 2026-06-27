#requires -Version 5.1
# PSScriptAnalyzer: Disable=PSUseApprovedVerbs
<#
.SYNOPSIS
    AOEngine-Online-Installer - Automated deployment for the AOEngine project.
    Parameters:
    -TrustBanner    : Show the trust banner.
    -Recovery       : Recovers the files from previous install.
    -Silent         : Runs the installer with minimal console output.
    -SilenceErrors  : Prevents the script from pausing on errors (exit code matters, 0 - ok, 1 - uh oh).
    -NoBackup       : Skips backing up existing game files.
    -Logging        : Enables writing installation steps to a log file.
    -Instructions   : Shows MO2 configuration steps.
    -DisableConsoleBeeps : As said.
    
.AUTHOR
    kamil_zeus
    
.VERSION
    1.8.1 (hotfix)
    
.LICENSE
    Script made by kamil_zeus (kamil_zeus on Discord).
    DO NOT REMOVE THIS HEADER. Modification is allowed, but attribution is mandatory.
    Updates are provided on an "as-lazy-as-possible" basis.
#>

param(
    [Alias("TB")] [switch]$TrustBanner,
    [Alias("R")] [switch]$Recovery,
    [Alias("S")] [switch]$Silent,
    [Alias("NB")] [switch]$NoBackup,
    [Alias("L")] [switch]$Logging,
    [Alias("I")] [switch]$Instructions,
    [Alias("GH")] [switch]$GenerateHashes,
    [Alias("SE")] [switch]$SilenceErrors,
    [Alias("DCB")] [switch]$DisableConsoleBeeps
)

[Net.ServicePointManager]::SecurityProtocol = `
    [Net.ServicePointManager]::SecurityProtocol -bor `
    [Net.SecurityProtocolType]::Tls12 -bor `
    [Net.SecurityProtocolType]::Tls13

try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
} catch {
    Write-Warning "Compression assembly not available. Archive operations may fail: $($_.Exception.Message)"
}


if ($env:OS -notlike "*Windows*") {
    [Console]::ForegroundColor = 'Magenta'
    [Console]::WriteLine("========================================================================================================")
    [Console]::WriteLine("[?] [The Creator's Handler] You won't run this here. Don't even bother.")
    [Console]::WriteLine("It's not worth it. Trust me.")
    [Console]::WriteLine("========================================================================================================")
    [Console]::ForegroundColor = 'White'
    exit
}
function Admintest {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Beeps are intentional: installer is destructive and long-running.
# Disable with -DCB if your ears are not ready.

function DoINeedAdmin {
    param([string]$path)
    $pf = [Regex]::Escape([Environment]::GetFolderPath("ProgramFiles"))
    $pf86 = [Regex]::Escape([Environment]::GetFolderPath("ProgramFilesX86"))
    $windir = [Regex]::Escape($env:windir)
    if ($path -match "(?i)^($pf|$pf86|$windir)") {
        return $true
    }
    return $false
}

if (DoINeedAdmin -path $PSScriptRoot -and -not (Admintest)) {
    [Console]::ForegroundColor = 'Red'
    [Console]::WriteLine("========================================================================================================")
    [Console]::WriteLine("[X] [Runtime Handler] Administrator privileges required for this location.")
    [Console]::WriteLine("[!] Game detected in restricted folder. Please run as Administrator.")
    [Console]::WriteLine("========================================================================================================")
    [Console]::ResetColor()
    Read-Host "Press ENTER to exit"
    exit 1
}

$rawBaseDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }

$cfg = [pscustomobject]@{
    IsSilent       = $Silent.IsPresent
    Version        = "1.8"
    ScriptName     = "AOEngine-Online-Installer"
    BaseDir        = [System.IO.Path]::GetFullPath($rawBaseDir)
    LogFilePath    = ""
    SourceDir      = ""
    RecoveryDir    = ""
    ExtractDir     = ""
    StagingDir     = ""
    InstallationStarted = $false
    AllowedDeletes = @()
}

function Get-CanonicalPath {
    param([string]$path)
    if ([string]::IsNullOrWhiteSpace($path)) {
        throw "Get-CanonicalPath: path is empty."
    }
    $base = $cfg.BaseDir
    $full = if ([System.IO.Path]::IsPathRooted($path)) {
        [System.IO.Path]::GetFullPath($path)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $base $path))
    }
    return $full
}


$ul     = [char]27 + "[4m"
$reset  = [char]27 + "[0m"
$cfg.LogFilePath = Get-CanonicalPath ("$($cfg.ScriptName)_$($cfg.Version).log")
$cfg.SourceDir   = Get-CanonicalPath (".aoeneeded")
$cfg.RecoveryDir   = Get-CanonicalPath (".recovery")
$cfg.ExtractDir  = Get-CanonicalPath (".extract")
$cfg.StagingDir  = Get-CanonicalPath (".stage_install")
$cfg.AllowedDeletes = @(
    $cfg.SourceDir,
    $cfg.ExtractDir,
    (Get-CanonicalPath "gamedata"),
    (Get-CanonicalPath "appdata\shaders_cache"),
    (Get-CanonicalPath "db\mods\00_modded_exes_gamedata.db0")
)

Function Write-ToLog {
    param([string]$text)
    if ($Logging) {
        $cleanText = $text -replace '\e\[[0-9;]*m', ''
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        try {
            [System.IO.File]::AppendAllText($cfg.LogFilePath, "[$timestamp] $cleanText`r`n", [System.Text.Encoding]::UTF8)
        } catch {
            # logging failure ignored intentionally
        }
    }
}

if ($Logging) {
    [System.IO.File]::WriteAllText($cfg.LogFilePath, "=== AOEngine Online Installer Log Start ===`r`n", [System.Text.Encoding]::UTF8)
}

if ($cfg.IsSilent) {
    $script:ProgressPreference = 'SilentlyContinue'
}  

# unified output and interface functions
Function Info {
    param(
        [string]$text = "",
        [string]$ForegroundColor
    )
    if ([string]::IsNullOrWhiteSpace($text)) { return }
    if (-not $cfg.IsSilent) {
        try {
            if ($ForegroundColor) {
                Microsoft.PowerShell.Utility\Write-Host $text -ForegroundColor $ForegroundColor
            } else {
                Microsoft.PowerShell.Utility\Write-Host $text
            }
        } catch {
            Microsoft.PowerShell.Utility\Write-Host $text
        }
    } else {
        Write-ToLog ($text -replace '\e
        
\[[0-9;]*m', '')
    }
}

Function Step {
    param([string]$text)
    if ([string]::IsNullOrWhiteSpace($text)) { return }
    Write-ToLog "[>] $text"
    if ($cfg.IsSilent) { return }
    Microsoft.PowerShell.Utility\Write-Host "[>] $text" -ForegroundColor Cyan
    if (-not $DisableConsoleBeeps) {
        try { [Console]::Beep(2500, 10) } catch {}
    }
}


Function Success {
    param([string]$text)
    if ([string]::IsNullOrWhiteSpace($text)) { return }
    Write-ToLog "[+] $text"
    if ($cfg.IsSilent) { return }
    Microsoft.PowerShell.Utility\Write-Host "[+] $text" -ForegroundColor Green
    if (-not $DisableConsoleBeeps) {
        try { [Console]::Beep(1000, 150) } catch {}
    }
}


Function Warning {
    param(
        [string]$text,
        [int]$CenterWidth = 0
    )
    if ([string]::IsNullOrWhiteSpace($text)) { return }
    Write-ToLog "[!] $text"
    if ($cfg.IsSilent) { return }
    $FullText = "[!] $text"
    if ($CenterWidth -gt 0) {
        $Spaces = [math]::Max(0, [int](($CenterWidth - $FullText.Length) / 2))
        $FullText = (" " * $Spaces) + $FullText
    }
    Microsoft.PowerShell.Utility\Write-Host $FullText -ForegroundColor Yellow
    if (-not $DisableConsoleBeeps) {
        try { [Console]::Beep(500, 300) } catch {}
    }
}

Function AnError {
    param(
        [string]$text,
        [string]$Hint = ""
    )
    if ([string]::IsNullOrWhiteSpace($text)) { $text = "Unknown error." }
    Write-ToLog "[X] $text"
    if ($Hint) { Write-ToLog "[!] $Hint" }
    if ($cfg.IsSilent) {
        Microsoft.PowerShell.Utility\Write-Error $text -ErrorAction SilentlyContinue
        return
    }
    $LineWidth = 104
    $line = "=" * $LineWidth
    Microsoft.PowerShell.Utility\Write-Host ""
    Microsoft.PowerShell.Utility\Write-Host $line -ForegroundColor Red
    $FullErrorText = "[X] $text"
    $ErrorSpaces = [math]::Max(0, [int](($LineWidth - $FullErrorText.Length) / 2))
    Microsoft.PowerShell.Utility\Write-Host (" " * $ErrorSpaces + $FullErrorText) -ForegroundColor Red
    if ($Hint) {
        Warning -text $Hint -CenterWidth $LineWidth
    }
    Microsoft.PowerShell.Utility\Write-Host $line -ForegroundColor Red
    Microsoft.PowerShell.Utility\Write-Host ""
    if (-not $DisableConsoleBeeps) {
        try { [Console]::Beep(300, 600) } catch {}
    }
}


Function Wait-ForExit {
    if ($Instructions) {
        Read-Host "Press ENTER to exit"
        return
    }
    if ($cfg.IsSilent) {
        return
    }
    Read-Host "Press ENTER to exit"
}


Function Instructions {
    Clear-Host
    Write-ToLog "Displayed MO2 instructions"
    Microsoft.PowerShell.Utility\Write-Host "========================================================================================================" -ForegroundColor White
    Microsoft.PowerShell.Utility\Write-Host (" " * 44 + "MO2 Instructions") -ForegroundColor Cyan
    Microsoft.PowerShell.Utility\Write-Host "========================================================================================================" -ForegroundColor White
    Microsoft.PowerShell.Utility\Write-Host "[!] Enable '236- 1st Person Visible Body Ported from SWM - Wang_Laoshi & SWM Team'." -ForegroundColor Yellow
    Microsoft.PowerShell.Utility\Write-Host "[!] Remove '05_gamma aoe fixes' from MO2 to prevent crashes!" -ForegroundColor Yellow
    Microsoft.PowerShell.Utility\Write-Host "[!] Reinstall '190- Screen Space Shaders 23 - Ascii1457' by ${ul}UNCHECKING${reset} these components:" -ForegroundColor Yellow
    Microsoft.PowerShell.Utility\Write-Host "    -> [ ] 51 - PostProcess - BLOOM  (Causes visual problems.)" -ForegroundColor Cyan
    Microsoft.PowerShell.Utility\Write-Host "    -> [ ] 04 - SSR Water Ice Version (Unless you use winter mod.)" -ForegroundColor Cyan
    Microsoft.PowerShell.Utility\Write-Host "    -> [ ] 10- Wind [Optional] Vanilla Emission" -ForegroundColor Cyan
    Microsoft.PowerShell.Utility\Write-Host "    -> [ ] 991- Extra Laser+ [BaS] (When turned on, lasers are not visible.)" -ForegroundColor Cyan
    Microsoft.PowerShell.Utility\Write-Host "    -> [ ] 992 - Detectors+ [Vanilla]" -ForegroundColor Cyan
    Microsoft.PowerShell.Utility\Write-Host "    -> [ ] MANUAL INSTALLATION - MODDED EXE" -ForegroundColor Cyan
    Microsoft.PowerShell.Utility\Write-Host "[!] In the main menu, go to MCM Settings -> SWM Visible Body -> Scroll to the bottom -> Uncheck 'Remove body'." -ForegroundColor Yellow
    Microsoft.PowerShell.Utility\Write-Host "========================================================================================================" -ForegroundColor White
    Microsoft.PowerShell.Utility\Write-Host (" " * 30 + "if i'll have an idea what to type here, i will") -ForegroundColor Magenta
    Microsoft.PowerShell.Utility\Write-Host "========================================================================================================" -ForegroundColor White
    Microsoft.PowerShell.Utility\Write-Host ""
}

Function TrustBanner {
    Clear-Host
    Write-ToLog "Displayed Trust Banner"
    $LineWidth = 104
    Microsoft.PowerShell.Utility\Write-Host ("=" * $LineWidth) -ForegroundColor White
    $title = "AOEngine Online Installer - TRUST INFORMATION"
    $spaces = [math]::Max(0, [int](($LineWidth - $title.Length) / 2))
    Microsoft.PowerShell.Utility\Write-Host ((" " * $spaces) + $title) -ForegroundColor Green
    Microsoft.PowerShell.Utility\Write-Host ("=" * $LineWidth) -ForegroundColor White
    Microsoft.PowerShell.Utility\Write-Host "[!] This installer will ONLY modify folders inside your Anomaly directory:" -ForegroundColor Yellow
    Microsoft.PowerShell.Utility\Write-Host "    -> bin" -ForegroundColor Cyan
    Microsoft.PowerShell.Utility\Write-Host "    -> gamedata" -ForegroundColor Cyan
    Microsoft.PowerShell.Utility\Write-Host "    -> db" -ForegroundColor Cyan
    Microsoft.PowerShell.Utility\Write-Host "    -> appdata" -ForegroundColor Cyan
    Microsoft.PowerShell.Utility\Write-Host ""
    Microsoft.PowerShell.Utility\Write-Host "[!] It WILL NOT:" -ForegroundColor Yellow
    Microsoft.PowerShell.Utility\Write-Host "    -> modify Windows system files" -ForegroundColor Cyan
    Microsoft.PowerShell.Utility\Write-Host "    -> access or change the registry" -ForegroundColor Cyan
    Microsoft.PowerShell.Utility\Write-Host "    -> install background services" -ForegroundColor Cyan
    Microsoft.PowerShell.Utility\Write-Host "    -> add startup entries" -ForegroundColor Cyan
    Microsoft.PowerShell.Utility\Write-Host "    -> touch your Documents, Pictures, Desktop, or any personal files" -ForegroundColor Cyan
    Microsoft.PowerShell.Utility\Write-Host ""
    Microsoft.PowerShell.Utility\Write-Host ("=" * $LineWidth) -ForegroundColor White
    $footer = "All operations are restricted to the folder where this script is placed. I got nothing to hide."
    $spaces = [math]::Max(0, [int](($LineWidth - $footer.Length) / 2))
    Microsoft.PowerShell.Utility\Write-Host ((" " * $spaces) + $footer) -ForegroundColor Yellow
    Microsoft.PowerShell.Utility\Write-Host ("=" * $LineWidth) -ForegroundColor White
    Microsoft.PowerShell.Utility\Write-Host ""
    Wait-ForExit
    exit 0
}



function Lightweight {
    param(
        [Parameter(Mandatory=$true)][string]$source,
        [Parameter(Mandatory=$true)][string]$destination
    )
    try {
        $src = [System.IO.Path]::GetFullPath($source)
        $dst = [System.IO.Path]::GetFullPath($destination)
        if (-not [System.IO.Directory]::Exists($src)) {
            throw "[Lightweight Handler] Source directory does not exist: $src"
        }
        if (-not [System.IO.Directory]::Exists($dst)) {
            [void][System.IO.Directory]::CreateDirectory($dst)
        }
        foreach ($file in [System.IO.Directory]::GetFiles($src)) {
            try {
                $destFile = [System.IO.Path]::Combine($dst, [System.IO.Path]::GetFileName($file))
                [System.IO.File]::Copy($file, $destFile, $true)
            }
            catch {
                Write-ToLog "[Lightweight Handler] Failed copying file: $file - $($_.Exception.Message)"
                throw
            }
        }
        foreach ($dir in [System.IO.Directory]::GetDirectories($src)) {
            try {
                $destDir = [System.IO.Path]::Combine($dst, [System.IO.Path]::GetFileName($dir))
                Lightweight -source $dir -destination $destDir
            }
            catch {
                Write-ToLog "[Lightweight Handler] Failed copying directory: $dir - $($_.Exception.Message)"
                throw
            }
        }
    }
    catch {
        Write-ToLog "[Lightweight Handler] Copy failed: $($_.Exception.Message)"
        Write-ToLog $_.ScriptStackTrace
        throw
    }
}

function Heavyweight($target) {

    if ([string]::IsNullOrWhiteSpace($target)) {
        throw "[Heavyweight Handler] Received empty target path."
    }

    # normalize paths
    $targetFull = [IO.Path]::GetFullPath($target).TrimEnd('\')
    $backup     = [IO.Path]::GetFullPath($cfg.RecoveryDir).TrimEnd('\')
    $win        = [IO.Path]::GetFullPath([Environment]::GetFolderPath([Environment+SpecialFolder]::Windows))
    $base       = [IO.Path]::GetFullPath($cfg.BaseDir).TrimEnd('\')

    # block deleting backup folder or its contents
    if ($targetFull.Equals($backup, [StringComparison]::OrdinalIgnoreCase) -or
        $targetFull.StartsWith("$backup\", [StringComparison]::OrdinalIgnoreCase)) {
        Write-ToLog "[Heavyweight Handler] Blocked backup deletion: $targetFull"
        return
    }

    try {
        # block deleting Windows directory or anything inside it
        if (
            $targetFull.Equals($win, [StringComparison]::OrdinalIgnoreCase) -or
            $targetFull.StartsWith("$win\", [StringComparison]::OrdinalIgnoreCase)
        ) {
            Write-ToLog "[Heavyweight Handler] Blocked Windows path: $targetFull"
            return
        }

        # block deleting installer root
        if ($targetFull.Equals($base, [StringComparison]::OrdinalIgnoreCase)) {
            Write-ToLog "[Heavyweight Handler] Blocked installer root deletion."
            return
        }

        Write-ToLog "[Heavyweight Handler] Delete request: $targetFull"

        # check whitelist
        $allowed = $false
        foreach ($path in $cfg.AllowedDeletes) {
            $allowedFull = [IO.Path]::GetFullPath($path).TrimEnd('\')
            if (
                $targetFull.Equals($allowedFull, [StringComparison]::OrdinalIgnoreCase) -or
                $targetFull.StartsWith("$allowedFull\", [StringComparison]::OrdinalIgnoreCase)
            ) {
                $allowed = $true
                Write-ToLog "[Heavyweight Handler] Authorized deletion: $targetFull"
                break
            }
        }

        if (-not $allowed) {
            Write-ToLog "[Heavyweight Handler] Blocked unauthorized deletion: $targetFull"
            return
        }

        # nothing to delete
        if (-not (Test-Path -LiteralPath $target)) {
            Write-ToLog "[Heavyweight Handler] Nothing to remove: $targetFull"
            return
        }

        # clear attributes on all children
        Get-ChildItem -LiteralPath $target -Recurse -Force -ErrorAction Stop |
        ForEach-Object {
            try {
                [IO.File]::SetAttributes($_.FullName, [IO.FileAttributes]::Normal)
            }
            catch {
                throw "[Heavyweight Handler] Cannot clear attributes: $($_.FullName)"
            }
        }

        # clear attributes on root target
        [IO.File]::SetAttributes($targetFull, [IO.FileAttributes]::Normal)

        # delete file or directory
        $item = Get-Item $target -Force
        if ($item.PSIsContainer) {
            [IO.Directory]::Delete($item.FullName, $true)
        }
        else {
            [IO.File]::Delete($item.FullName)
        }

        Write-ToLog "[Heavyweight Handler] Deleted successfully: $targetFull"
    }
    catch {
        Write-ToLog "[Heavyweight Handler] Removing failed: $($_.Exception.Message)"
        Write-ToLog $_.ScriptStackTrace
        throw
    }
}

function ExtractAuto {
    param([string]$ZipPath, [string]$TargetName) # TargetName: binResources|db|gamedata

    $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
    $entries = $zip.Entries | ForEach-Object { $_.FullName }
    $zip.Dispose()

    $prefix = ""
    switch ($TargetName) {
        "binResources" {
            if ($entries -contains "AnomalyDX11.exe" -or $entries -contains "AnomalyDX11.pdb") {
                $prefix = ""            # flat zip
            } elseif ($entries -match "^bin/") {
                $prefix = "bin/"
            } else {
                # fallback: try to find any exe in root or bin
                if ($entries | Where-Object { $_ -match "AnomalyDX11" } ) { $prefix = "" }
            }
        }
        "db" {
            if ($entries -match "^db/") { $prefix = "db/" }
        }
        "gamedata" {
            $match = $entries | Where-Object { $_ -match "/gamedata/" } | Select-Object -First 1
            if ($match) {
                $prefix = ($match -split "/gamedata/")[0] + "/gamedata/"
            }
        }
    }

    $dest = Join-Path $cfg.ExtractDir $TargetName
    Extraction -ZipPath $ZipPath -Destination $dest -FilterPrefix $prefix
}

function Extraction {
    param(
        [string]$ZipPath,
        [string]$Destination,
        [string]$FilterPrefix
    )

    if (-not (Test-Path $ZipPath)) { throw "[Extraction Handler] Archive not found: $ZipPath" }
    if (-not (Test-Path $Destination)) { New-Item -ItemType Directory -Path $Destination -Force | Out-Null }

    $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)

    foreach ($entry in $zip.Entries) {
        
        # normalize prefix to use forward slashes
        $fp = if ($FilterPrefix) { $FilterPrefix.TrimStart('/') } else { "" }

        # if prefix provided, skip entries that don't start with it
        if ($fp -ne "" -and -not $entry.FullName.StartsWith($fp, [System.StringComparison]::OrdinalIgnoreCase)) { continue }

        # compute relative path by removing the exact prefix (if any)
        $relative = if ($fp -ne "") { $entry.FullName.Substring($fp.Length) } else { $entry.FullName }

        # trim any leading slashes and convert to Windows separators
        $relative = $relative.TrimStart('/') -replace '/', '\'

        if ([string]::IsNullOrWhiteSpace($relative)) { continue }

        $destPath = Join-Path $Destination $relative

        if ($entry.FullName.EndsWith("/")) {
            if (-not (Test-Path $destPath)) { New-Item -ItemType Directory -Path $destPath -Force | Out-Null }
            continue
        }

        $dir = Split-Path $destPath
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

        $entryStream = $entry.Open()
        try {
            $fileStream = [System.IO.File]::Create($destPath)
            $entryStream.CopyTo($fileStream)
        } finally {
            if ($null -ne $fileStream) { $fileStream.Dispose() }
            if ($null -ne $entryStream) { $entryStream.Dispose() }
        }
    }

    $zip.Dispose()
}

function TheRecovery {
$gamedataBackupIsEmpty = $false
Step "[Runtime Handler] Starting recovery (snapshot rollback)..."
if (-not (Test-Path (Join-Path $cfg.BaseDir "AnomalyLauncher.exe"))) {
    AnError "[Recovery Handler] This is NOT an Anomaly directory." -Hint "What do you even want to recover?"
    return
}
$savedgames = Join-Path $cfg.BaseDir "appdata\savedgames"
$gamedataPath   = Join-Path $cfg.BaseDir "gamedata"
$gamedataBackup = Join-Path $cfg.BaseDir "gamedata_old"
$snapSaved      = Join-Path $cfg.RecoveryDir "appdata\savedgames"
$snapUserLtx    = Join-Path $cfg.RecoveryDir "appdata\user.ltx"
$targetBin   = Join-Path $cfg.BaseDir "bin"
$targetExe   = Join-Path $targetBin "AnomalyDX11.exe"
$targetPdb   = Join-Path $targetBin "AnomalyDX11.pdb"
$backupExe   = Join-Path $cfg.recoveryDir "AnomalyDX11.exe"
$backupPdb   = Join-Path $cfg.recoveryDir "AnomalyDX11.pdb"
$recoveredSomething = $false
if (Test-Path $backupExe) {
    Copy-Item $backupExe $targetExe -Force
    Success "[Recovery Handler] Restored AnomalyDX11.exe from snapshot."
    $recoveredSomething = $true
}

if (Test-Path $gamedataBackup -PathType Container) {
    $content = Get-ChildItem $gamedataBackup -Force | Where-Object { $_.Name -notin @('.', '..') }
    if ($content.Count -eq 0) {
        Warning "[Recovery Handler] gamedata_old exists but is empty - skipping restore."
        $gamedataBackupIsEmpty = $true
    }
}

if (Test-Path $backupPdb) {
    Copy-Item $backupPdb $targetPdb -Force
    Success "[Recovery Handler] Restored AnomalyDX11.pdb from snapshot."
    $recoveredSomething = $true
}

if (-not (Test-Path $gamedataBackup) -and -not (Test-Path $gamedataPath)) {
    Warning "[Recovery Handler] No current gamedata or gamedata_old found - nothing to restore."
}
else {
    if (Test-Path $gamedataPath) {
        Step "[Recovery Handler] Removing current modded \gamedata..."
        try {
            Heavyweight $gamedataPath
            if (Test-Path $gamedataPath) {
                throw "[Recovery Handler] Failed removing current gamedata"
            }
        }
        catch {
            AnError "[Recovery Handler] Failed removing current \gamedata: $($_.Exception.Message)"
            return
        }
    }

    if (Test-Path $gamedataBackup -and -not $gamedataBackupIsEmpty) {
    Step "[Recovery Handler] Restoring \gamedata_old -> \gamedata"
    try {
        [System.IO.Directory]::Move($gamedataBackup, $gamedataPath)
        Success "[Recovery Handler] \gamedata restored successfully."
        $recoveredSomething = $true
    }
    catch {
        AnError "[Recovery Handler] Failed to restore \gamedata: $($_.Exception.Message)"
        return
    }
    }
    elseif (Test-Path $gamedataBackup -and $gamedataBackupIsEmpty) {
        Warning "[Recovery Handler] Skipped restoring empty gamedata_old."
    }
    else {
        Warning "[Recovery Handler] No \gamedata_old found - cannot restore oldinal gamedata."
    }
}

$dbArtifact = Join-Path $cfg.BaseDir "db\mods\00_modded_exes_gamedata.db0"
if (Test-Path $dbArtifact) {
    Step "[Recovery Handler] Removing modded \db file..."
    try {
        Heavyweight $dbArtifact
        Success "[Recovery Handler] \db mod artifact removed."
        $recoveredSomething = $true
    }
    catch {
        Warning "[Recovery Handler] Could not remove \db file (file in use?)."
    }
}

Step "[Recovery Handler] Cleaning installer working directories..."
foreach ($dir in @($cfg.SourceDir, $cfg.ExtractDir, $cfg.StagingDir)) {
    if (Test-Path $dir) {
        try {
            Heavyweight $dir
        }
        catch {
            Warning "[Recovery Handler] Failed to remove working directory: $dir"
        }
    }
}
$shaderCache = Join-Path $cfg.BaseDir "appdata\shaders_cache"
if (Test-Path $shaderCache) {
    try {
        Heavyweight $shaderCache
        Success "[Recovery Handler] \shaders_cache cleared."
        $recoveredSomething = $true
    }
    catch {
        Warning "[Recovery Handler] Could not clear \shaders_cache."
    }
}

Step "[Recovery Handler] Restoring user configs and savedgames..."
# restore savedgames (folder)
if (Test-Path $savedgames -PathType Leaf) {
    Heavyweight $savedgames
}

if (Test-Path $snapSaved) {
    Step "[Recovery Handler] Restoring savedgames..."
    if (Test-Path (Join-Path $cfg.BaseDir "appdata\savedgames")) {
        Heavyweight (Join-Path $cfg.BaseDir "appdata\savedgames")
    }
    try {
    Lightweight $snapSaved (Join-Path $cfg.BaseDir "appdata\savedgames")
    Success "[Recovery Handler] savedgames restored."
    $recoveredSomething = $true
    } catch {
    AnError "[Recovery Handler] Failed restoring savedgames: $($_.Exception.Message)"
    return
}
}

# restore user.ltx (file)
if (Test-Path $snapUserLtx) {
    Step "[Recovery Handler] Restoring user.ltx..."
    $dest = Join-Path $cfg.BaseDir "appdata\user.ltx"
    try {
    [IO.File]::SetAttributes($dest, [IO.FileAttributes]::Normal)
    } catch {}
    Copy-Item $snapUserLtx $dest -Force
    Success "[Recovery Handler] user.ltx restored."
    $recoveredSomething = $true
}

if ($recoveredSomething) {
    Success "[Recovery Handler] Recovery completed successfully."
}
else {
    Warning "[Recovery Handler] Recovery finished, but no files were actually restored (no matching snapshot content)."
}
}


function CreateSnapshot {
    Step "[Snapshot Handler] Creating snapshot in .recovery..."
    $binPath = Join-Path $cfg.BaseDir "bin"
    $snapBin = Join-Path $cfg.RecoveryDir "bin"
    if (Test-Path $snapBin) {
    Heavyweight $snapBin
    [void][System.IO.Directory]::CreateDirectory($snapBin)
}

    # ensure .recovery exists
    if (-not (Test-Path $cfg.RecoveryDir)) {
        [void][System.IO.Directory]::CreateDirectory($cfg.RecoveryDir)
    }

    # ensure snapshot/bin exists
    if (-not (Test-Path $snapBin)) {
        [void][System.IO.Directory]::CreateDirectory($snapBin)
    }

    # list of AOEngine files to backup
    $engineFiles = @(
        "AnomalyDX11.exe",
        "AnomalyDX11AVX.exe"
    )

    foreach ($file in $engineFiles) {
        $src = Join-Path $binPath $file
        $dst = Join-Path $snapBin $file

        if (Test-Path $src) {
            try {
                Copy-Item $src $dst -Force
                Success "[Snapshot Handler] Snapshot: $file"
            }
            catch {
                Warning "[Snapshot Handler] Could not snapshot $file"
            }
        }
    }

    # snapshot \savedgames + user.ltx
    $itemsToBackup = @(
        "appdata\savedgames",
        "appdata\user.ltx"
    )

    foreach ($item in $itemsToBackup) {
        $source = Join-Path $cfg.BaseDir $item
        $dest   = Join-Path $cfg.RecoveryDir $item

        if (Test-Path $source -PathType Container) {
            Lightweight $source $dest
            Success "[Snapshot Handler] Snapshot: $item"
        }
        elseif (Test-Path $source -PathType Leaf) {
            $destParent = Split-Path $dest -Parent
            if (-not (Test-Path $destParent)) {
                [void][System.IO.Directory]::CreateDirectory($destParent)
            }
            Copy-Item $source $dest -Force
            Success "[Snapshot Handler] Snapshot: $item"
        }
    }

    Write-ToLog "[Snapshot Handler] Snapshot created successfully."
    Success "[Snapshot Handler] Snapshot created successfully."
}



$ErrorActionPreference = if ($SilenceErrors) { 'SilentlyContinue' } else { 'Stop' }
Set-StrictMode -Off
Write-ToLog "AOEngine Online Installer started. Version: $($cfg.Version). Silent: $($cfg.IsSilent)."

try {
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

if ($Recovery) {
    try {
        TheRecovery
        exit 0
    }
    catch {
        AnError "[Recovery Handler] Recovery failed: $($_.Exception.Message)"
        exit 1
    }
}

# debug

#trap {
    #$ErrorActionPreference = "Continue"
    #$errorMessage = $_.Exception.Message
    #$failedLine = $_.InvocationInfo.ScriptLineNumber
    #$failedCmd = $_.InvocationInfo.MyCommand         
    #if ([string]::IsNullOrWhiteSpace($errorMessage)) { $errorMessage = $_.ToString() }
    #Error -text "Installation failed in line $failedLine ($failedCmd): $errorMessage" -Hint "To revert any partial changes, run the installer with: -Recovery"
    #Write-ToLog "Unhandled exception at line ${failedLine}: $errorMessage"
    #if (-not $cfg.IsSilent -and -not $SilenceErrors) { Wait-ForExit }
    #exit 1
#}

function Test-FileHash($file, $expectedHash) {
    if (-not [System.IO.File]::Exists($file)) { return $false }
    $stream = $null
    $sha256 = $null
    try {
        $stream = [System.IO.File]::OpenRead($file)
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $hashBytes = $sha256.ComputeHash($stream)
        $actual = [System.BitConverter]::ToString($hashBytes).Replace("-", "").ToUpper()
        return [string]::Equals($actual, $expectedHash, [StringComparison]::OrdinalIgnoreCase)
    } catch {
        return $false
    } finally {
        if ($null -ne $stream) { $stream.Dispose() }
        if ($null -ne $sha256) { $sha256.Dispose() }
    }
}

if ($Instructions -and -not $cfg.IsSilent) {
    Instructions
    Wait-ForExit
    exit 0
}

if ($TrustBanner -and -not $cfg.IsSilent) {
    TrustBanner
    Wait-ForExit
    exit 0
}

$launcherPath = Join-Path $cfg.BaseDir "AnomalyLauncher.exe"
if (-not [System.IO.File]::Exists($launcherPath)) {
    AnError "[Runtime Handler] This is NOT an Anomaly directory." -Hint "Make sure this installer is placed and executed inside your main Anomaly folder." 
    Wait-ForExit
    exit 1
}

$gameProcess = @("AnomalyLauncher","AnomalyDX11", "AnomalyDX10", "AnomalyDX9","AnomalyDX8", "AnomalyDX11AVX","AnomalyDX10AVX","AnomalyDX9AVX","AnomalyDX8AVX")
$runningGameName = $null
foreach ($procName in $gameProcess) {
    $processes = [System.Diagnostics.Process]::GetProcessesByName($procName)
    if ($processes.Count -gt 0) {
        $runningGameName = $procName
        foreach ($p in $processes) { $p.Dispose() }
        break
    }
} if ($null -ne $runningGameName) {
    AnError "[Runtime Handler] Game is already running." -Hint "Close ${runningGameName}.exe before continuing installation."
    Wait-ForExit
    exit 1
}

foreach ($folder in @("bin", "gamedata","db","appdata")) {
    $targetFolder = Join-Path $cfg.BaseDir $folder
    if (Test-Path -LiteralPath $targetFolder) {
        $testFile = Join-Path $targetFolder ".permission_test"
        $folderItem = Get-Item -LiteralPath $targetFolder -Force
        if ($folderItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
    AnError "[Runtime Handler] Folder '$folder' is a symlink/junction." -Hint "Installer does not support symlinked game directories."
    exit 1
            }
        try {
            # retry logic
            $ok = $false
            for ($i = 1; $i -le 3; $i++) {
                try {
                    [System.IO.File]::WriteAllText($testFile, "test")
                    $ok = $true
                    break
                } catch {
                    Start-Sleep -Milliseconds 200
                }
            }
            if (-not $ok) {
                throw "[Runtime Handler] Permission denied." 
            }
        } catch {
            AnError -text "[Runtime Handler] Folder '$folder' is locked by the system or another process." -Hint "This could be caused by MO2 running, an AV scan, or lack of Administrator rights."
            Wait-ForExit
            exit 1
        } finally {
            try { [System.IO.File]::Delete($testFile) } catch {}
        }
    }
}


$VersionText = "Version: $($cfg.Version)"
$Spaces = [math]::Max(0, [int]((104 - $VersionText.Length) / 2))

$asciiArt = @'
    ___  ____  ____          _              ____       ___              ____         __       ____      
   / _ |/ __ \/ __/__  ___ _(_)__  ___ ____/ __ \___  / (_)__  ___ ____/  _/__  ___ / /____ _/ / /__ ____
  / __ / /_/ / _// _ \/ _ `/ / _ \/ -_)___/ /_/ / _ \/ / / _ \/ -_)___// // _ \(_-</ __/ _ `/ / / -_) __/
 /_/ |_\____/___/_//_/\_, /_/_//_/\__/    \____/_//_/_/_/_//_/\__/   /___/_//_/___/\__/\_,_/_/_/\__/_/  
                     /___/                                                                              
                                              kamil_zeus, 2026.
'@

if (-not $cfg.IsSilent) {
    Clear-Host
    Info "========================================================================================================" -ForegroundColor White
    Info $asciiArt -ForegroundColor Cyan
    Info "========================================================================================================" -ForegroundColor White
    Info ""
    Info "This script will:" -ForegroundColor White
    Step "  Automatically download the latest AOEngine binaries and needed resources from the Web." 
    Step "  Backup your current \bin, \appdata\savedgames, and change the name for \gamedata to \gamedata_old." 
    Step "  Install AOEngine files to your Anomaly directory." 
    Info (" " * $Spaces + $VersionText)
    Info "========================================================================================================" -ForegroundColor White
    Info ""
}

$confirm = ""
if (-not $cfg.IsSilent) {
    $confirm = Read-Host "Press ENTER to begin installation (or type 'q' to quit)"
}
if ([string]$confirm.Trim().ToLower() -eq 'q') {
    AnError -text "Installation aborted." -Hint "Deployment cancelled by user request."
    Start-Sleep -Seconds 1
    exit
}

Step "[Runtime Handler] Preparing environment..."
if (Test-Path $cfg.SourceDir) { Heavyweight $cfg.SourceDir }
[void][System.IO.Directory]::CreateDirectory($cfg.SourceDir)
[System.IO.File]::SetAttributes($cfg.SourceDir, [System.IO.FileAttributes]::Hidden)

if (Test-Path $cfg.ExtractDir) { Heavyweight $cfg.ExtractDir }
[void][System.IO.Directory]::CreateDirectory($cfg.ExtractDir)
[System.IO.File]::SetAttributes($cfg.ExtractDir, [System.IO.FileAttributes]::Hidden)

#download'n'extract
$allDownloads = @(
    @{ Url = "https://drive.google.com/uc?export=download&id=1s3oGEwIB-LyZrKzKaI8AFZkjV5lFvh4p"; SearchedFolder = "binResources"; Hash ="91E16B2400C833A887F261ED57098814AC2042F0E71AC4C7F3C4A3AD405AECD5" }
    @{ Url = "https://github.com/themrdemonized/xray-monolith/releases/download/2025.8.31/STALKER-Anomaly-modded-exes_2025.8.31.zip"; SearchedFolder = "db"; Hash="194B41DBDCC8430540149B0FD4CFA1DAC0CC4FDC8CD38DE9BDE12131B7EB3604" }
    @{ Url = "https://github.com/themrdemonized/xray-monolith/archive/refs/tags/2025.8.31.zip"; SearchedFolder = "gamedata"; Hash="331C68872251FD7675B7C0D9927C07121B4DC06E254D8B37A67B90E3582DB6F5" }
)

if (-not $cfg.IsSilent) { $ProgressPreference = 'Continue' }

foreach ($file in $allDownloads) {
    if ($file.Url -match "drive.google.com") {
        $FileName = "AOEngine_Base.7z"
    } else {
        $FileName = [System.IO.Path]::GetFileName($file.Url) 
    }
    # regex link validation
    if ($file.Url -notmatch '^https://(?:drive\.google\.com|github\.com)/') {
        AnError "[Download Handler] Invalid source URL: $($file.Url)"
        Wait-ForExit; exit 1
    }
    $targetPath = Join-Path $cfg.sourceDir $FileName
    Step "[Download Handler] Downloading: $($FileName)..."
    $retryCount = 0
    $success = $false
    while (-not $success -and $retryCount -lt 3) {
        try {
            Invoke-WebRequest -Uri $file.Url -OutFile $targetPath -UserAgent "Mozilla/5.0" -ErrorAction Stop
            $success = $true
        } catch {
            Write-ToLog "[Download Handler] Download error: $($_.Exception.Message)"
            $retryCount++
            Warning "[Download Handler] Attempt $retryCount failed for $($FileName)"
            Write-ToLog "[Download Handler] Retry $retryCount for $FileName"
            if ($retryCount -lt 3) { Start-Sleep 5 }
        }
    }
    if ((Get-Item $targetPath).Length -eq 0) {
    throw "[Download Handler] Downloaded file is empty."
    }


    if (-not $success) {
        AnError -text "[Download Handler] Failed to download $($FileName) after 3 attempts." -Hint "Check your network connection, firewalls, or verify if the host links are still active."
        Wait-ForExit; exit 1
    }

    if ($file.Hash -and -not $GenerateHashes) {
        if (-not (Test-FileHash $targetPath $file.Hash)) {
            AnError -text "[Hash Check Handler] Hash verification mismatch on downloaded file!" -Hint "File: $($FileName) is corrupted or has been modified on the remote server."
            Wait-ForExit; exit 1
        }
        Success "[Hash Check Handler] Hash verified: $($FileName)"
    }

    # hash generating mode
    if ($GenerateHashes) {
        $hash = ""
        $stream = [System.IO.File]::OpenRead($targetPath)
        try {
            $sha256 = [System.Security.Cryptography.SHA256]::Create()
            $hashBytes = $sha256.ComputeHash($stream)
            $hash = [System.BitConverter]::ToString($hashBytes).Replace("-", "").ToUpper()
        } finally {
            $stream.Dispose()
        }
        $line = "$($FileName) | $hash"
        Write-ToLog $line
        if (-not $cfg.IsSilent) { 
            Write-Host $line -ForegroundColor Yellow 
        }
        if ([System.IO.File]::Exists($targetPath)) { [System.IO.File]::Delete($targetPath) }
        continue
    }

# prepare extraction folder
$tempExtract = Join-Path $cfg.ExtractDir $file.SearchedFolder
if (Test-Path $tempExtract) { Heavyweight $tempExtract }
[void][System.IO.Directory]::CreateDirectory($tempExtract)


# prefix for ZIP extraction
$prefix = switch ($file.SearchedFolder) {
    "binResources" { "" }
    "db"           { "db/" }
    "gamedata"     { "xray-monolith-2025.8.31/gamedata/" }
    default        { "" }
}

Step "[Extraction Handler] Extracting $($FileName)..."

# detect 7z magic bytes
$bytes = New-Object byte[] 4
$fs = [System.IO.File]::OpenRead($targetPath)
[void]$fs.Read($bytes, 0, 4)
$fs.Close()

$magic7z = ($bytes[0] -eq 0x37 -and $bytes[1] -eq 0x7A -and $bytes[2] -eq 0xBC -and $bytes[3] -eq 0xAF)

if ($magic7z) {
    # AOEngine Base 7z (store-only)
    $tarPath = Join-Path $env:SystemRoot "System32\tar.exe"
    & $tarPath -xf $targetPath -C $tempExtract *>&1 | Out-Null
}
else {
    # ZIP archive
    switch ($FileName) {

    "AOEngine_Base.7z" {
        ExtractAuto -ZipPath $targetPath -TargetName "binResources"
    }

    "STALKER-Anomaly-modded-exes_2025.8.31.zip" {
        ExtractAuto -ZipPath $targetPath -TargetName "db"
    }

    "2025.8.31.zip" {
        ExtractAuto -ZipPath $targetPath -TargetName "gamedata"
    }

    default {
        Warning "[Extraction Handler] Unknown archive: $($file.Name)"
    }
}
}

Success "[Extraction Handler] Extracted: $($file.SearchedFolder)"

# clear attributes
$allFileSystemItems = [System.IO.Directory]::GetFileSystemEntries($tempExtract, "*", [System.IO.SearchOption]::AllDirectories)
foreach ($item in $allFileSystemItems) {
    try {
        [System.IO.File]::SetAttributes($item, [System.IO.FileAttributes]::Normal)
    } catch {
        AnError -text "[Attributes Handler] Failed to update file attributes." -Hint "Could not clear security flags on file: $item. Ensure the file is not in use."
        Wait-ForExit; exit 1
    }
}
}

if ($GenerateHashes) {
    Warning "[Hash Handler] Hash generation completed. Exiting."
    Wait-ForExit
    exit 0
}

Success "[Installation Handler] All components downloaded and ready for install."

if (-not $NoBackup) {
    CreateSnapshot
}

# installation
Step "[Installation Handler] Preparing installation pipeline..."
$cfg.InstallationStarted = $true
$gdTarget = Get-CanonicalPath "gamedata"
$gdOld   = Get-CanonicalPath "gamedata_old"
if ([System.IO.Directory]::Exists($gdTarget)) {
    if ([System.IO.Directory]::Exists($gdOld)) {
        Warning "[Installation Handler] Found existing \gamedata_old. Current \gamedata is from a previous installation."
        Step "[Installation Handler] Cleaning up old modded \gamedata folder to free space..."
        Heavyweight $gdTarget
        [void][System.IO.Directory]::CreateDirectory($gdTarget)
    }
    else {
        Step "[Installation Handler] Preparing \gamedata backup (\gamedata -> \gamedata_old)..."
        Step "[Installation Handler] Renaming \gamedata -> \gamedata_old"
        [System.IO.Directory]::Move($gdTarget, $gdOld)
    }
}
$srcBin  = Join-Path $cfg.ExtractDir "binResources"
$srcDB   = Join-Path $cfg.ExtractDir "db"
$srcGD   = Join-Path $cfg.ExtractDir "gamedata"
if (-not (Test-Path $srcBin)) { throw "[Installation Handler] Missing \binResources source (binResources not extracted)" }
if (-not (Test-Path $srcDB))  { throw "[Installation Handler] Missing \db source" }
if (-not (Test-Path $srcGD))  { throw "[Installation Handler] Missing \gamedata source" }
Step "[Installation Handler] Updating AnomalyDX11 binaries..."
$targetBin   = Get-CanonicalPath "bin"
if (-not (Test-Path $targetBin)) {
    throw "[Installation Handler] Target \bin folder missing in Anomaly directory."
}
$targetExe   = Join-Path $targetBin "AnomalyDX11.exe"
$targetPdb   = Join-Path $targetBin "AnomalyDX11.pdb"
$stageExe    = Join-Path $srcBin "AnomalyDX11.exe"
$stagePdb    = Join-Path $srcBin "AnomalyDX11.pdb"
$backupExe   = Join-Path $cfg.RecoveryDir "AnomalyDX11.exe"
$backupPdb   = Join-Path $cfg.RecoveryDir "AnomalyDX11.pdb"
if (-not (Test-Path $stageExe)) {
    AnError "[Installation Handler] AOEngine DX11 EXE missing." -Hint "Archive may be corrupted or incomplete."
    Wait-ForExit; exit 1
}
if (-not (Test-Path $cfg.RecoveryDir)) {
    [void][System.IO.Directory]::CreateDirectory($cfg.RecoveryDir)
}
if (Test-Path $targetExe) { Copy-Item $targetExe $backupExe -Force }
if (Test-Path $targetPdb) { Copy-Item $targetPdb $backupPdb -Force }
Copy-Item $stageExe $targetExe -Force
if (Test-Path $stagePdb) {
    Copy-Item $stagePdb $targetPdb -Force
}
Success "[Installation Handler] AnomalyDX11.exe (+ .pdb if present) updated."
Step "[Installation Handler] Merging \db folder..."
$dbDst = Get-CanonicalPath "db"
Lightweight $srcDB $dbDst
Write-ToLog "[Installation Handler] Merged \db: $((Get-ChildItem $srcDB -Recurse).Count) files"
Success "[Installation Handler] \db merged."
Step "[Installation Handler] Installing new \gamedata (no overwrite policy)..."
$gdDst = Get-CanonicalPath "gamedata"
if (-not (Test-Path $gdDst)) {
    [void][System.IO.Directory]::CreateDirectory($gdDst)
}
if ([System.IO.Directory]::Exists($gdDst) -and (Get-ChildItem $gdDst -Force | Where-Object { -not $_.PSIsContainer })) {
    Warning "[Installation Handler] \gamedata already exists and is not empty (this should not happen after rename step). Cleaning..."
    Heavyweight $gdDst
    [void][System.IO.Directory]::CreateDirectory($gdDst)
}
Lightweight $srcGD $gdDst
Success "[Installation Handler] \gamedata installed safely."
Step "[Installation Handler] Final cleanup..."
Heavyweight $cfg.SourceDir
Heavyweight $cfg.ExtractDir
Heavyweight $cfg.StagingDir
Heavyweight (Get-CanonicalPath "appdata\shaders_cache")
if (-not $cfg.IsSilent) {
    Success "[Installation Handler] Installation complete."
    if (-not $NoBackup) {
        Warning "You can find your backups in: $($cfg.RecoveryDir)"
    } else {
        Warning "Backup was skipped as requested. (-NoBackup)"
    }
    Warning "For MO2 instructions, run this script again with the -i flag."
    Warning "They are ${ul}critical${reset} for the game to work properly."
    exit 0
}


} catch {
    $err = $_
    $msg = $err.Exception.Message
    if ([string]::IsNullOrWhiteSpace($msg)) { $msg = $err.ToString() }
    if ($Logging) {
        Write-ToLog "[The Creator's Handler] Unhandled exception!"
        Write-ToLog "[The Creator's Handler] Exception Type: $($err.Exception.GetType().FullName)"
        Write-ToLog "[The Creator's Handler] Inner Exception: $($err.Exception.InnerException)"
        Write-ToLog ($err | Out-String)
    }
    AnError -text "[The Creator's Handler] Installation failed: $msg" -Hint "To revert any partial changes, run the installer with: -Recovery"
    if (-not $cfg.IsSilent -and -not $SilenceErrors) { Wait-ForExit }
    exit 1
}