Option Explicit

' --- Configurable Parameters (可配置参数) ---
Dim DelayTime, ProcessName, SearchArgument, ExecutableCommand
DelayTime = 13000                ' 延时毫秒 (e.g., 2100 = 2.1 seconds)
ProcessName = "frpc.exe"        ' 要检查的进程名称
SearchArgument = "-c frp.ini"   ' 用于识别进程的唯一参数
ExecutableCommand = "C:\sysPlus\frp\frpc.exe -c frp.ini"  ' 如果进程未运行，执行的命令

' --- End of Configuration ---

' Delay before execution
WScript.Sleep DelayTime

Dim objWMIService, colProcesses, objProcess, processFound, objShell
processFound = False

' Connect to WMI and query all processes with the specified process name
Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
Set colProcesses = objWMIService.ExecQuery("SELECT ProcessId, CommandLine FROM Win32_Process WHERE Name = '" & ProcessName & "'")

For Each objProcess In colProcesses
    If Not IsNull(objProcess.CommandLine) Then
        If InStr(objProcess.CommandLine, SearchArgument) > 0 Then
            processFound = True
            MsgBox "Existing " & ProcessName & " process is running." & vbCrLf & _
                   "PID: " & objProcess.ProcessId & vbCrLf & _
                   "CommandLine: " & objProcess.CommandLine, vbInformation, ProcessName & " Status"
            Exit For
        End If
    End If
Next

If processFound Then
    WScript.Quit
End If

' Create a Shell object and run the command with a hidden window (0 = hidden)
Set objShell = CreateObject("Wscript.Shell")
objShell.Run ExecutableCommand, 0, False

MsgBox ProcessName & " started.", vbInformation, "Successful"
