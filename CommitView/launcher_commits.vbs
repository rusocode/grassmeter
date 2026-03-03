Dim shell, fso, skinPath, parentPath, cmd
Set shell = CreateObject("WScript.Shell")
Set fso   = CreateObject("Scripting.FileSystemObject")
skinPath   = fso.GetParentFolderName(WScript.ScriptFullName)
parentPath = fso.GetParentFolderName(skinPath)
cmd = "powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -NonInteractive" & _
      " -File """ & parentPath & "\FetchCommits.ps1"""
shell.Run cmd, 0, False
