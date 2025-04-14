@echo off
rem 获取脚本所在目录
set "SCRIPT_DIR=%~dp0"
set "ENV_PATH=%SCRIPT_DIR%.venv"
set "FLAG_FILE=%ENV_PATH%\deps_installed.txt"

if not exist "%ENV_PATH%" (
    python -m venv "%ENV_PATH%"
)

call "%ENV_PATH%\Scripts\activate.bat"

if not exist "%SCRIPT_DIR%requirements.txt" goto cmdk

if not exist "%FLAG_FILE%" (
    pip install -r "%SCRIPT_DIR%requirements.txt"
    echo Installed > "%FLAG_FILE%"
)

:cmdk
cmd /k
