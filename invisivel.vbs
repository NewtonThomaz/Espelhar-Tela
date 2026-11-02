Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run Chr(34) & scriptDir & "\transmitting.bat" & Chr(34), 0, False
Set WshShell = Nothing
