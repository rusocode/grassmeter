Dim shell, rootPath, cmd
Set shell  = CreateObject("WScript.Shell")
rootPath   = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)

cmd = "powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden" & _
      " -File """ & rootPath & "\Settings.ps1"""

shell.Run cmd, 0, False
