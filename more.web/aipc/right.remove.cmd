@echo off
chcp 65001 > nul
:: 从当前用户注册表中移除 "AIPC智囊" 右键菜单项（针对所有文件、文件夹和目录背景）
reg delete "HKCU\Software\Classes\*\shell\AIPCAssistant" /f
reg delete "HKCU\Software\Classes\Directory\shell\AIPCAssistant" /f
reg delete "HKCU\Software\Classes\Directory\Background\shell\AIPCAssistant" /f

echo 右键菜单项 "AIPC智囊" 已成功移除！
pause
