@echo off
chcp 65001 > nul
:: 请以管理员身份运行此脚本！
:: 请将下面的 "C:\Windows\System32\notepad.exe" 替换为你实际的应用程序路径
set "appPath=C:\Windows\System32\notepad.exe"

echo 正在添加右键菜单项 "AIPC智囊" ...

:: 为“目录”右键菜单添加项
reg add "HKCU\Software\Classes\Directory\shell\AIPCAssistant" /ve /d "AIPC智囊" /f
reg add "HKCU\Software\Classes\Directory\shell\AIPCAssistant\command" /ve /d "\"%appPath%\" \"%1\"" /f

:: 为“目录背景”（即在目录空白处右键）添加项
reg add "HKCU\Software\Classes\Directory\Background\shell\AIPCAssistant" /ve /d "AIPC智囊" /f
reg add "HKCU\Software\Classes\Directory\Background\shell\AIPCAssistant\command" /ve /d "\"%appPath%\" \"%V\"" /f

echo 注册表项添加完成。

echo 正在调整右键菜单显示方式，尝试让菜单项直接显示在主菜单中...

:: 针对 “目录”右键菜单项调整
powershell -Command "Rename-Item -LiteralPath 'HKCU:\Software\Classes\Directory\shell\AIPCAssistant' -NewName 'extract' -ErrorAction SilentlyContinue"
powershell -Command "Set-ItemProperty -LiteralPath 'HKCU:\Software\Classes\Directory\shell\extract' -Name 'AppliesTo' -Value 'NOT .zip' -ErrorAction SilentlyContinue"
powershell -Command "Rename-Item -LiteralPath 'HKCU:\Software\Classes\Directory\shell\extract' -NewName 'AIPCAssistant' -ErrorAction SilentlyContinue"
powershell -Command "Remove-ItemProperty -LiteralPath 'HKCU:\Software\Classes\Directory\shell\AIPCAssistant' -Name 'AppliesTo' -ErrorAction SilentlyContinue"

:: 针对 “目录背景”右键菜单项调整
powershell -Command "Rename-Item -LiteralPath 'HKCU:\Software\Classes\Directory\Background\shell\AIPCAssistant' -NewName 'extract' -ErrorAction SilentlyContinue"
powershell -Command "Set-ItemProperty -LiteralPath 'HKCU:\Software\Classes\Directory\Background\shell\extract' -Name 'AppliesTo' -Value 'NOT .zip' -ErrorAction SilentlyContinue"
powershell -Command "Rename-Item -LiteralPath 'HKCU:\Software\Classes\Directory\Background\shell\extract' -NewName 'AIPCAssistant' -ErrorAction SilentlyContinue"
powershell -Command "Remove-ItemProperty -LiteralPath 'HKCU:\Software\Classes\Directory\Background\shell\AIPCAssistant' -Name 'AppliesTo' -ErrorAction SilentlyContinue"

echo 调整完成，右键菜单项 "AIPC智囊" 应直接显示在主菜单中。
pause
