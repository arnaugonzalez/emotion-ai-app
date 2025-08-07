@echo off
echo 📱 Launching EmotionAI for Physical Android Device...
echo.

flutter run ^
  --dart-define=ENVIRONMENT=development ^
  --dart-define=BACKEND_TYPE=local ^
  --dart-define=DEVICE_TYPE=physical

echo.
echo ✅ Launch complete!
pause 