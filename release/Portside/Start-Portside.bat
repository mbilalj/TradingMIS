@echo off
setlocal
cd /d "%~dp0"
if "%SERVER_PORT%"=="" set SERVER_PORT=8080

where java >nul 2>nul
if errorlevel 1 (
  echo Java 21 or newer is required but was not found. Install it from https://adoptium.net and run this again.
  pause & exit /b 1
)

if not exist data mkdir data
if not exist data\jwt.secret (
  powershell -NoProfile -Command "[guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N')" > data\jwt.secret
)
set /p JWT_SECRET=<data\jwt.secret
set SPRING_PROFILES_ACTIVE=standalone

echo Starting Portside on http://localhost:%SERVER_PORT% ...  (close this window to stop)
start "" /b cmd /c "timeout /t 12 /nobreak >nul & start http://localhost:%SERVER_PORT%"
java -jar portside.jar
pause
