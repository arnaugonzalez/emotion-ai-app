# Launch Configuration System

## Overview

The EmotionAI app now supports flexible launch configurations that automatically determine the correct backend URL based on how the app is launched. This system eliminates the need to manually change URLs in the code when switching between different development environments.

## Quick Start

### VS Code Launch Configurations

Use the Run and Debug panel in VS Code to select from these pre-configured options:

- **Flutter: Development (AVD/Emulator)** - For Android Virtual Device
- **Flutter: Development (Physical Device)** - For physical Android device
- **Flutter: Docker Backend (Physical)** - Physical device with Docker backend
- **Flutter: Docker Backend (AVD)** - Emulator with Docker backend
- **Flutter: Staging Environment** - Staging server
- **Flutter: Production Environment** - Production server
- **Flutter: Local Development (Desktop)** - Desktop/web development

### Command Line Launch Scripts

#### Windows (.bat files)
```bash
# Launch for AVD
scripts\launch_avd.bat

# Launch for physical device
scripts\launch_physical.bat

# Launch with Docker backend (interactive)
scripts\launch_docker.bat
```

#### Unix/Linux/macOS (.sh files)
```bash
# Launch for AVD
./scripts/launch_avd.sh

# Launch for physical device
./scripts/launch_physical.sh

# Universal launch script with options
./scripts/launch.sh --help
```

## Universal Launch Script

The `scripts/launch.sh` script provides the most flexibility:

### Quick Commands
```bash
./scripts/launch.sh --avd           # Android Virtual Device
./scripts/launch.sh --physical      # Physical Android device
./scripts/launch.sh --docker        # Docker backend
./scripts/launch.sh --staging       # Staging environment
./scripts/launch.sh --production    # Production environment
```

### Advanced Usage
```bash
# Custom Docker host for physical device
./scripts/launch.sh --backend docker --device physical --docker-host 192.168.1.100

# Staging with release build
./scripts/launch.sh --staging --release

# Custom configuration
./scripts/launch.sh \
  --environment development \
  --backend local \
  --device emulator \
  --mode profile
```

### All Options
```bash
Options:
  -h, --help              Show help message
  -b, --backend TYPE      Backend type: local, docker, deployed
  -d, --device TYPE       Device type: auto, emulator, physical, desktop
  -e, --environment ENV   Environment: development, staging, production
  -H, --docker-host HOST  Docker host IP (default: 192.168.1.180)
  -m, --mode MODE         Build mode: debug, profile, release
  --release               Build in release mode
  --profile               Build in profile mode
```

## Manual Command Line Launch

You can also launch manually with `flutter run` and `--dart-define` parameters:

```bash
# AVD/Emulator
flutter run \
  --dart-define=ENVIRONMENT=development_emulator \
  --dart-define=BACKEND_TYPE=local \
  --dart-define=DEVICE_TYPE=emulator

# Physical Device
flutter run \
  --dart-define=ENVIRONMENT=development \
  --dart-define=BACKEND_TYPE=local \
  --dart-define=DEVICE_TYPE=physical

# Docker Backend
flutter run \
  --dart-define=ENVIRONMENT=development \
  --dart-define=BACKEND_TYPE=docker \
  --dart-define=DEVICE_TYPE=physical \
  --dart-define=DOCKER_HOST=192.168.1.180

# Staging Environment
flutter run \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=BACKEND_TYPE=deployed \
  --dart-define=DEVICE_TYPE=any

# Production Environment
flutter run \
  --dart-define=ENVIRONMENT=production \
  --dart-define=BACKEND_TYPE=deployed \
  --dart-define=DEVICE_TYPE=any
```

## Configuration Parameters

### ENVIRONMENT
- `development` - Local development for physical device
- `development_emulator` - Local development for Android emulator
- `development_local` - Local development for desktop/web
- `staging` - Staging server environment
- `production` - Production server environment

### BACKEND_TYPE
- `local` - Local backend server (usually on port 8000)
- `docker` - Docker containerized backend
- `deployed` - Remote deployed backend (staging/production)

### DEVICE_TYPE
- `auto` - Automatically detect device type
- `emulator` - Android Virtual Device (uses 10.0.2.2)
- `physical` - Physical Android device (uses network IP)
- `desktop` - Desktop application (uses localhost)
- `web` - Web browser (uses localhost)
- `any` - Any device type (for deployed backends)

### DOCKER_HOST
- Custom IP address for Docker backend
- Default: `192.168.1.180` for physical devices
- Automatically set to `10.0.2.2` for emulators

## URL Resolution

The system automatically builds the correct backend URL:

