@echo off
chcp 65001 >nul
rem 检查是否需要显示帮助信息.
if "%1"=="-h" goto :ShowHelp
if "%1"=="--help" goto :ShowHelp
if "%1"=="/?" goto :ShowHelp
goto :exec_call
:ShowHelp
call __sub.cmd -h %~n0
exit /b 0
:exec_call



::调用子脚本, 并传入参数：           1-端口   2-ip地址        3-默认用户   4-ssh-key                        5-指定用户名  6-要打开的路径  7-可以留空否则会启动vscode进行远程打开，如果%3非空则使用SFTP同步本地目录%3 需要先安装 SFTP/FTP sync  @Natizyskunk 插件.
call  %~dp0..\_lib\remote_kit.cmd  22       example.com    h           %USERPROFILE%\.ssh\id_rsa        %1           %2             %3
