@echo off
chcp 65001 > nul
:: 请以管理员身份运行此脚本！

echo 正在移除右键菜单项 "AIPC智囊" ...

reg delete "HKCU\Software\Classes\Directory\shell\AIPCAssistant" /f
reg delete "HKCU\Software\Classes\Directory\Background\shell\AIPCAssistant" /f

echo 右键菜单项 "AIPC智囊" 已移除。
pause
