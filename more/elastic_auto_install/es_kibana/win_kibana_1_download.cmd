:: es_kibana\win_kibana_1_download.cmd
@echo off
chcp 65001 > nul
CALL %~dp0..\config.cmd


python %LIB_DIR%\check_install.py %KIBANA_INSTALL_DIR%
if %ERRORLEVEL% neq 0 (
    python %LIB_DIR%\install_download.py  %KIBANA_DOWNLOAD_URL%  %KIBANA_DOWNLOAD_ZIP%
    python %LIB_DIR%\install_extra.py  %KIBANA_DOWNLOAD_ZIP%  %KIBANA_INSTALL_DIR%  %KIBANA_TEMP_DIR%
    python %LIB_DIR%\config_add.py  %KIBANA_CONFIG_FILE%  KIBANA_CONFIG_PATCH
)



PAUSE