@echo off
echo ==========================================
echo      BARBERSHOP GENTLEMAN DEPLOYMENT
echo ==========================================
echo.
echo 1. Cleaning project...
call flutter clean
if %errorlevel% neq 0 (
    echo Error cleaning project.
    pause
    exit /b %errorlevel%
)

echo.
echo 2. Building Web App (Release Mode)...
echo    This may take a few minutes. Please wait.
call flutter build web --release
if %errorlevel% neq 0 (
    echo Error building web app.
    pause
    exit /b %errorlevel%
)

echo.
echo 3. Deploying to Firebase Hosting...
call firebase deploy
if %errorlevel% neq 0 (
    echo Error deploying to Firebase.
    echo Make sure you are logged in (firebase login).
    pause
    exit /b %errorlevel%
)

echo.
echo ==========================================
echo      DEPLOYMENT SUCCESSFUL!  🚀
echo ==========================================
echo.
pause
