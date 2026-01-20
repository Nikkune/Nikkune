# ==============================
# 🚀 New PC Setup Script for Unattended Deployment (Optimized)
# Author: Nikkune
# Version: 1.3
# ==============================

# --- Enable TLS for secure downloads ---
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- Start transcript (logs) ---
$LogPath = "C:\Setup\install_log.txt"
Start-Transcript -Path $LogPath -Append
Write-Host "🧾 Logging installation to $LogPath"

# --- Create folder structure ---
Write-Host "📁 Creating folder structure..."
$folders = @(
    "S:\Languages",
    "S:\Languages\Java\8",
    "S:\Languages\Java\11",
    "S:\Languages\Java\17",
    "S:\Languages\Java\21",
    "S:\Languages\Java\25",
    "S:\IDE",
    "S:\IDE\JetBrains",
    "S:\Games_Launchers"
)
foreach ($f in $folders) {
    if (-not (Test-Path $f)) {
        New-Item -Path $f -ItemType Directory | Out-Null
        Write-Host "Created folder: $f"
    }
}

# --- Install Chocolatey silently ---
Write-Host "🍫 Installing Chocolatey..."
Set-ExecutionPolicy Bypass -Scope Process -Force
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# --- Reload PATH so choco is available immediately ---
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

# --- Helper function for safe execution ---
Function Safe-Run($Command) {
    Try {
        Invoke-Expression $Command
    } Catch {
        Write-Host "⚠️ Error executing: $Command" -ForegroundColor Yellow
    }
}

# --- Define app groups ---
$no_locations_apps = @("Discord.Discord")
$jetbrains_ide = @("JetBrains.CLion","JetBrains.IntelliJIDEA.Ultimate","JetBrains.PHPStorm","JetBrains.PyCharm.Professional","JetBrains.WebStorm")
$other_ide = @("Microsoft.VisualStudioCode")
$games_launchers = @("PrismLauncher.PrismLauncher","Valve.Steam")
$apps = @("KeePassXCTeam.KeePassXC","Klocman.BulkCrapUninstaller","Brave.Brave","Elgato.StreamDeck","voidtools.Everything","Flow-Launcher.Flow-Launcher","Git.Git","MongoDB.Compass.Full","Notepad++.Notepad++","TechPowerUp.NVCleanstall","Postman.Postman","Microsoft.PowerToys","qBittorrent.qBittorrent","StartIsBack.StartAllBack","VideoLAN.VLC","Voicemod.Voicemod","WeMod.WeMod","GnuPG.Gpg4win","chrisant996.Clink")
$languages = @("Python.Python","OpenJS.NodeJS")
$java_versions = @("8","11","17","21","25")

# --- Update Winget sources ---
Write-Host "🔄 Updating Winget sources..."
Safe-Run "winget source update"

# --- Function for Winget installs ---
Function Install-WingetApp ($appId, $location) {
    Write-Host "➡️ Installing $appId..."
    Try {
        if ($location) {
            winget install --id=$appId --silent --accept-package-agreements --accept-source-agreements --location $location
        } else {
            winget install --id=$appId --silent --accept-package-agreements --accept-source-agreements
        }
    } Catch {
        Write-Host "⚠️ Failed to install $appId" -ForegroundColor Yellow
    }
}

# --- 1️⃣ Apps without location ---
Write-Host "🌐 Installing apps without custom location..."
foreach ($app in $no_locations_apps) { Install-WingetApp $app $null }

