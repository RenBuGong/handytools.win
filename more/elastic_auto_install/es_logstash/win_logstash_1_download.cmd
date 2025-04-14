:: es_logstash\win_logstash_1_download.cmd
@echo off
chcp 65001 > nul
CALL %~dp0..\config.cmd


python %LIB_DIR%\check_install.py %LOGSTASH_INSTALL_DIR%
if %ERRORLEVEL% neq 0 (
    python %LIB_DIR%\install_download.py  %LOGSTASH_DOWNLOAD_URL%  %LOGSTASH_DOWNLOAD_ZIP%
    python %LIB_DIR%\install_extra.py  %LOGSTASH_DOWNLOAD_ZIP%  %LOGSTASH_INSTALL_DIR%  %LOGSTASH_TEMP_DIR%
    python %LIB_DIR%\config_add.py  %LOGSTASH_CONFIG_FILE%  LOGSTASH_CONFIG_PATCH
)



PAUSE