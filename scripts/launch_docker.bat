@echo off
echo 🐳 Launching EmotionAI with Docker Backend...
echo.

set /p DOCKER_HOST="Enter Docker host IP (default: 192.168.1.180): "
if "%DOCKER_HOST%"=="" set DOCKER_HOST=192.168.1.180

set /p DEVICE_TYPE="Device type [emulator/physical] (default: physical): "
if "%DEVICE_TYPE%"=="" set DEVICE_TYPE=physical

if "%DEVICE_TYPE%"=="emulator" (
    set ENV=development_emulator
    set DOCKER_IP=10.0.2.2
) else (
    set ENV=development
    set DOCKER_IP=%DOCKER_HOST%
)

echo.
echo 🔧 Configuration:
echo   Environment: %ENV%
echo   Backend: Docker
echo   Device: %DEVICE_TYPE%
echo   Docker Host: %DOCKER_IP%
echo.

flutter run ^
  --dart-define=ENVIRONMENT=%ENV% ^
  --dart-define=BACKEND_TYPE=docker ^
  --dart-define=DEVICE_TYPE=%DEVICE_TYPE% ^
  --dart-define=DOCKER_HOST=%DOCKER_IP%

echo.
echo ✅ Launch complete!
pause 