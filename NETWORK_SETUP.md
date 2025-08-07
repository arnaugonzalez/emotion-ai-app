# Network Configuration Guide

## Quick Setup for Physical Device Testing

### 1. Start the Backend
```bash
cd ../emotionai-api
docker-compose up -d
```

### 2. Find Your Machine's IP
```bash
ipconfig
# Look for "Wi-Fi" adapter IPv4 address (usually 192.168.x.x)
```

### 3. Run Flutter App

#### Option A: Using Scripts (Recommended)
```bash
# For physical device
scripts/run_physical.bat

# For emulator
scripts/run_emulator.bat
```

#### Option B: Manual Command
```bash
# Replace 192.168.2.53 with your actual IP
flutter run --dart-define=DOCKER_HOST=192.168.2.53 --dart-define=DEVICE_TYPE=physical
```

#### Option C: VS Code Launch Configurations
1. Open VS Code
2. Go to Run & Debug (Ctrl+Shift+D)
3. Select "Flutter (Physical Device - Manual IP)"
4. Update IP in launch.json if needed

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ENVIRONMENT` | `development` | App environment |
| `BACKEND_TYPE` | `local` | Backend type (local/docker/deployed) |
| `DEVICE_TYPE` | `auto` | Device type (physical/emulator/desktop) |
| `DOCKER_HOST` | `192.168.2.53` | Your machine's IP address |

## Device Types

- **physical**: Physical Android/iOS device → Use machine IP
- **emulator**: Android emulator → Use `10.0.2.2`
- **desktop**: Windows/macOS/Linux → Use `localhost`

## Troubleshooting

### Connection Timeout
1. Check backend is running: `docker ps`
2. Test backend: `curl http://YOUR_IP:8000/health`
3. Verify IP in config: Update `DOCKER_HOST` variable
4. Check firewall: Allow port 8000

### Wrong IP in Logs
1. Update `lib/config/api_config.dart` line 26
2. Or use environment variable: `--dart-define=DOCKER_HOST=YOUR_IP`
3. Restart Flutter app completely

### Backend Not Accessible
1. Ensure Docker containers are healthy: `docker ps`
2. Check logs: `docker logs emotionai-api-api-1`
3. Verify network: `docker network ls`

## Example Commands

```bash
# Physical device with custom IP
flutter run --dart-define=DOCKER_HOST=192.168.1.100

# Emulator (automatic IP detection)
flutter run --dart-define=DEVICE_TYPE=emulator

# Desktop development
flutter run --dart-define=DEVICE_TYPE=desktop
```