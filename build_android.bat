@echo off
echo Building Android App Bundle...
call flutter build appbundle
if %errorlevel% neq 0 (
    echo Build failed!
    pause
    exit /b %errorlevel%
)
echo.
echo Build Successful!
echo The file is located at: build\app\outputs\bundle\release\app-release.aab
echo.
pause
