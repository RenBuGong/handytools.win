@echo off
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File ".\_powershell\ssh-pubkey-del.ps1" -KeyPath "%1"
pause


