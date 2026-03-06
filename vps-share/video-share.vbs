Set args = WScript.Arguments
If args.Count < 1 Then WScript.Quit 1
path = args(0)

cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Sta -File ""C:\Tools\share-video.ps1"" """ & path & """"
CreateObject("WScript.Shell").Run cmd, 0, False