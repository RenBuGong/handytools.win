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





echo 注册当前安装的elasticsearch 实例.
echo 1 如果elasticsearch 还从未启动过, 请退出此脚本, 去手动运行一次(初始化)!!!
echo 2 如果elasticsearch 正在运行, 请先停止.
echo 3 请确认%ENV_FILE%中的账号密码、URL已根据实际情况,设置正确.
echo 3 请确认%ENV_FILE%中的账号密码、URL已根据实际情况,设置正确.
echo 3 请确认%ENV_FILE%中的账号密码、URL已根据实际情况,设置正确.





:confirm
set /p choice=是否继续执行? (Y/N): 
if /i "%choice%"=="Y" goto continue
if /i "%choice%"=="N" goto end
echo 请输入 Y 或 N
goto confirm





:continue
:: 拷贝学习好的.jar 替换到安装目录.
copy /Y %SRARCH_LEARNED_JAR% %SRARCH_LICENSE_TARG_JAR%
if %ERRORLEVEL% EQU 0 (
    echo 已成功替换 %SRARCH_LICENSE_TARG_JAR%
) else (
    CALL %SEARCH_SERVER_MNG% "stop"
    CALL python %LIB_DIR%\learn_copy.py %SRARCH_LEARNED_JAR%  %SRARCH_LICENSE_TARG_JAR%
)
eho.


:: 提交自定义授权文件
CALL %SEARCH_SERVER_MNG% "start"
CALL python %LIB_DIR%\check_http_service.py %ELASTICSEARCH_USER%  %ELASTICSEARCH_PASS%  %ELASTICSEARCH_HOST%/_cluster/health
if %ERRORLEVEL% equ 0 (
    CALL python %LIB_DIR%\learn_update_license.py %ELASTICSEARCH_USER%  %ELASTICSEARCH_PASS%  %SRARCH_LEARNED_LICENSE_JSON%  %ELASTICSEARCH_HOST%/_license
) else (
    echo 跳过注册.
)


echo.
echo 当前授权信息:
curl -k --cacert %SEARCH_INSTALL_DIR%\config\certs\http_ca.crt -u %ELASTICSEARCH_USER%:%ELASTICSEARCH_PASS%  %ELASTICSEARCH_HOST%/_license

:end
PAUSE




:: powershell -Command "for ($i = 10; $i -ge 0; $i--) { Write-Host \"$i 秒后继续...\"; Start-Sleep -Seconds 1 }"