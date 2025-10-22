@echo off
REM Run PowerShell in cmd.exe so Fabric CLI works correctly
pwsh -NoProfile -ExecutionPolicy Bypass -File "Manage-FabricAdmins.ps1" %*