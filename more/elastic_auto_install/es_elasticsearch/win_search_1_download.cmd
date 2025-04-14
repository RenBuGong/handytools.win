:: es_elasticsearch\win_search_1_download.cmd
@echo off
chcp 65001 > nul
CALL %~dp0..\config.cmd


python %LIB_DIR%\check_install.py %SEARCH_INSTALL_DIR%
if %ERRORLEVEL% neq 0 (
    python %LIB_DIR%\install_download.py  %SEARCH_DOWNLOAD_URL%  %SEARCH_DOWNLOAD_ZIP%
    python %LIB_DIR%\install_extra.py  %SEARCH_DOWNLOAD_ZIP%  %SEARCH_INSTALL_DIR%  %SEARCH_TEMP_DIR%
    python %LIB_DIR%\config_add.py  %SEARCH_CONFIG_FILE%  SEARCH_CONFIG_PATCH
)



PAUSE