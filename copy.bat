xcopy "Source.ps1" "C:\Users\Administrator\Desktop" /Y /F
xcopy "Auto Updates.bat" "C:\Users\Administrator\Desktop" /Y /F
xcopy "Cleanup.bat" "C:\Users\Administrator\Desktop" /Y /F
start /min "" cmd /c "powershell.exe -ExecutionPolicy bypass -File C:\Users\Administrator\Desktop\Source.ps1" & exit