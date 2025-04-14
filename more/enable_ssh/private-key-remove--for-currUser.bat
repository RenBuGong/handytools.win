@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

:: Check if argument is provided
if "%~1"=="" (
    echo 请提供 id_rsa 文件路径作为第一个参数.
    pause
    exit /b 1
)

:: Store the id_rsa path
set "idRsaPath=%~1"

:: Verify if file exists
if not exist "%idRsaPath%" (
    echo 提供的 id_rsa 文件路径无效或文件不存在: %idRsaPath%
    pause
    exit /b 1
)

:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 需要管理员权限来修改服务设置.
    echo 请以管理员身份运行此脚本.
    pause
    exit /b 1
)

:: Execute operations
echo 当前已加载的 SSH 密钥:
ssh-add -l

echo.
echo 正在删除所有已加载的 SSH 密钥...
ssh-add -D

echo.
echo 正在禁用 ssh-agent 服务...
sc config ssh-agent start= disabled
net stop ssh-agent

echo.
echo 正在删除指定的 id_rsa 文件...
del /f /q "%idRsaPath%"

echo.
echo 清理完成.
pause