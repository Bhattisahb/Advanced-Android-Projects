@echo off
setlocal

cd /d "%~dp0"

where node >nul 2>nul
if errorlevel 1 (
  echo node was not found. Install Node.js LTS from https://nodejs.org/ first.
  pause
  exit /b 1
)

if not exist "serviceAccountKey.json" if not exist "*firebase-adminsdk*.json" (
  echo Firebase service account JSON file was not found in this folder.
  echo Download your Firebase service account key and put it here.
  pause
  exit /b 1
)

node backup.js
pause
