@echo off
chcp 65001  >nul
setlocal enabledelayedexpansion

:: 获取当前脚本所在目录，注意 %~dp0 带有末尾反斜杠.
set "CUR_DIR=%~dp0"
:: 如需要去除末尾的反斜杠，可取消下面两行注释.
if "%CUR_DIR:~-1%"=="\" set "CUR_DIR=%CUR_DIR:~0,-1%"

:: 获取脚本文件名（不包括扩展名）.
set "SCRIPT_NAME=%~n0"

:: 构造模板 wsb 文件的完整路径（模板文件与脚本同名）.
set "TEMPLATE_WSB=%~dp0%SCRIPT_NAME%.wsb"
echo 正在处理模板文件: %TEMPLATE_WSB%

:: 检查模板文件是否存在.
if not exist "%TEMPLATE_WSB%" (
    echo 模板文件不存在: %TEMPLATE_WSB%
    pause
    exit /b 1
)

:: 构造新生成文件的名称，可按需求修改后缀.
set "NEW_WSB=%~dp0%SCRIPT_NAME%-generated.wsb"

:: 使用 PowerShell 读取模板文件内容，并替换所有占位符 __SCRIPTDIR__ 为当前目录，再写入新的 wsb 文件.
powershell -NoProfile -Command "(Get-Content -Raw '%TEMPLATE_WSB%').Replace('__SCRIPTDIR__','%CUR_DIR%') | Set-Content '%NEW_WSB%'"
if errorlevel 1 (
    echo 文件替换过程中发生错误.
    pause
    exit /b 1
)

echo 新的 wsb 文件已生成: %NEW_WSB%

:: 直接启动新生成的 .wsb 文件（如果已关联到 Windows Sandbox，则会自动打开沙箱）.
start "" "%NEW_WSB%"
del %NEW_WSB%

pause
