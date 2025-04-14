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
:: 参考文档 https://www.elastic.co/guide/en/logstash/current/installing-logstash.html
:: nssm 使用说明 https://nssm.cc/usage



echo 已接受参数:
echo 安装服务名: %LOGSTASH_SERVER_INSTALL_NAME%
echo 版本: %VER%
echo 工作目录: %LOGSTASH_INSTALL_DIR%
echo 启动脚本: %LOGSTASH_SERVER_BIN%
echo 日志目录: %LOGSTASH_SERVER_LOG_DIR%
echo NSSM路径: %NSSMEXE%
echo.





if not exist %LOGSTASH_SERVER_LOG_DIR% mkdir %LOGSTASH_SERVER_LOG_DIR%

echo 开始安装 %LOGSTASH_SERVER_INSTALL_NAME% 作为后台服务...
echo.
pause
%NSSMEXE% install %LOGSTASH_SERVER_INSTALL_NAME% %LOGSTASH_SERVER_BIN%
if %ERRORLEVEL% equ 0 (
    echo %LOGSTASH_SERVER_INSTALL_NAME% 后台服务安装完成.
    echo.
    echo 设置一些优化参数:

    %NSSMEXE% set %LOGSTASH_SERVER_INSTALL_NAME% AppDirectory %LOGSTASH_INSTALL_DIR%
    %NSSMEXE% set %LOGSTASH_SERVER_INSTALL_NAME% AppStdout %LOGSTASH_SERVER_LOG_DIR%\nssm.stdout
    %NSSMEXE% set %LOGSTASH_SERVER_INSTALL_NAME% AppStderr %LOGSTASH_SERVER_LOG_DIR%\nssm.stderr
    %NSSMEXE% set %LOGSTASH_SERVER_INSTALL_NAME% AppStdoutCreationDisposition 4
    %NSSMEXE% set %LOGSTASH_SERVER_INSTALL_NAME% AppStderrCreationDisposition 4
    %NSSMEXE% set %LOGSTASH_SERVER_INSTALL_NAME% AppRotateFiles 1
    %NSSMEXE% set %LOGSTASH_SERVER_INSTALL_NAME% AppRotateOnline 0
    %NSSMEXE% set %LOGSTASH_SERVER_INSTALL_NAME% AppRotateSeconds 86400
    %NSSMEXE% set %LOGSTASH_SERVER_INSTALL_NAME% Start SERVICE_DELAYED_AUTO_START
)


echo.
pause
