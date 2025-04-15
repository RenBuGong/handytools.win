@echo off
chcp 65001  >nul
:: -------------------------------------------------------------------------
:: 文件: pathhereadd.cmd
:: 用途: 将指定路径或当前工作目录添加到当前用户的 PATH(注册表HKCU\Environment) 中.
::       如果提供参数 %1，则添加参数指定的路径，否则添加当前工作目录.
:: -------------------------------------------------------------------------
setlocal enabledelayedexpansion

echo Add this path to your user %%PATH%%
echo.
:: 1. 获取要添加的路径(去除末尾的"\")
if "%~1"=="" (
    :: 如果没有参数，使用当前工作目录.
    set "TARGET_DIR=%cd%"
    echo 使用当前工作目录: %cd%
) else (
    :: 如果有参数，使用指定的路径.
    set "TARGET_DIR=%~1"
    echo 使用指定路径: %~1
)

:: 确保路径末尾没有"\"
if "%TARGET_DIR:~-1%"=="\" (
    set "TARGET_DIR=%TARGET_DIR:~0,-1%"
)

:: 2. 从注册表查询用户 PATH 值.
set "CurrentUserPath="
set "RegPathType="

for /f "skip=2 tokens=1,2,* delims= " %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do (
    if /i "%%a"=="Path" (
        set "RegPathType=%%b"
        set "CurrentUserPath=%%c"
    )
)

:: 若不存在 PATH 这个键，CurrentUserPath 可能为空.
if not defined CurrentUserPath (
    set "CurrentUserPath="
)

echo 当前用户PATH 原始值:
echo %CurrentUserPath%
echo.

:: 3. 使用替换测试 检查当前用户 PATH 是否已包含 %TARGET_DIR%
set "test_before=;%CurrentUserPath%;"
set "test_after=!test_before:;%TARGET_DIR%;=;!"

if not "!test_after!"=="!test_before!" (
    echo 目标路径已存在, 无需添加:
    echo %TARGET_DIR%
    echo.
    pause
    goto :EOF
)

:: 4. 备份当前PATH(带时间戳)到脚本同目录 __path_backup.log
set "TIME_STAMP=[%date% %time%]"
echo USER-PATH_PRE-ADD %TIME_STAMP%   %CurrentUserPath% >>"%~dp0pathhere.backup.log"

:: 5. 组装新的PATH
if "%CurrentUserPath%"=="" (
    set "NewUserPath=%TARGET_DIR%"
) else (
    set "NewUserPath=%CurrentUserPath%;%TARGET_DIR%"
)

echo 准备写入新的PATH:
echo %NewUserPath%
echo.

:: 6. setx 写入注册表.
setx Path "%NewUserPath%" >nul
if %ERRORLEVEL% neq 0 (
    echo [错误] 写入注册表失败，脚本退出.
    pause
    goto :EOF
)

echo [完成] 已添加到用户PATH.
echo 提示: 需关闭并重新打开命令提示符才会看到最新PATH生效.
echo.
pause
goto :EOF
