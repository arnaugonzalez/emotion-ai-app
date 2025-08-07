# Launch Scripts

Quick reference for EmotionAI launch scripts.

## Windows Scripts (.bat)

- `launch_avd.bat` - Launch for Android Virtual Device
- `launch_physical.bat` - Launch for physical Android device  
- `launch_docker.bat` - Interactive Docker backend setup

## Unix/Linux/macOS Scripts (.sh)

- `launch_avd.sh` - Launch for Android Virtual Device
- `launch_physical.sh` - Launch for physical Android device
- `launch.sh` - Universal launch script with all options

## Quick Usage

### Windows
```cmd
# For emulator
scripts\launch_avd.bat

# For physical device
scripts\launch_physical.bat

# For Docker (interactive)
scripts\launch_docker.bat
```

### Unix/Linux/macOS
```bash
# Make scripts executable (one time)
chmod +x scripts/*.sh

# For emulator192
./scripts/launch_avd.sh

# For physical device
./scripts/launch_physical.sh

# Universal script with options
./scripts/launch.sh --help
./scripts/launch.sh --avd
./scripts/launch.sh --physical
./scripts/launch.sh --docker
./scripts/launch.sh --staging
./scripts/launch.sh --production
```

## Backend URLs Generated

| Launch Type | Device | Backend URL |
|-------------|--------|-------------|
| AVD/Emulator | Emulator | `http://10.0.2.2:8000` |
| Physical Device | Physical | `http://192.168.1.180:8000` |
| Docker | Emulator | `http://10.0.2.2:8000` |
| Docker | Physical | `http://192.168.1.180:8000` |
| Staging | Any | `https://staging-api.emotionai.app` |
| Production | Any | `https://api.emotionai.app` |

For complete documentation, see `../LAUNCH_CONFIGURATION.md` 