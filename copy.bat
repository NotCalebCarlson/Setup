xcopy "Source.ps1" "C:\Users\Administrator\Desktop" /Y /F
xcopy "Auto Updates.bat" "C:\Users\Administrator\Desktop" /Y /F
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\Administrator\Desktop\Source.ps1"
