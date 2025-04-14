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
:: 参考文档：::https://elasticsearch.tutorials24x7.com/blog/how-to-install-kibana-on-windows
:: nssm 使用说明 https://nssm.cc/usage



echo 已接受参数:
echo 安装服务名: %KIBANA_SERVER_INSTALL_NAME%
echo 版本: %VER%
echo 工作目录: %KIBANA_INSTALL_DIR%
echo 启动脚本: %KIBANA_SERVER_BIN%
echo 日志目录: %KIBANA_SERVER_LOG_DIR%
echo NSSM路径: %NSSMEXE%
echo.





if not exist %KIBANA_SERVER_LOG_DIR% mkdir %KIBANA_SERVER_LOG_DIR%

echo 开始安装 %KIBANA_SERVER_INSTALL_NAME% 作为后台服务...
echo.
pause
%NSSMEXE% install %KIBANA_SERVER_INSTALL_NAME% %KIBANA_SERVER_BIN%
if %ERRORLEVEL% equ 0 (
    echo %KIBANA_SERVER_INSTALL_NAME% 后台服务安装完成.
    echo.
    echo 设置一些优化参数:

    %NSSMEXE% set %KIBANA_SERVER_INSTALL_NAME% AppDirectory %KIBANA_INSTALL_DIR%
    %NSSMEXE% set %KIBANA_SERVER_INSTALL_NAME% AppStdout %KIBANA_SERVER_LOG_DIR%\nssm.stdout
    %NSSMEXE% set %KIBANA_SERVER_INSTALL_NAME% AppStderr %KIBANA_SERVER_LOG_DIR%\nssm.stderr
    %NSSMEXE% set %KIBANA_SERVER_INSTALL_NAME% AppStdoutCreationDisposition 4
    %NSSMEXE% set %KIBANA_SERVER_INSTALL_NAME% AppStderrCreationDisposition 4
    %NSSMEXE% set %KIBANA_SERVER_INSTALL_NAME% AppRotateFiles 1
    %NSSMEXE% set %KIBANA_SERVER_INSTALL_NAME% AppRotateOnline 0
    %NSSMEXE% set %KIBANA_SERVER_INSTALL_NAME% AppRotateSeconds 86400
    %NSSMEXE% set %KIBANA_SERVER_INSTALL_NAME% Start SERVICE_DELAYED_AUTO_START
)


echo.
pause
