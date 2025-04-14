@echo off
REM 设置当前用户的执行策略为 RemoteSigned，并使用 -Force 参数避免交互提示.
:: PowerShell.exe -NoProfile -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"
PowerShell.exe -NoProfile -Command "Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force"
echo Execution policy has been set to Unrestricted for the current user.
pause
