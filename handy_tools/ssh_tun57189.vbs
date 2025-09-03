Option Explicit

' 延时 21 秒
WScript.Sleep 1000


Dim searchArg, objWMIService, colProcesses, objProcess, processFound, sshCommand, objShell

' Define the unique argument used to identify the SSH tunnel process
searchArg = "-R 0.0.0.0:57189:localhost:3389"
processFound = False

' Connect to WMI and query all processes named "ssh.exe"
Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
Set colProcesses = objWMIService.ExecQuery("SELECT ProcessId, CommandLine FROM Win32_Process WHERE Name = 'ssh.exe'")

For Each objProcess In colProcesses
    If Not IsNull(objProcess.CommandLine) Then
        If InStr(objProcess.CommandLine, searchArg) > 0 Then
            processFound = True
            MsgBox "Existing SSH reverse tunnel process is running." & vbCrLf & _
                   "PID: " & objProcess.ProcessId & vbCrLf & _
                   "CommandLine: " & objProcess.CommandLine, vbInformation, "SSH Tunnel Status"
            Exit For
        End If
    End If
Next

If processFound Then
    WScript.Quit
End If

' Construct the SSH command. Ensure that 'ssh.exe' is in your system PATH or specify the full path.
sshCommand = "ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ServerAliveCountMax=3 " & _
             "-o ExitOnForwardFailure=yes -o ControlMaster=no -o ControlPath=none " & _
             "-n -N -T -R 0.0.0.0:57189:localhost:3389 -g -p22 ubuntu@175.178.47.41"

' Create a Shell object and run the SSH command with a hidden window (0 = hidden)
Set objShell = CreateObject("Wscript.Shell")
objShell.Run sshCommand, 0, False

MsgBox "SSH reverse tunnel started.", vbInformation, "Start Successful"
