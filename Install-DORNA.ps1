
# ==========================================
# DORNA PC Service Installer
# Offline Driver Installation System
# Windows 7 / 8 / 8.1 / 10 / 11
# x86 / x64
# ==========================================

$ErrorActionPreference = "Continue"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$DriverFolder = Join-Path $Root "Drivers"
$LogFolder = Join-Path $Root "Logs"
$LogFile = Join-Path $LogFolder "DORNA-Install.log"

# Create log directory
if (!(Test-Path $LogFolder)) {
    New-Item -ItemType Directory -Path $LogFolder -Force | Out-Null
}

function Write-Log {
    param([string]$Message)

    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Line = "[$Time] $Message"

    Write-Host $Line
    Add-Content -Path $LogFile -Value $Line
}

# Administrator check
$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
$IsAdmin = $Principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (!$IsAdmin) {
    Write-Host "Please run DORNA as Administrator."
    Read-Host "Press Enter to exit"
    exit 1
}

# Detect Windows version
$OS = [Environment]::OSVersion.Version

$WindowsName = "Unknown"

if ($OS.Major -eq 6 -and $OS.Minor -eq 1) {
    $WindowsName = "Windows 7"
}
elseif ($OS.Major -eq 6 -and $OS.Minor -eq 2) {
    $WindowsName = "Windows 8"
}
elseif ($OS.Major -eq 6 -and $OS.Minor -eq 3) {
    $WindowsName = "Windows 8.1"
}
elseif ($OS.Major -ge 10) {
    $WindowsName = "Windows 10 / 11"
}
else {
    Write-Log "Unsupported Windows version: $OS"
    exit 1
}

# Detect architecture
$Architecture = $env:PROCESSOR_ARCHITECTURE

if ($env:PROCESSOR_ARCHITEW6432) {
    $Architecture = $env:PROCESSOR_ARCHITEW6432
}

Write-Log "=================================="
Write-Log "DORNA PC Service Installer"
Write-Log "Windows: $WindowsName"
Write-Log "Version: $OS"
Write-Log "Architecture: $Architecture"
Write-Log "=================================="

# Check driver folder
if (!(Test-Path $DriverFolder)) {
    Write-Log "ERROR: Drivers folder not found."
    exit 1
}

# Find INF driver files
$Drivers = Get-ChildItem -Path $DriverFolder -Filter "*.inf" -Recurse

if ($Drivers.Count -eq 0) {
    Write-Log "No INF drivers found."
    exit 1
}

Write-Log "Found $($Drivers.Count) driver files."

$Success = 0
$Failed = 0

foreach ($Driver in $Drivers) {

    Write-Log "Installing: $($Driver.Name)"

    if ($OS.Major -eq 6 -and $OS.Minor -le 1) {

        # Windows 7 compatible syntax
        & "$env:SystemRoot\System32\pnputil.exe" -i -a "$($Driver.FullName)"

    }
    else {

        # Windows 8 and newer
        & "$env:SystemRoot\System32\pnputil.exe" /add-driver "$($Driver.FullName)" /install

    }

    if ($LASTEXITCODE -eq 0) {
        $Success++
        Write-Log "SUCCESS: $($Driver.Name)"
    }
    else {
        $Failed++
        Write-Log "FAILED: $($Driver.Name) - Exit code: $LASTEXITCODE"
    }
}

Write-Log "=================================="
Write-Log "Installation completed."
Write-Log "Successful: $Success"
Write-Log "Failed: $Failed"
Write-Log "=================================="

Write-Host ""
Write-Host "DORNA installation finished."
Write-Host "Successful: $Success"
Write-Host "Failed: $Failed"

Read-Host "Press Enter to exit"

