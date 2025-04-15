@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

set "TIME_STAMP=[%date% %time%]"
echo 1.
:: 1. 读取当前用户 PATH
set "USER_PATH="
for /f "tokens=1,2,* skip=2" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do (
    if /i "%%a"=="PATH" (
        set "USER_PATH=%%c"
    )
)

if not defined USER_PATH (
    echo [INFO] 没有找到用户级 PATH 环境变量，无需处理.
    goto removeVar
)

echo [INFO] 当前用户级 PATH:
echo %USER_PATH%
echo.

:: 2. 备份当前 PATH 到同目录 __path_backup.log
echo USER-PATH_PRE-DEL %TIME_STAMP%:  %USER_PATH% >> "%~dp0path_backup.log"

:: 3. 为了方便替换操作，前后各加一个分号.
set "temp=;%USER_PATH%;"

:: 4. 将其中的 `;%ipzu_handy_tools_win%;` 替换为空的分号.
::
::   - 注意大小写不敏感的话可以改成:
::     set "temp=!temp:;%ipzu_handy_tools_win%;=;!"
::     但理论上 PATH 内部会存成 `%ipzu_handy_tools_win%`（小写）,
::   - 如果你不确定大小写，就可以 `findstr /i` 判断,
::     这里先按上面添加时的写法，使用小写替换.
::
set "temp=!temp:;%%ipzu_handy_tools_win%%;=;!"

:: 如果不确定还可能出现 `%ipzu_handy_tools_win%` 在 PATH 的开头/结尾等情况.
:: 也可以多做几次替换:
::   set "temp=!temp:;%ipzu_handy_tools_win% =;!"
::   set "temp=!temp: %ipzu_handy_tools_win%;=;!"
:: （具体情况看你添加时的逻辑而定）.

:: 5. 去除可能产生的双分号.
:removeDouble
if not "!temp!"=="!temp:;;=;!" (
    set "temp=!temp:;;=;!"
    goto removeDouble
)

:: 6. 如果开头末尾有分号，去掉.
if "!temp:~0,1!"==";" set "temp=!temp:~1!"
if "!temp:~-1!"==";" set "temp=!temp:~0,-1!"

:: 7. 更新 PATH
setx PATH "!temp!" >nul
echo [完成] 已从 PATH 中移除 "%%ipzu_handy_tools_win%%" 引用.
echo [INFO] 新的 PATH:
echo !temp!
echo.

:removeVar
echo.
echo.
echo.
echo 2.
:: 8. 删除 ipzu_handy_tools_win 这个变量本身.
reg delete "HKCU\Environment" /v "ipzu_handy_tools_win" /f >nul 2>nul
echo [完成] 已删除用户环境变量 %%ipzu_handy_tools_win%%

echo.
pause
endlocal
goto :EOF
