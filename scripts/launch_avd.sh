#!/bin/bash

echo "🚀 Launching EmotionAI for Android Virtual Device (AVD)..."
echo

flutter run \
  --dart-define=ENVIRONMENT=development_emulator \
  --dart-define=BACKEND_TYPE=local \
  --dart-define=DEVICE_TYPE=emulator

echo
echo "✅ Launch complete!" 