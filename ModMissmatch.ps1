
$TestMode = $false

$ModLists = @(
    @{ Name = "Lunar"; Url = "https://steamcommunity.com/sharedfiles/filedetails/?id=3320591539" },
    @{ Name = "Vinlark"; Url = "https://steamcommunity.com/sharedfiles/filedetails/?id=3619129132" },
    @{ Name = "Reborn"; Url = "https://steamcommunity.com/sharedfiles/filedetails/?id=3693245779" }
)

$CustomArkModsPath = ""
$CustomSteamExeLocation = ""
$OpenSubscriptionsPage = $true


Write-Host "======================================================" -ForegroundColor Cyan
Write-Host " ARK: Survival Evolved - Mod Version Mismatch Resolver" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

if ($TestMode) {
    Write-Host ">>> TEST MODE ENABLED - NO FILES WILL BE DELETED <<<" -ForegroundColor Yellow -BackgroundColor Red
    Write-Host ""
}

$WorkshopCollectionUrl = ""
while ([string]::IsNullOrWhiteSpace($WorkshopCollectionUrl)) {
    Write-Host "Please select a ModList to load:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $ModLists.Count; $i++) {
        Write-Host "  [$($i + 1)] $($ModLists[$i].Name)" -ForegroundColor White
    }
    Write-Host "  [X] Exit" -ForegroundColor Red
    
    $choice = Read-Host ">>> Selection"
    
    if ($choice -eq "X" -or $choice -eq "x") {
        Write-Host "Exiting..." -ForegroundColor Red
        exit
    }
    $index = 0
    if ([int]::TryParse($choice, [ref]$index) -and $index -gt 0 -and $index -le $ModLists.Count) {
        $selectedMod = $ModLists[$index - 1]
        $WorkshopCollectionUrl = $selectedMod.Url
        Write-Host "[+] Selected: $($selectedMod.Name)" -ForegroundColor Green
    }
    else {
        Write-Host "[-] Invalid selection. Please try again." -ForegroundColor Red
    }
    Write-Host ""
}

function Wait-UserConfirmation([string]$Message) {
    Write-Host ""
    Write-Host "--> $Message" -ForegroundColor Magenta
    $null = Read-Host ">>> Press ENTER to continue..."
}

Wait-UserConfirmation "Step 1: Check and close ARK. Please manually close the game, or let the script attempt to force-close it."


$gameProcess = Get-Process -Name "ShooterGame", "ShooterGame_BE" -ErrorAction SilentlyContinue
if ($gameProcess) {
    Write-Host "[*] Closing ARK..." -ForegroundColor Yellow
    $gameProcess | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host "[+] ARK closed successfully (or attempted)." -ForegroundColor Green
}
else {
    Write-Host "[-] ARK is not running." -ForegroundColor DarkGray
}

$steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -Name "SteamPath" -ErrorAction SilentlyContinue).SteamPath
if ($null -ne $steamPath) {
    $steamPath = $steamPath -replace '/', '\'
}

$runningSteamExe = ""
if (-not [string]::IsNullOrWhiteSpace($CustomSteamExeLocation) -and (Test-Path $CustomSteamExeLocation)) {
    $runningSteamExe = $CustomSteamExeLocation
}
elseif ($steamPath) {
    $runningSteamExe = Join-Path -Path $steamPath -ChildPath "steam.exe"
}

if ($OpenSubscriptionsPage) {
    Wait-UserConfirmation "Step 2: Open 'Subscribed Items' in Steam so you can click 'Unsubscribe From All'."
    $steamProcess = Get-Process -Name "steam" -ErrorAction SilentlyContinue
    if (-not $steamProcess -and -not [string]::IsNullOrWhiteSpace($runningSteamExe)) {
        Start-Process -FilePath $runningSteamExe
        Wait-UserConfirmation "Steam needs to open. If Steam asks you to log in, please do so now. Press ENTER ONLY when you are completely logged into Steam."
    }
    
    Write-Host "[+] Opening 'Subscribed Items' in Steam..." -ForegroundColor Cyan
    Start-Process "steam://openurl/https://steamcommunity.com/my/myworkshopfiles/?appid=346110&browsefilter=mysubscriptions"
    
    Write-Host "==========================================================" -ForegroundColor Red
    Write-Host ">>> PLEASE CLICK 'Unsubscribe From All' IN STEAM NOW!  <<<" -ForegroundColor Red
    Write-Host "==========================================================" -ForegroundColor Red
    Wait-UserConfirmation "Once you have successfully clicked Unsubscribe From All, press ENTER."
}

Wait-UserConfirmation "Step 3: Close Steam. This releases Steam's lock on the local mod files."

$steamProcess = Get-Process -Name "steam" -ErrorAction SilentlyContinue
if ($steamProcess) {
    Write-Host "[*] Closing Steam..." -ForegroundColor Yellow
    Stop-Process -Name "steam" -Force
    Start-Sleep -Seconds 3
    Write-Host "[+] Steam closed successfully." -ForegroundColor Green
}
else {
    Write-Host "[-] Steam is already closed." -ForegroundColor DarkGray
}

Wait-UserConfirmation "Step 4: Locate ARK installation and delete corrupted workshop mod files."

Write-Host "[*] Locating ARK installation..." -ForegroundColor Cyan

$arkModPath = ""
$workshopPath = ""

