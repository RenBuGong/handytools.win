@echo off
chcp 65001 > nul
CALL %~dp0..\config.cmd


echo 1 下载 需要学习的模块 的源代码.
python %LIB_DIR%\install_download.py  %LICENSE_FILE_1_URL%  %LICENSE_FILE_1%
python %LIB_DIR%\install_download.py  %LICENSE_FILE_2_URL%  %LICENSE_FILE_2%
echo.

echo 2 下载用于模块编译的  elastic search 环境.
python %LIB_DIR%\check_install.py %SRARCH_LEARNED_DIR%
if %ERRORLEVEL% neq 0 (
    python %LIB_DIR%\install_download.py  %SEARCH_DOWNLOAD_URL%  %SEARCH_DOWNLOAD_ZIP%
    python %LIB_DIR%\install_extra.py  %SEARCH_DOWNLOAD_ZIP%  %SRARCH_LEARNED_DIR%  %SEARCH_TEMP_DIR%
)




PAUSE