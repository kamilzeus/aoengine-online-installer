<#
.SYNOPSIS
    AOEngine-Online-Installer - Automated deployment for the AOEngine project.
    
.AUTHOR
    kamil_zeus
    
.VERSION
    1.5.1.3
    
.LICENSE
    Script made by kamil_zeus (kamil_zeus on Discord).
    DO NOT REMOVE THIS HEADER. Modification is allowed, but attribution is mandatory.
#>

# 1. Drop this file into your main Anomaly folder.
# 2. Right-click inside the folder -> "Open in Terminal" (or open PowerShell there).
# 3. If your windows doesn't let you launch it, copy-paste this exact command and hit ENTER:
#
#    powershell -ExecutionPolicy Bypass -File .\AOEngine-Online-Installer.ps1
#
# 4. Do absolutely nothing, walk away from your PC, make some tea or whatever you like to drink. At the end, READ THE INSTRUCTIONS and APPLY THEM!
# 5. If your computer starts to let out strange beeps, it's not that new spiritus.

# mock dirs generator
# ========================================================================================================
# for testing in an empty folder, uncomment lines below

 #if (!(Test-Path "AnomalyLauncher.exe")) { New-Item -ItemType File -Path "AnomalyLauncher.exe" -Force | Out-Null }
 #$mockFolders = @("bin", "appdata\savedgames", "gamedata")
 #foreach ($f in $mockFolders) { if (!(Test-Path $f)) { New-Item -ItemType Directory -Path $f -Force | Out-Null } }
 #if (!(Test-Path "appdata\user.ltx")) { Set-Content -Path "appdata\user.ltx" -Value "unbind_all`nbind forward kW" -Force }
 #if (!(Test-Path "appdata\savedgames\swamps_50h.scop")) { Set-Content -Path "appdata\savedgames\swamps_50h.scop" -Value "savefile data" -Force }
 #if (!(Test-Path "bin\Anomaly_DX11.exe")) { Set-Content -Path "bin\Anomaly_DX11.exe" -Value "binary data" -Force }
 #Write-Host "[!] Mock environment active: Simulated base files generated for testing."

# ========================================================================================================

Function Out-Step {
    param([string]$text)
    Write-Host "[>] $text" -ForegroundColor Cyan
    [Console]::Beep(2200, 20)
}
Function Out-Success {
    param([string]$text)
    Write-Host "[+] $text" -ForegroundColor Green
    [Console]::Beep(1000, 250)
}

Function Out-Warning {
    param([string]$text)
    Write-Host "[!] $text" -ForegroundColor Yellow
    [Console]::Beep(500, 400)
}

Function Out-Error {
    param([string]$text)
    Write-Host "[X] $text" -ForegroundColor Red
    [Console]::Beep(300, 600)
}
Function Assert-DeploymentStage {
    $local:target = ($global:Session_Offset -join "")
    $local:current = $global:rcheck1 + $global:rcheck2 + $global:rcheck3 + $global:rcheck4 + $global:rcheck5 
    if ($local:current -ne $local:target) { 
        Write-Host "========================================================================================================" -ForegroundColor Red
        Out-Error "Script has been tampered with! This is not an authorized copy."
        Out-Warning "Message me on Discord for a proper pull request or if you have any problems (kamil_zeus)."
        Write-Host "========================================================================================================" -ForegroundColor Red
        Read-Host "Press ENTER to exit"
        exit 
    }
}

Start-Transcript -Path "AOEOI_Log.txt" -Append -Force

# early environment and system age validation
Out-Step "Initializing AOEngine deployment pipeline..."
Start-Sleep -Milliseconds 500

Out-Step "Checking if your system is ancient (searching for tar.exe)..."
Start-Sleep -Milliseconds 600

# tar validation - i respect murphy's law
if (!(Get-Command "tar" -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "========================================================================================================" -ForegroundColor Red
    Out-Error "Your Windows is missing 'tar.exe' utility!"
    Out-Warning "This script requires modern Windows (Win 10 1803+ or Win 11) to extract files."
    Write-Host "========================================================================================================" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press ENTER to exit"
    exit
}

# path and folder integrity check
Out-Step "Verifying target environment..."
$baseDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }
$global:Session_Offset = @("13-", "ZEUS-", "37-", "AO-", "ENG")
Start-Sleep -Milliseconds 400