| Backend Type | Device Type | Resulting URL |
|--------------|-------------|---------------|
| `local` | `emulator` | `http://10.0.2.2:8000` |
| `local` | `physical` | `http://192.168.1.180:8000` |
| `local` | `desktop` | `http://localhost:8000` |
| `docker` | `emulator` | `http://10.0.2.2:8000` |
| `docker` | `physical` | `http://192.168.1.180:8000` |
| `deployed` | `any` (staging) | `https://staging-api.emotionai.app` |
| `deployed` | `any` (production) | `https://api.emotionai.app` |

## Configuration Validation

The app validates configuration at startup and shows helpful error messages for invalid combinations. Configuration details are printed to the console in development mode.

Example output:
```
🚀 ===== EmotionAI API Configuration =====
📊 Environment: development_emulator
🔧 Backend Type: local
📱 Device Type: emulator
🌐 Base URL: http://10.0.2.2:8000
🔍 Debug Mode: true
📋 Mock Data: true

📡 Key Endpoints:
  🏥 Health: http://10.0.2.2:8000/health/
  🔐 Login: http://10.0.2.2:8000/auth/login
  💬 Chat: http://10.0.2.2:8000/api/v1/chat
  📊 Records: http://10.0.2.2:8000/emotional_records/
========================================
```

## Development Workflow

### For Android Emulator Development
1. Start your Android emulator
2. Start local backend: `cd ../emotionai-api && python simple_main.py`
3. Launch app: `./scripts/launch.sh --avd` or use VS Code "Development (AVD/Emulator)"

### For Physical Device Development
1. Connect your Android device via USB
2. Ensure device and computer are on same network
3. Start local backend: `cd ../emotionai-api && python simple_main.py`
4. Launch app: `./scripts/launch.sh --physical` or use VS Code "Development (Physical Device)"

### For Docker Backend Development
1. Start Docker backend (with appropriate port mapping)
2. Launch app: `./scripts/launch.sh --docker` or use VS Code Docker configurations
3. The script will prompt for Docker host IP if using interactive mode

### For Staging/Production Testing
1. Ensure you have access to staging/production servers
2. Launch app: `./scripts/launch.sh --staging` or `./scripts/launch.sh --production`
3. Use release builds for performance testing: `./scripts/launch.sh --staging --release`

## Troubleshooting

### Common Issues

1. **Cannot connect to backend**
   - Check if backend is running
   - Verify IP addresses (especially for physical devices)
   - Check firewall settings

2. **Wrong URL being used**
   - Verify launch configuration parameters
   - Check console output for actual URL being used
   - Ensure device type detection is correct

3. **Emulator connectivity issues**
   - Ensure you're using `10.0.2.2` for emulator
   - Check if emulator has internet connectivity
   - Try restarting the emulator

4. **Docker backend issues**
   - Verify Docker container is running and accessible
   - Check port mappings (usually port 8000)
   - Ensure Docker host IP is correct

### Debug Mode

In development environments, the app prints detailed configuration information to help with debugging. Check the console output for:
- Resolved backend URL
- Configuration parameters used
- Validation results

### Validation Errors

If you see configuration validation errors:
1. Check that all parameters are spelled correctly
2. Ensure valid combinations (e.g., don't use `deployed` backend with `emulator` device)
3. Verify environment variables are set correctly

## Integration with CI/CD

The launch configuration system works well with CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Build for staging
  run: |
    flutter build apk \
      --dart-define=ENVIRONMENT=staging \
      --dart-define=BACKEND_TYPE=deployed \
      --dart-define=DEVICE_TYPE=any \
      --release

- name: Build for production
  run: |
    flutter build appbundle \
      --dart-define=ENVIRONMENT=production \
      --dart-define=BACKEND_TYPE=deployed \
      --dart-define=DEVICE_TYPE=any \
      --release
```

## Extending the System

To add new environments or backend types:

1. **Add new environment**: Update `_deployedUrls` in `ApiConfig`
2. **Add new backend type**: Update `_getHost()`, `_getPort()`, and `_getProtocol()` methods
3. **Add new device type**: Update `_getLocalHost()` method
4. **Update validation**: Add new values to `validateConfiguration()` method
5. **Update scripts**: Add new quick commands to launch scripts

## Best Practices

1. **Use VS Code configurations** for quick development
2. **Use launch scripts** for automation and CI/CD
3. **Always verify configuration** by checking console output
4. **Test with different device types** to ensure compatibility
5. **Use staging environment** before production deployments
6. **Keep Docker configurations** consistent across team members
7. **Document custom configurations** for team reference 