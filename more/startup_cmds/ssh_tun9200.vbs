Option Explicit

' Configuration parameters - Modify here for different servers or ports
Dim DELAY_TIME : DELAY_TIME = 2                 ' Startup delay (milliseconds)
Dim LOCAL_PORT : LOCAL_PORT = "8888"            ' Local port
Dim REMOTE_PORT : REMOTE_PORT = "8888"          ' Remote port
Dim REMOTE_BIND : REMOTE_BIND = "0.0.0.0"       ' Remote binding address
Dim SSH_SERVER : SSH_SERVER = "1.2.3.4"         ' SSH server address
Dim SSH_USER : SSH_USER = "user"                ' SSH username
Dim SSH_PORT : SSH_PORT = "22"                  ' SSH port

' Delay startup
WScript.Sleep DELAY_TIME

Dim searchArg, objWMIService, colProcesses, objProcess, processFound, sshCommand, objShell

' Define the unique argument used to identify the SSH tunnel process
searchArg = "-R " & REMOTE_BIND & ":" & REMOTE_PORT & ":localhost:" & LOCAL_PORT
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
             "-n -N -T -R " & REMOTE_BIND & ":" & REMOTE_PORT & ":localhost:" & LOCAL_PORT & " -g -p" & SSH_PORT & " " & SSH_USER & "@" & SSH_SERVER

' Create a Shell object and run the SSH command with a hidden window (0 = hidden)
Set objShell = CreateObject("Wscript.Shell")
objShell.Run sshCommand, 0, False

MsgBox "SSH reverse tunnel started.", vbInformation, "Start Successful"
