@echo off
chcp 65001 > nul
CALL %~dp0..\config.cmd

echo 初始化配置, 会为logstash 添加一个syslog pipeline 配置, 否则pipeline 为空的logstash 会拒绝启动.
echo 1 会修改%LOGSTASH_PIPELINE_YAML%
echo 2 会生成%LOGSTASH_PIPELINE_CONIF_1_SYSLOG%
echo.
pause
:: 检查配置文件是否已存在
if exist "%LOGSTASH_PIPELINE_CONIF_1_SYSLOG%" (
    echo %LOGSTASH_PIPELINE_CONIF_1_SYSLOG% 已存在.
    goto END
)

python %LIB_DIR%\check_install.py %LOGSTASH_INSTALL_DIR%
if %ERRORLEVEL% equ 0 (
    python %LIB_DIR%\config_add.py  %LOGSTASH_PIPELINE_YAML%  LOGSTASH_PIPELINE_YAML_PATCH
    python %LIB_DIR%\config_process.py  %LOGSTASH_PIPELINE_TAMPLATE_1_SYSLOG%  LOGSTASH_PIPELINE_CONIF_VAR  %LOGSTASH_PIPELINE_CONIF_1_SYSLOG%
)

:END
PAUSE