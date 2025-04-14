Set objShell = CreateObject("WScript.Shell")
' 切换到 .\_lib 目录
objShell.CurrentDirectory = ".\_lib"
' 执行 PowerShell 命令
objShell.Run "PowerShell.exe -NoProfile -Command ""& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File """"main.ps1""""'}""", 0, False
