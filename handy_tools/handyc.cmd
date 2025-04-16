@echo off
chcp 65001 >nul
rem 检查是否需要显示帮助信息.
if "%1"=="-h" goto :ShowHelp
if "%1"=="--help" goto :ShowHelp
if "%1"=="/?" goto :ShowHelp
goto :exec_call
:ShowHelp
call %~dp0..\_lib\remote_kit.cmd -h %~n0 __local__
exit /b 0
:exec_call



::                                                           ↓修改这里即可
@echo off  & call  %~dp0..\_lib\remote_kit.cmd  __local__    %~dp0             %1 & exit /b


