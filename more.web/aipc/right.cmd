@echo off
:: 请将下面的路径修改为你的实际 VBS 脚本和图标路径
set vbsPath=C:\Path\To\Your\echoPath.vbs
set iconPath=C:\proj\aipc\ipzu.ico

echo 正在为所有文件添加右键菜单项...
reg add "HKCU\Software\Classes\*\shell\AIPCAssistant" /ve /d "AIPC智囊" /f
reg add "HKCU\Software\Classes\*\shell\AIPCAssistant" /v Icon /d "%iconPath%" /f
reg add "HKCU\Software\Classes\*\shell\AIPCAssistant\command" /ve /d "\"wscript.exe\" \"%vbsPath%\" \"%1\"" /f

echo 正在为文件夹添加右键菜单项...
reg add "HKCU\Software\Classes\Directory\shell\AIPCAssistant" /ve /d "AIPC智囊" /f
reg add "HKCU\Software\Classes\Directory\shell\AIPCAssistant" /v Icon /d "%iconPath%" /f
reg add "HKCU\Software\Classes\Directory\shell\AIPCAssistant\command" /ve /d "\"wscript.exe\" \"%vbsPath%\" \"%1\"" /f

echo 正在为目录背景（空白处）添加右键菜单项...
reg add "HKCU\Software\Classes\Directory\Background\shell\AIPCAssistant" /ve /d "AIPC智囊" /f
reg add "HKCU\Software\Classes\Directory\Background\shell\AIPCAssistant" /v Icon /d "%iconPath%" /f
:: 在目录背景中使用 %V 传递当前文件夹路径
reg add "HKCU\Software\Classes\Directory\Background\shell\AIPCAssistant\command" /ve /d "\"wscript.exe\" \"%vbsPath%\" \"%V\"" /f

echo 右键菜单项 "AIPC智囊" 已成功添加到所有相关位置！
pause
