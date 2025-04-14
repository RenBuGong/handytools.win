@echo off
cd /d "%~dp0"
:: 检查管理员权限并在需要时提权.
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "%*", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B
)
goto gotAdmin
:gotAdmin
cd /d "%~dp0"

PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File ".\_powershell\ssh-pubkey-add.ps1" -KeyPath "%1" -AuthorizedKeysFile "C:\ProgramData\ssh\administrators_authorized_keys"

::Appropriately ACL the authorized_keys file on your server
@REM icacls.exe "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
@REM icacls.exe "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "SYSTEM:F"

pause

