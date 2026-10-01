# Install and enroll the Wazuh agent on Windows. Run in an elevated PowerShell.
# Usage: .\install-agent-windows.ps1 -Manager 10.0.0.12 [-Version 4.14.8-1] [-Group default]
param(
  [Parameter(Mandatory = $true)][string]$Manager,
  [string]$Version = "4.14.8-1",   # match your manager version (docs: Installing the Wazuh agent on Windows)
  [string]$Group = "default"
)
$ErrorActionPreference = "Stop"

$msi = "$env:TEMP\wazuh-agent-$Version.msi"
Invoke-WebRequest -Uri "https://packages.wazuh.com/4.x/windows/wazuh-agent-$Version.msi" -OutFile $msi

Start-Process msiexec.exe -Wait -ArgumentList @(
  "/i", "`"$msi`"", "/q",
  "WAZUH_MANAGER=`"$Manager`"",
  "WAZUH_AGENT_GROUP=`"$Group`"",
  "WAZUH_AGENT_NAME=`"$env:COMPUTERNAME`""
)

Start-Service WazuhSvc
Get-Service WazuhSvc | Format-Table Name, Status
Write-Host "Done. Check the dashboard: Agents > $env:COMPUTERNAME should be Active."
