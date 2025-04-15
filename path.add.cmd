@echo off
chcp 65001 >nul
:: -------------------------------------------------------------------------
:: 文件: add_path.bat
:: 用途:
::   1) 在用户级环境里定义(或更新) ipzu_handy_tools_win = <脚本所在目录>\handy_tools;<脚本所在目录>\handy_tools_custom
::   2) 检测并将 "%ipzu_handy_tools_win%" 追加到用户级 PATH (注册表HKCU\Environment\Path) 中.
:: -------------------------------------------------------------------------
setlocal EnableDelayedExpansion

:: 1. 获取脚本自身所在目录(去除末尾 "\").
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" (
    set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
)

:: 2. 组装 ipzu_handy_tools_win 对应目录值（分号分隔）.
set "HANDY_DIRS=%SCRIPT_DIR%\handy_tools;%SCRIPT_DIR%\handy_tools_custom"

echo ====================================================
echo [INFO] 脚本目录:    %SCRIPT_DIR%
echo [INFO] 将写入变量:  %%ipzu_handy_tools_win%%
echo [INFO] 对应的值:    %HANDY_DIRS%
echo ====================================================
echo.
echo 1.
:: 3. 先查询已存在的 ipzu_handy_tools_win
set "CURRENT_HIPZU="
for /f "skip=2 tokens=1,2,* delims= " %%A in (
    'reg query "HKCU\Environment" /v "ipzu_handy_tools_win" 2^>nul'
) do (
    if /i "%%A"=="ipzu_handy_tools_win" (
        set "CURRENT_HIPZU=%%C"
    )
)

:: 4. 如果当前 ipzu_handy_tools_win 跟我们想要的值不同，则 setx 更新.
if /i "%CURRENT_HIPZU%"=="%HANDY_DIRS%" (
    echo [INFO] %%ipzu_handy_tools_win%% 已是目标值, 无需更新.
) else (
    setx ipzu_handy_tools_win "%HANDY_DIRS%" >nul
    if %ERRORLEVEL% neq 0 (
        echo [错误] 无法写入 %%ipzu_handy_tools_win%% 到注册表，脚本退出.
        pause
        goto :EOF
    )
    echo [完成] %%ipzu_handy_tools_win%% 已设置为: "%HANDY_DIRS%"
)
echo.
echo.
echo.
echo 2.

:: 5. 读取当前用户 PATH 的【原始字符串】(即注册表存储值).
set "CurrentUserPath="
for /f "skip=2 tokens=1,2,* delims= " %%a in (
    'reg query "HKCU\Environment" /v Path 2^>nul'
) do (
    if /i "%%a"=="Path" (
        set "CurrentUserPath=%%c"
        set "CurrentUserPath2=%%c"
    )
)

:: 注意: CurrentUserPath 里可能包含尚未被展开的 %ipzu_handy_tools_win% 字面量.
if not defined CurrentUserPath (
    set "CurrentUserPath="
)

:: 为了在 echo 时不被 CMD 再次解析, 我们用 ! 变量 !.
echo [INFO] 注册表中当前 PATH 原始值:
echo !CurrentUserPath!
echo.

:: 6. 使用替换测试 检查当前用户 PATH 是否已包含字面串 "%%ipzu_handy_tools_win%%"
set "test_before=;!CurrentUserPath!;"
set "test_after=!test_before:;%%ipzu_handy_tools_win%%;=;!"

if not "!test_after!"=="!test_before!" (
    echo [INFO] 当前 PATH 中已包含 "%%ipzu_handy_tools_win%%", 无需再添加.
    echo.
    pause
    goto :EOF
)


:: 7. 进行添加前的备份.
set "TIME_STAMP=[%date% %time%]"
echo [INFO] 备份当前 PATH 到脚本同目录 path_backup.log
echo USER-PATH_PRE-ADD %TIME_STAMP%:   !CurrentUserPath! >>"%~dp0path_backup.log"

:: 8. 组装新的 PATH
set "NewUserPath=!CurrentUserPath!"
if "!NewUserPath!"=="" (
    set "NewUserPath=%%ipzu_handy_tools_win%%"
) else (
    set "NewUserPath=!NewUserPath!;%%ipzu_handy_tools_win%%"
)

echo [INFO] 准备写入新的 PATH:
echo !NewUserPath!
echo.

:: 9. setx 写入注册表.
setx Path "!NewUserPath!" >nul
if %ERRORLEVEL% neq 0 (
    echo [错误] 写入注册表失败，脚本退出.
    pause
    goto :EOF
)

echo [完成] 写入完成. 需关闭-重新打开终端,后生效 !!
echo.
pause
goto :EOF
