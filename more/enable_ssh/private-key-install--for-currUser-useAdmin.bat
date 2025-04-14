@echo off
cd /d "%~dp0"

:: Check for permissions and self-elevate if needed
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
chcp 65001 > nul
setlocal enabledelayedexpansion

:: Ensure OpenSSH service is set to automatic and started
sc config ssh-agent start= auto
net start ssh-agent

:: Get the private key path from first argument
set "privateKeyPath=%~1"
echo Private key path: %privateKeyPath%
if "%privateKeyPath%"=="" (
    echo Please provide the path to your private key as an argument.
    pause
    exit /b 1
)

:: Create .ssh directory if it doesn't exist
ssh -oBatchMode=yes -oStrictHostKeyChecking=no -tt 050e0ec1-bc43-4996-9bce-5494eb255141@127.0.0.1 >nul 2>nul

:: Copy the private key to .ssh directory
copy /Y "%privateKeyPath%" "%USERPROFILE%\.ssh\"

:: Add the private key to ssh-agent
ssh-add "%USERPROFILE%\.ssh\%~nx1"

echo SSH setup completed.
pause