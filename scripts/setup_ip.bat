@echo off
echo ============================================
echo     EmotionAI Network Configuration Setup
echo ============================================
echo.

echo Detecting your machine's IP address...
echo.

REM Get current active IP address (192.168.x.x range)
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr "IPv4.*192.168"') do (
    for /f "tokens=1" %%j in ("%%i") do set CURRENT_IP=%%j
)

echo Network Information:
echo -------------------
if defined CURRENT_IP (
    echo Current IP: %CURRENT_IP%
    set RECOMMENDED_IP=%CURRENT_IP%
    echo Recommended IP: %CURRENT_IP%
) else (
    set RECOMMENDED_IP=192.168.2.53
    echo No network detected. Using default: %RECOMMENDED_IP%
)

echo.
echo ============================================
echo     Configuration Instructions
echo ============================================
echo.
echo 1. Update your Flutter configuration:
echo    - Edit: lib/config/api_config.dart
echo    - Line 26: defaultValue: '%RECOMMENDED_IP%'
echo.
echo 2. Or run with environment variable:
echo    flutter run --dart-define=DOCKER_HOST=%RECOMMENDED_IP%
echo.
echo 3. Verify backend is running:
echo    curl http://%RECOMMENDED_IP%:8000/health
echo.
echo ============================================

pause