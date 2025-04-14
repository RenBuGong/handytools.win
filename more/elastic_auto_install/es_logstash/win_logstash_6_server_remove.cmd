@echo off
cd /d "%~dp0"
cacls.exe "%SystemDrive%\System Volume Information" >nul 2>nul
if %errorlevel%==0 goto Admin
if exist "%temp%\getadmin.vbs" del /f /q "%temp%\getadmin.vbs"
echo Set RequestUAC = CreateObject^("Shell.Application"^)>"%temp%\getadmin.vbs"
echo RequestUAC.ShellExecute "%~s0","","","runas",1 >>"%temp%\getadmin.vbs"
echo WScript.Quit >>"%temp%\getadmin.vbs"
"%temp%\getadmin.vbs" /f
if exist "%temp%\getadmin.vbs" del /f /q "%temp%\getadmin.vbs"
exit
:Admin
chcp 65001 > nul
CALL %~dp0..\config.cmd


echo %LOGSTASH_SERVER_INSTALL_NAME% 服务会被停止, 并移除作为后台服务的设置.
echo %LOGSTASH_SERVER_INSTALL_NAME% 服务会被停止, 并移除作为后台服务的设置.
echo %LOGSTASH_SERVER_INSTALL_NAME% 服务会被停止, 并移除作为后台服务的设置.
echo.
pause
%NSSMEXE% stop %LOGSTASH_SERVER_INSTALL_NAME%
if %ERRORLEVEL% equ 0 (
    %NSSMEXE% remove %LOGSTASH_SERVER_INSTALL_NAME% confirm
)

pause
