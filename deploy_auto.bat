@echo off
echo Running Deployment...

echo 1. Cleaning...
call flutter clean
if %errorlevel% neq 0 ( exit /b %errorlevel% )

echo 2. Building Web...
call flutter build web --release
if %errorlevel% neq 0 ( exit /b %errorlevel% )

echo 3. Deploying...
call firebase deploy
if %errorlevel% neq 0 ( exit /b %errorlevel% )

echo Deployment Complete.
