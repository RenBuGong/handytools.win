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


echo 停止 %SEARCH_SERVER_INSTALL_NAME% 作为后台服务.
echo 如果服务尚未安装, 会报 code 2 错误.
echo (因为官方bug, 会执行两次停止, 请以后面一次的信息输出为准).
echo.
pause
CALL %SEARCH_SERVER_MNG% "stop"
CALL %SEARCH_SERVER_MNG% "stop"

pause
