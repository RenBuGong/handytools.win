@echo off
chcp 65001  >nul
:: -------------------------------------------------------------------------
:: 文件: pathhererm.cmd
:: 用途: 将指定路径或当前工作目录从当前用户的 PATH(注册表HKCU\Environment) 中删除.
::       如果提供参数 %1，则删除参数指定的路径，否则删除当前工作目录.
::       会删除PATH中所有出现的指定路径.
:: -------------------------------------------------------------------------
setlocal EnableDelayedExpansion

echo Remove this path from your user %%PATH%%
echo.
set "TIME_STAMP=[%date% %time%]"
:: 1. 获取要删除的路径，去掉末尾的反斜杠.
if "%~1"=="" (
    :: 如果没有参数，使用当前工作目录.
    set "TARGET_PATH=%cd%"
    echo 将从PATH中删除当前工作目录: %cd%
) else (
    :: 如果有参数，使用指定的路径
    set "TARGET_PATH=%~1"
    echo 将从PATH中删除指定路径: %~1
)

:: 确保路径末尾没有"\"
if "%TARGET_PATH:~-1%"=="\" set "TARGET_PATH=%TARGET_PATH:~0,-1%"

:: 2. 从注册表读取用户级 PATH (可能包含空格，所以用 tokens=1,2,*).
for /f "tokens=1,2,* skip=2" %%a in ('reg query HKCU\Environment /v PATH 2^>nul') do (
    if /i "%%a"=="PATH" (
        set "USER_PATH=%%c"
    )
)
if not defined USER_PATH (
    echo 没有找到用户级 PATH 环境变量.
    goto :EOF
)

:: 3. 备份当前用户级 PATH 到脚本同目录的 .bak.txt 文件中.
echo USER-PATH_PRE-DEL %TIME_STAMP% %USER_PATH% >> "%~dp0pathhere.backup.log"
echo 当前用户级 PATH:
echo %USER_PATH%
echo 已备份当前 PATH 到 %~dp0pathhere.backup.log

:: 4. 将用户 PATH 字符串首尾加分号，便于精确匹配和替换.
set "temp=;%USER_PATH%;"

:: 5. 删除路径：把所有";目标路径;"替换为";"
:removeTargetPath
if not "!temp!"=="!temp:;%TARGET_PATH%;=;!" (
    set "temp=!temp:;%TARGET_PATH%;=;!"
    goto removeTargetPath
)

:: 6. 循环去除可能产生的双分号.
:removeDouble
if not "!temp!"=="!temp:;;=;!" (
    set "temp=!temp:;;=;!"
    goto removeDouble
)

:: 7. 移除开头和结尾多余的分号.
if "!temp:~0,1!"==";" set "temp=!temp:~1!"
if "!temp:~-1!"==";" set "temp=!temp:~0,-1!"

:: 8. 更新用户级 PATH
setx PATH "!temp!" >/nul
echo 用户级 PATH 已更新，新值为:
echo !temp!

endlocal
pause
