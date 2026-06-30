@echo off
cd /d "%~dp0"
call flutter clean
call flutter pub get
call flutter build apk
pause