if (-not [string]::IsNullOrWhiteSpace($CustomArkModsPath)) {
    $arkModPath = $CustomArkModsPath
    Write-Host "[*] Using custom ARK Mods path from configuration..." -ForegroundColor Cyan
}
else {
    if ($null -ne $steamPath) {
        $libraryFoldersFile = Join-Path -Path $steamPath -ChildPath "steamapps\libraryfolders.vdf"
        $arkPath = ""
        
        if (Test-Path $libraryFoldersFile) {
            $content = Get-Content $libraryFoldersFile
            $currentPath = ""
            foreach ($line in $content) {
                if ($line -match '"path"\s+"([^"]+)"') {
                    $currentPath = $matches[1] -replace '\\\\', '\'
                }
                if ($line -match '"346110"') { 
                    $arkPath = Join-Path -Path $currentPath -ChildPath "steamapps\common\ARK"
                    $workshopPath = Join-Path -Path $currentPath -ChildPath "steamapps\workshop\content\346110"
                    break
                }
            }
        }
        if ([string]::IsNullOrEmpty($arkPath) -and (Test-Path -Path "C:\Program Files (x86)\Steam\steamapps\common\ARK")) {
            $arkPath = "C:\Program Files (x86)\Steam\steamapps\common\ARK"
            $workshopPath = "C:\Program Files (x86)\Steam\steamapps\workshop\content\346110"
        }

        if ($arkPath -and (Test-Path $arkPath)) {
            $arkModPath = Join-Path -Path $arkPath -ChildPath "ShooterGame\Content\Mods"
        }
    }
}

if (-not [string]::IsNullOrWhiteSpace($arkModPath) -and (Test-Path $arkModPath)) {
    Write-Host "[+] Found ARK Mods path: $arkModPath" -ForegroundColor Green
    Write-Host "[*] Scanning game directory for mod files (numbered folders and .mod files)..." -ForegroundColor Yellow
    
    $modFolders = Get-ChildItem -Path $arkModPath -Directory | Where-Object { $_.Name -match '^\d+$' }
    $modFiles = Get-ChildItem -Path $arkModPath -File | Where-Object { $_.Name -match '^\d+\.mod$' }
            
    $totalDeleted = 0
            
    foreach ($folder in $modFolders) {
        Write-Host "    - Deleting Mod Folder: $($folder.Name)" -ForegroundColor DarkGray
        if (-not $TestMode) {
            Remove-Item -Path $folder.FullName -Recurse -Force
        }
        $totalDeleted++
    }
            
    foreach ($file in $modFiles) {
        if (-not $TestMode) {
            Remove-Item -Path $file.FullName -Force
        }
    }
            
    if ($totalDeleted -gt 0) {
        $msgSuffix = if ($TestMode) { "(SIMULATED)" } else { "" }
        Write-Host "[+] Successfully deleted $totalDeleted mod(s) from game folder $msgSuffix." -ForegroundColor Green
    }
    else {
        Write-Host "[+] No numbered mods found to delete in game folder." -ForegroundColor Green
    }
}

if (-not [string]::IsNullOrWhiteSpace($workshopPath) -and (Test-Path $workshopPath)) {
    Write-Host "[+] Found Steam Workshop cache path: $workshopPath" -ForegroundColor Green
    Write-Host "[*] Scanning workshop cache for downloaded mod files..." -ForegroundColor Yellow
    
    $workshopFolders = Get-ChildItem -Path $workshopPath -Directory
    $workshopDeleted = 0
    
    foreach ($folder in $workshopFolders) {
        Write-Host "    - Deleting Workshop Cache: $($folder.Name)" -ForegroundColor DarkGray
        if (-not $TestMode) {
            Remove-Item -Path $folder.FullName -Recurse -Force
        }
        $workshopDeleted++
    }
    
    if ($workshopDeleted -gt 0) {
        $msgSuffix = if ($TestMode) { "(SIMULATED)" } else { "" }
        Write-Host "[+] Successfully deleted $workshopDeleted item(s) from workshop cache $msgSuffix." -ForegroundColor Green
    }
    else {
        Write-Host "[+] Workshop cache is already empty." -ForegroundColor Green
    }
}
else {
    Write-Host "[-] Could not find ARK installation directory or custom path is invalid." -ForegroundColor Red
    Write-Host "[-] Please edit the configuration at the top of the script if it continues to fail." -ForegroundColor Red
}

Wait-UserConfirmation "Step 5: Re-open Steam. After pressing ENTER, please wait for Steam to fully launch."

Write-Host "[*] Re-opening Steam..." -ForegroundColor Cyan

if (-not [string]::IsNullOrWhiteSpace($runningSteamExe) -and (Test-Path $runningSteamExe)) {
    Start-Process -FilePath $runningSteamExe
    Write-Host "[+] Steam is starting." -ForegroundColor Green
    
    if (-not [string]::IsNullOrWhiteSpace($WorkshopCollectionUrl)) {
        Wait-UserConfirmation "If Steam asks you to log in, please do so now. Press ENTER ONLY when you are completely logged into Steam."
        
        Wait-UserConfirmation "Step 6: Tell Steam to open the Server ModList."
        $openUrl = $WorkshopCollectionUrl
        if (-not $openUrl.StartsWith("steam://openurl/")) {
            $openUrl = "steam://openurl/" + $openUrl
        }
        Write-Host "[+] Opening Workshop Collection in Steam..." -ForegroundColor Cyan
        Start-Process $openUrl
    }
    
    Write-Host ""
    Write-Host "--> Please click 'Subscribe to all' in Steam and wait for them to finish downloading before starting ARK again!" -ForegroundColor Yellow
}
else {
    Write-Host "[-] Could not automatically start Steam. Please start Steam manually or set CustomSteamExeLocation in the script." -ForegroundColor Yellow
}

Wait-UserConfirmation "All steps are complete. The script will now close."
