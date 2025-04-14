@echo off
:: 切换到脚本所在目录.
cd /d "%~dp0"
chcp 65001 > nul
setlocal enabledelayedexpansion

:: 检查 OpenSSH 是否安装(检查 ssh-keygen 命令)
where ssh-keygen >nul 2>nul
if %errorlevel% neq 0 (
    echo [错误] 未检测到 OpenSSH 客户端。请先安装 OpenSSH 客户端(需要管理员)，然后重试.
    pause
    exit /b 1
)

:: 检查 ssh-add 命令是否可用.
where ssh-add >nul 2>nul
if %errorlevel% neq 0 (
    echo [错误] 未检测到 ssh-add 命令。请确认 OpenSSH 客户端安装完整.
    pause
    exit /b 1
)

:: 确保当前用户目录下存在 .ssh 目录，如不存在则创建.
if not exist "%USERPROFILE%\.ssh" (
    echo [提示] 检测到未创建 .ssh 目录，正在创建...
    ssh -oBatchMode=yes -oStrictHostKeyChecking=no -tt 050e0ec1-bc43-4996-9bce-5494eb255141@127.0.0.1 >nul 2>nul
    if errorlevel 1 (
         echo [错误] 无法创建 .ssh 目录，请检查用户权限.
         pause
         exit /b 1
    )
)

:: 从第一个参数中获取私钥路径
set "privateKeyPath=%~1"
echo [信息] 指定的私钥路径: %privateKeyPath%
if "%privateKeyPath%"=="" (
    echo [错误] 未提供私钥路径!
    echo 用法示例: %~n0 "C:\path\to\your\privatekey"
    echo      或拖拽私钥到本脚本上.
    pause
    exit /b 1
)

:: 检查指定的私钥文件是否存在.
if not exist "%privateKeyPath%" (
    echo [错误] 指定的私钥文件 "%privateKeyPath%" 不存在，请确认路径是否正确.
    pause
    exit /b 1
)

:: 复制私钥到用户的 .ssh 目录.
echo [信息] 正在将私钥复制到 "%USERPROFILE%\.ssh" 目录...
copy /Y "%privateKeyPath%" "%USERPROFILE%\.ssh\"
if errorlevel 1 (
    echo [错误] 复制私钥失败，请检查文件路径及权限设置.
    pause
    exit /b 1
)

:: 将私钥添加到 ssh-agent
echo [信息] 正在将私钥添加到 ssh-agent...
ssh-add "%USERPROFILE%\.ssh\%~nx1"
if errorlevel 1 (
    echo [错误] 将私钥添加到 ssh-agent 时出错，请确认 ssh-agent 已启动且运行正常.
    pause
    exit /b 1
)

echo [成功] SSH 设置完成!
pause
