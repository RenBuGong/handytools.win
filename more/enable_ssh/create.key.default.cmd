@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

:: 检查OpenSSH是否安装
where ssh-keygen >nul 2>nul
if %errorlevel% neq 0 (
    echo OpenSSH未安装。请先安装OpenSSH客户端.
    echo 可以通过 设置 -> 应用 -> 可选功能 -> 添加功能 -> OpenSSH 客户端 来安装.
    pause
    exit /b 1
)

:: 询问用户邮箱
set /p EMAIL="请输入您的邮箱 (直接回车使用默认值 no-reply@example.com): "
if "!EMAIL!"=="" set EMAIL=no-reply@example.com

:: 如果希望使用默认算法，则不传 -t 参数
:: 修改文件保存名称，不写死为 id_rsa，而是使用中性名称 id_sshkey
set "KEY_PATH=%cd%\id_sshkey"

echo 正在生成SSH密钥...
ssh-keygen -C "!EMAIL!" -f "%KEY_PATH%" -N ""
if %errorlevel% equ 0 (
    echo.
    echo SSH密钥生成成功!
    echo 私钥保存在: %KEY_PATH%
    echo 公钥保存在: %KEY_PATH%.pub
    echo.
    echo 公钥内容如下:
    type "%KEY_PATH%.pub"
) else (
    echo 生成SSH密钥时出错.
)

echo.
pause
