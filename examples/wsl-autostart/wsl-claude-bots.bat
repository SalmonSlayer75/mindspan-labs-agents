@echo off
REM Start WSL and Claude bots on Windows login.
REM
REM Place this file in your Windows Startup folder:
REM   %AppData%\Microsoft\Windows\Start Menu\Programs\Startup\
REM
REM Or use it as the Action in a Windows Scheduled Task (trigger: At log on).
REM
REM The /min flag starts WSL minimized so it doesn't pop up a terminal window.

start /min wsl.exe -d Ubuntu -e /home/yourusername/bin/wsl-boot.sh