# anomaly folder validation
$launcherPath = Join-Path $baseDir "AnomalyLauncher.exe"
if (!(Test-Path $launcherPath)) {
    Write-Host ""
    Write-Host "========================================================================================================" -ForegroundColor Red
    Out-Error "This is NOT an Anomaly directory."
    Out-Warning "Make sure this installer is placed and executed inside your main Anomaly folder." 
    Write-Host "========================================================================================================" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press ENTER to exit"
    exit
}

# i respect murphy's law even more
$gameProcess = "AnomalyDX11" 
if (Get-Process -Name $gameProcess -ErrorAction SilentlyContinue) {
    Write-Host ""
    Write-Host "========================================================================================================" -ForegroundColor Red
    Out-Error "Game is already running. Impossible to proceed further."
    Out-Warning "Close the $gameProcess and try again."
    Write-Host "========================================================================================================" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press ENTER to exit"
    exit
}

# interface
$asciiArt = @'
   ___  ____  ____          _              ____       ___              ____         __       ____       
  / _ |/ __ \/ __/__  ___ _(_)__  ___ ____/ __ \___  / (_)__  ___ ____/  _/__  ___ / /____ _/ / /__ ____
 / __ / /_/ / _// _ \/ _ `/ / _ \/ -_)___/ /_/ / _ \/ / / _ \/ -_)___// // _ \(_-</ __/ _ `/ / / -_) __/
/_/ |_\____/___/_//_/\_, /_/_//_/\__/    \____/_//_/_/_/_//_/\__/   /___/_//_/___/\__/\_,_/_/_/\__/_/   
                    /___/                                                                              
                                        kamil_zeus, 2026. 
'@
    Clear-Host
    Write-Host "========================================================================================================" -ForegroundColor White
    Write-Host $asciiArt -ForegroundColor Cyan
    Write-Host "========================================================================================================" -ForegroundColor White
    Write-Host ""
    Write-Host "This script will:" -ForegroundColor White
    Out-Step "  Automatically download the latest AOEngine binaries and needed resources from the Web." 
    Out-Step "  Backup your current \bin, \appdata\savedgames(saves), and change the name for \gamedata to \gamedata_orig." 
    Out-Step "  Install AOEngine files to your Anomaly directory." 
    Write-Host ""
    Write-Host "========================================================================================================" -ForegroundColor White
    Write-Host ""

$confirm = Read-Host "Press ENTER to begin installation (or type 'q' to quit)"

if ($confirm.Trim().ToLower() -eq 'q') {
    Out-Error "Installation aborted."
    Start-Sleep -Seconds 2
    exit
}

    $checkOffset = Get-Variable "Session_Offset" -Scope Global -ErrorAction SilentlyContinue
if (-not $checkOffset -or ($checkOffset.Value -join "").Length -ne 21) {
        Write-Host "========================================================================================================" -ForegroundColor Red
        Out-Error "Configuration missing. Script have been tampered with."
        Out-Warning "Message me on Discord (kamil_zeus)."
        Write-Host "========================================================================================================" -ForegroundColor Red
        exit
    }

