# --- Windows 11 black-screen shell repair script ---

Write-Host "Resetting Explorer and shell components..." -ForegroundColor Cyan

# 1. Kill any frozen Explorer instance
Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force

# 2. Re-register core Windows shell components (apps providing desktop, taskbar, settings UI)
$packages = @(
    "Microsoft.Windows.ShellExperienceHost",
    "Microsoft.Windows.StartMenuExperienceHost",
    "Microsoft.Windows.FileExplorer",
    "Microsoft.Windows.Search",
    "windows.immersivecontrolpanel",
    "Microsoft.WindowsStore"
)
foreach ($pkg in $packages) {
    Get-AppxPackage -AllUsers -Name $pkg -ErrorAction SilentlyContinue | 
        ForEach-Object {
            Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppxManifest.xml" -ErrorAction SilentlyContinue
        }
}

# 3. Restore the correct shell registry value
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "Shell" -Value "explorer.exe" -ErrorAction SilentlyContinue

# 4. Run SFC and DISM repairs
Write-Host "`nRunning SFC and DISM health checks (may take several minutes)..." -ForegroundColor Yellow
sfc /scannow
DISM /Online /Cleanup-Image /RestoreHealth

# 5. Restart Explorer
Start-Process explorer.exe
Write-Host "`nExplorer restarted. If the desktop now appears, reboot once more to confirm persistence." -ForegroundColor Green
