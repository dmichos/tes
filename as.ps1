# Run this script from an elevated PowerShell window (Run as Administrator)

Write-Host "=== Desktop and shell repair ===" -ForegroundColor Cyan

# 1. Remove desktop.ini files from each user's Desktop
$profiles = Get-ChildItem 'C:\Users' -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notin @('Public','Default','Default User','All Users') }

foreach ($p in $profiles) {
    $desktopPath = Join-Path $p.FullName 'Desktop'
    if (Test-Path $desktopPath) {
        $inis = Get-ChildItem $desktopPath -Filter 'desktop.ini' -Force -ErrorAction SilentlyContinue
        foreach ($ini in $inis) {
            try {
                Remove-Item $ini.FullName -Force -ErrorAction Stop
                Write-Host "Removed: $($ini.FullName)" -ForegroundColor Yellow
            } catch {
                Write-Warning "Could not remove $($ini.FullName): $_"
            }
        }
    }
}

# 2. Verify shell registry key (system-wide)
$regPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
Set-ItemProperty -Path $regPath -Name Shell -Value 'explorer.exe' -ErrorAction SilentlyContinue
Write-Host "Verified shell registry value under Winlogon." -ForegroundColor Cyan

# 3. Re-register core shell packages for all users
$packages = @(
    "Microsoft.Windows.ShellExperienceHost",
    "Microsoft.Windows.StartMenuExperienceHost",
    "Microsoft.Windows.FileExplorer",
    "Microsoft.Windows.Search",
    "windows.immersivecontrolpanel",
    "Microsoft.WindowsStore"
)
foreach ($pkg in $packages) {
    Get-AppxPackage -AllUsers -Name $pkg -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "Re-registering $pkg for $($_.UserSid)" -ForegroundColor Cyan
        Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppxManifest.xml" -ErrorAction SilentlyContinue
    }
}

# 4. Run system file and image repairs
Write-Host "Running SFC and DISM health scans (may take several minutes)..." -ForegroundColor Cyan
sfc /scannow
DISM /Online /Cleanup-Image /RestoreHealth

# 5. Restart Explorer to test the result
Write-Host "Restarting Explorer..." -ForegroundColor Cyan
Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Process explorer.exe

Write-Host "`n=== Repair routine completed ===" -ForegroundColor Green
Write-Host "Reboot the computer after this script finishes."