# download'n'extract
$sourceDir = Join-Path $baseDir "AOEngineNeeded" 
if (!(Test-Path $sourceDir)) {
    Out-Step "Folder 'AOEngineNeeded' not found. Preparing automatic download..." 
    New-Item -ItemType Directory -Path $sourceDir | Out-Null
    
    # iwr has hard time with google drive, so it is how it is, but it works
    $allDownloads = @(
        @{ Url = "https://drive.google.com/uc?export=download&id=1s3oGEwIB-LyZrKzKaI8AFZkjV5lFvh4p"; Output = "AOEngine_Base.zip"; SearchedFolder = "binResources" }
        @{ Url = "https://github.com/themrdemonized/xray-monolith/releases/download/2025.8.31/STALKER-Anomaly-modded-exes_2025.8.31.zip"; Output = "STALKER-Anomaly-modded-exes_2025.8.31.zip"; SearchedFolder = "db" }
        @{ Url = "https://github.com/themrdemonized/xray-monolith/archive/refs/tags/2025.8.31.zip"; Output = "xray-monolith-2025.8.31.zip"; SearchedFolder = "gamedata" }
    )
    $ProgressPreference = 'Continue'
    foreach ($file in $allDownloads) {
        $targetPath = Join-Path $sourceDir $file.Output
        Out-Step "Downloading: $($file.Output)..." 
        try {
            Invoke-WebRequest -Uri $file.Url -OutFile $targetPath -UserAgent "Mozilla/5.0"
            Out-Success "Successfully downloaded $($file.Output)."
        }
        catch {
            Out-Error "Failed to download $($file.Output)." 
            continue
        }
        $tempExtract = Join-Path $sourceDir "temp_extract"
        if (!(Test-Path $tempExtract)) { New-Item -ItemType Directory -Path $tempExtract | Out-Null }
        Out-Step "Extracting $($file.Output) using tar.exe..." 
        tar -xf $targetPath -C $tempExtract
        
        if ($file.SearchedFolder -eq "binResources") {
            $destinationFolder = Join-Path $sourceDir "bin"
            if (!(Test-Path $destinationFolder)) { New-Item -ItemType Directory -Path $destinationFolder | Out-Null }
            Get-ChildItem -Path $tempExtract -File | Move-Item -Destination $destinationFolder -Force
            Out-Success "Successfully moved binaries into 'AOEngineNeeded\bin' folder." 
            
        } else {
            Out-Step "Searching for folder: '$($file.SearchedFolder)'..." 
            $foundFolder = Get-ChildItem -Path $tempExtract -Recurse -Directory | Where-Object { $_.Name -eq $file.SearchedFolder } | Select-Object -First 1
            if ($foundFolder) {
                $destinationFolder = Join-Path $sourceDir $file.SearchedFolder
                Move-Item -Path $foundFolder.FullName -Destination $destinationFolder -Force
                Out-Success "Successfully extracted: $($file.SearchedFolder)" 
            } else {
                Out-Error "Couldn't find '$($file.SearchedFolder)' folder inside the downloaded zip." 
            }
        }

        Start-Sleep -Seconds 1

        Remove-Item $targetPath -Force -Confirm:$false
        if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force -Confirm:$false }
        Out-Success "Cleaned up temporary files for $($file.Output)."
        Write-Host "========================================================================================================" -ForegroundColor White
    }
    $global:rcheck1 = "13-"
    $global:rcheck4 = "AO-" 
    Out-Success "All components downloaded and ready for install." 
} else {
    Out-Warning "Found existing 'AOEngineNeeded' folder, skipping download. Better delete it and start all over again."
    $global:rcheck1 = "13-"
    $global:rcheck4 = "AO-"
}
# backup processing
$backupDir = Join-Path $baseDir "backup of overwritten files"
if (!(Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
Out-Step "Backing up crucial files to: $backupDir" 
$itemsToBackup = @("bin", "appdata\savedgames","appdata\user.ltx")
$totalItems = $itemsToBackup.Count
$i = 0
foreach ($item in $itemsToBackup) {
    $i++
    Write-Progress -Activity "Backing up your files" -Status "Currently backing up: $item" -PercentComplete (($i / $totalItems) * 100)
    $itemPath = Join-Path $baseDir $item
    if (Test-Path $itemPath) {
        $destPath = Join-Path $backupDir $item
        $destParent = Split-Path $destPath -Parent
        if (!(Test-Path $destParent)) { New-Item -ItemType Directory -Path $destParent | Out-Null }
        
        Copy-Item -Path $itemPath -Destination $destPath -Recurse -Force
        Out-Success "Backed up: $item"
    }
}
    $global:rcheck2 = "ZEUS-"
    Write-Progress -Activity "Backing up your files" -Completed

# installation processing
Out-Step "Installing AOEngine binaries and needed resources..."
$steps = @("bin", "db", "gamedata", "shaders_cache")
$totalSteps = $steps.Count
$currentStep = 0
$foldersToUpdate = @("bin", "db")

foreach ($folder in $foldersToUpdate) {
    $currentStep++
    Write-Progress -Activity "Installing AOEngine" -Status "Installing: $folder" -PercentComplete (($currentStep / $totalSteps) * 100)
    $srcPath = Join-Path $sourceDir $folder
    $destPath = Join-Path $baseDir $folder
    if (Test-Path $srcPath) {
        if (!(Test-Path $destPath)) { New-Item -ItemType Directory -Path $destPath | Out-Null }
        Copy-Item -Path $srcPath -Destination $baseDir -Recurse -Force
        Out-Success "Overwritten: $folder"
    }
}
$global:rcheck3 = "37-"

$currentStep++
Write-Progress -Activity "Installing AOEngine" -Status "Configuring: gamedata" -PercentComplete (($currentStep / $totalSteps) * 100)
$gamedataPath = Join-Path $baseDir "gamedata"
$gamedataOrigPath = Join-Path $baseDir "gamedata_orig"
$srcGamedata = Join-Path $sourceDir "gamedata"

if (Test-Path $srcGamedata) {
    if (Test-Path $gamedataPath) {
        if (Test-Path $gamedataOrigPath) { Remove-Item $gamedataOrigPath -Recurse -Force -Confirm:$false }
        Rename-Item -Path $gamedataPath -NewName "gamedata_orig"
        Out-Success "Renamed existing 'gamedata' to 'gamedata_orig'."
    }
    Copy-Item -Path $srcGamedata -Destination $baseDir -Recurse -Force
    Out-Success "Installed new 'gamedata' folder"
}

$currentStep++
Write-Progress -Activity "Installing AOEngine" -Status "Deleting shader cache..." -PercentComplete (($currentStep / $totalSteps) * 100)
$cachePath = Join-Path $baseDir "appdata\shaders_cache"
$global:rcheck5 = "ENG"
Assert-DeploymentStage
if (Test-Path $cachePath) {
    Remove-Item -Path $cachePath -Recurse -Force -Confirm:$false
    Out-Success "Deleted 'shaders_cache'."
}

Write-Host ""
Out-Step "Cleaning up installation files..."

if (Test-Path $sourceDir) {
    Remove-Item -Path $sourceDir -Recurse -Force -Confirm:$false
    Out-Success "Folder 'AOEngineNeeded' has been removed."
}

Write-Progress -Activity "Installing AOEngine" -Completed

# finalizing and tutorial for MO2
Out-Success "Installation complete!" 
Out-Warning "You can find your backups in: $backupDir"
Write-Host ""
Out-Warning "Don't close the installer just yet!"
Write-Host ""
Write-Host "Now, there are things you need to do in MO2."
Out-Warning "Enable '236- 1st Person Visible Body Ported from SWM - Wang_Laoshi & SWM Team' ."
Out-Step  "Then in the main menu of the game, go to MCM Settings -> SWM Visible Body -> Scroll to the very bottom ->  Make sure that the last item 'Remove body' is unchecked."
Out-Warning  "Reinstall '190- Screen Space Shaders 23 - Ascii1457' by unchecking:"
Out-Step  "51 - PostProcess - BLOOM  (Causes visual problems.)"
Out-Step  "04 - SSR Water Ice Version (Unless you use winter mod.)"
Out-Step  "10- Wind [Optional] Vanilla Emission"
Out-Step  "991- Extra Laser+ [BaS] (When turned on, lasers are not visible.)"
Out-Step  "992 - Detectors+ [Vanilla]"
Out-Step  "MANUAL INSTALLATION - MODDED EXE"
Write-Host ""
Out-Warning "Waiting 5 seconds to ensure you read the instructions above..." 
Start-Sleep -Seconds 5
Read-Host "Press ENTER to exit"
