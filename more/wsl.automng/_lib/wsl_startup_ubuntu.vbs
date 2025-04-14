'latency 21 sec
WScript.Sleep 21000

Dim wsl_name : wsl_name = "ubuntu"

CreateObject("Shell.Application").ShellExecute "wsl.exe", "-d " & wsl_name & " -e bash -c ""pgrep -u $(whoami) -x dbus-daemon ||dbus-launch true &>/dev/null""", "", "open", 0

WScript.CreateObject("WScript.Shell").Run "wsl.exe -d " & wsl_name , 1, True
