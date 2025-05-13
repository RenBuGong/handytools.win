' echoPath.vbs
Option Explicit
Dim args, targetPath
Set args = WScript.Arguments

If args.Count > 0 Then
    targetPath = args(0)
    MsgBox "click is: " & targetPath, vbInformation, "path info"
Else
    MsgBox "no path got", vbExclamation, "err"
End If
