@echo off
setlocal enabledelayedexpansion
rem ==========================================================
rem runtime_setup.bat  -  Download Python (embeddable) + Node.js
rem Requires: Windows 10+ (curl and tar are built-in)
rem ==========================================================

rem ----- versions -----
set PY_VER=3.12.3
set NODE_VER=23.11.0
rem --------------------

set OUTDIR=%~dp0runtime
set PY_DIR=%OUTDIR%\python
set NODE_DIR=%OUTDIR%\node

rem ---------- make folders ----------
mkdir "%OUTDIR%" 2>nul
mkdir "%PY_DIR%" 2>nul
rem ----------------------------------

rem ===== download Python =====
echo [Python] downloading %PY_VER%
set PY_ZIP=python-%PY_VER%-embed-amd64.zip
curl -L -o "%PY_ZIP%" ^
  https://www.python.org/ftp/python/%PY_VER%/%PY_ZIP%
if errorlevel 1 goto err

echo [Python] extracting
tar -xf "%PY_ZIP%" -C "%PY_DIR%"
if errorlevel 1 goto err
del "%PY_ZIP%"

rem enable site-packages so pip/venv work
echo import site>>"%PY_DIR%\python312._pth"

rem bootstrap pip
echo [Python] installing pip
curl -sLo "%PY_DIR%\get-pip.py" https://bootstrap.pypa.io/get-pip.py
if errorlevel 1 goto err
"%PY_DIR%\python.exe" "%PY_DIR%\get-pip.py" --no-warn-script-location
if errorlevel 1 goto err
del "%PY_DIR%\get-pip.py"

rem ===== download Node.js =====
echo [Node] downloading %NODE_VER%
set NODE_ZIP=node-v%NODE_VER%-win-x64.zip
curl -L -o "%NODE_ZIP%" ^
  https://nodejs.org/dist/v%NODE_VER%/%NODE_ZIP%
if errorlevel 1 goto err

echo [Node] extracting
tar -xf "%NODE_ZIP%" -C "%OUTDIR%"
if errorlevel 1 goto err
del "%NODE_ZIP%"
move "%OUTDIR%\node-v%NODE_VER%-win-x64" "%NODE_DIR%" >nul

echo.
echo --------- runtime ready ---------
echo Python : "%PY_DIR%\python.exe"
echo Node   : "%NODE_DIR%\node.exe"
echo ---------------------------------
pause
exit /b 0

:err
echo.
echo [ERROR] setup failed. Please check network or disk space.
pause
exit /b 1
endlocal
