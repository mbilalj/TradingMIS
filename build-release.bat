@echo off
setlocal
cd /d "%~dp0"
echo == Building frontend ==
pushd frontend
call npm install || goto :fail
call npm run build || goto :fail
popd
echo == Bundling frontend into backend ==
rmdir /s /q backend\src\main\resources\static 2>nul
mkdir backend\src\main\resources\static
xcopy /e /i /q frontend\dist backend\src\main\resources\static >nul
echo == Building backend jar ==
pushd backend
call .\mvnw.cmd -q clean package -DskipTests || goto :fail
popd
echo == Assembling release\Portside ==
rmdir /s /q release 2>nul
mkdir release\Portside
copy backend\target\trading-mis-0.0.1-SNAPSHOT.jar release\Portside\portside.jar >nul
copy release-template\* release\Portside\ >nul
echo.
echo Done. Copy the folder release\Portside to any machine with Java 21+ and run Start-Portside.bat
exit /b 0
:fail
echo BUILD FAILED
exit /b 1