# --- 2️⃣ General apps → S:\ ---
Write-Host "🌐 Installing general apps..."
foreach ($app in $apps) { Install-WingetApp $app "S:\" }

# --- 3️⃣ JetBrains IDE → S:\IDE\JetBrains ---
Write-Host "🧠 Installing JetBrains suite..."
foreach ($ide in $jetbrains_ide) { Install-WingetApp $ide "S:\IDE\JetBrains" }

# --- 4️⃣ Other IDE → S:\IDE ---
Write-Host "🧰 Installing other IDEs..."
foreach ($ide in $other_ide) { Install-WingetApp $ide "S:\IDE" }

# --- 5️⃣ Games launchers → S:\Games_Launchers ---
Write-Host "🎮 Installing game launchers..."
foreach ($game in $games_launchers) { Install-WingetApp $game "S:\Games_Launchers" }

# --- 6️⃣ Languages → S:\Languages ---
Write-Host "🌐 Installing programming languages..."
foreach ($lang in $languages) { Install-WingetApp $lang "S:\Languages" }

# --- 7️⃣ Java (Temurin) ---
Write-Host "☕ Installing Java versions via Temurin..."
foreach ($vers in $java_versions) {
    $path = "S:\Languages\Java\$vers"
    Write-Host "➡️ Installing Java $vers to $path..."
    Safe-Run "choco install temurin$vers -y --install-arguments 'INSTALLDIR=$path' --no-progress"
}

# --- Set Java environment variables ---
Write-Host "🔧 Setting Java environment variables..."
foreach ($vers in $java_versions) {
    $javaPath = "S:\Languages\Java\$vers"
    $envName = "JAVA_${vers}_HOME"
    Write-Host "➡️ Setting $envName to $javaPath"
    [System.Environment]::SetEnvironmentVariable($envName, $javaPath, "Machine")
}
Write-Host "➡️ Setting JAVA_HOME to %JAVA_25_HOME%"
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", "%JAVA_25_HOME%", "Machine")
$javaBinVar = "%JAVA_HOME%\bin"
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
if ($currentPath -notlike "*$javaBinVar*") {
    Write-Host "🧩 Adding $javaBinVar to system PATH..."
    $newPath = "$currentPath;$javaBinVar"
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
} else { Write-Host "ℹ️ $javaBinVar already in PATH." }

# --- 8️⃣ Chocolatey apps ---
Write-Host "🍫 Installing apps via Chocolatey..."
Safe-Run "choco install starship -y --install-arguments 'INSTALLDIR=S:\' --no-progress"
Safe-Run "choco install sdio -y --install-arguments 'INSTALLDIR=S:\' --no-progress"
Safe-Run "choco install maven -y --install-arguments 'INSTALLDIR=S:\Languages' --no-progress"

# --- 9️⃣ Install JetBrainsMono Nerd Font (optimized) ---
Write-Host "🔤 Installing JetBrainsMono Nerd Font..."
$fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"
$fontZip = "C:\Temp\JetBrainsMono.zip"
$fontExtract = "C:\Temp\JetBrainsMono"
if (-not (Test-Path "C:\Temp")) { New-Item -Path "C:\Temp" -ItemType Directory | Out-Null }

# Download and extract font in a single step
Invoke-WebRequest -Uri $fontUrl -OutFile $fontZip
Expand-Archive -Path $fontZip -DestinationPath $fontExtract -Force

# Install all .ttf files in parallel
$fonts = Get-ChildItem -Path $fontExtract -Filter "*.ttf" -Recurse
$jobs = @()
foreach ($font in $fonts) {
    $jobs += Start-Job -ScriptBlock {
        param($f)
        $dest = "C:\Windows\Fonts\$($f.Name)"
        Copy-Item -Path $f.FullName -Destination $dest -Force
        $regName = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
        New-ItemProperty -Path $regPath -Name $regName -Value $f.Name -PropertyType String -Force | Out-Null
    } -ArgumentList $font
}
# Wait for all font jobs to finish
$jobs | Wait-Job | Receive-Job
$jobs | Remove-Job

# Clean temporary files
Remove-Item $fontZip -Force
Remove-Item $fontExtract -Recurse -Force
Write-Host "✅ JetBrainsMono Nerd Font installed!"

# --- 10️⃣ Verification of installations ---
Write-Host "🔍 Verifying installed software..."
Function Check-Command($name, $cmd) { Try { $output = & cmd /c $cmd 2>&1; Write-Host "$name version: $output" } Catch { Write-Host "⚠️ $name check failed!" -ForegroundColor Yellow } }

# Java versions
foreach ($vers in $java_versions) {
    $envVar = "JAVA_${vers}_HOME"
    $javaPath = [System.Environment]::GetEnvironmentVariable($envVar,"Machine")
    if ($javaPath) { Write-Host "✅ $envVar found at $javaPath"; Check-Command "Java $vers" "$javaPath\bin\java.exe -version" }
    else { Write-Host "⚠️ $envVar not found!" -ForegroundColor Yellow }
}
$javaHome = [System.Environment]::GetEnvironmentVariable("JAVA_HOME","Machine")
if ($javaHome) { Write-Host "✅ JAVA_HOME = $javaHome"; Check-Command "Java (JAVA_HOME)" "%JAVA_HOME%\bin\java.exe -version" }
else { Write-Host "⚠️ JAVA_HOME not found!" -ForegroundColor Yellow }

# Other software
Check-Command "Python" "python --version"
Check-Command "Node.js" "node --version"
Check-Command "Maven" "mvn -version"
Check-Command "Git" "git --version"

Write-Host "🔎 Verification completed!"
Stop-Transcript
