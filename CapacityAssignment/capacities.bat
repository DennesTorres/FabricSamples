@echo off
REM Required wrapper: run pwsh under cmd.exe so Fabric CLI has a Windows console.
REM Forward all arguments to the PowerShell script

pwsh -NoProfile -ExecutionPolicy Bypass -File "capacities.ps1" %*