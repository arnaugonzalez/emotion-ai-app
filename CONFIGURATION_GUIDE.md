# EmotionAI Flutter App - Configuration Guide

## Overview

This guide explains the centralized configuration system implemented for the EmotionAI Flutter app. The system provides environment-specific settings, centralized API endpoint management, and easy deployment across different environments.

## Configuration Architecture

### 1. API Configuration (`lib/config/api_config.dart`)
- **Purpose**: Centralized management of all API endpoints and settings
- **Features**:
  - Environment-based base URL selection
  - Timeout configurations
  - HTTP headers management
  - Feature flags
  - Development utilities

### 2. Environment Configuration (`lib/config/environment_config.dart`)
- **Purpose**: Environment-specific settings and behavior
- **Features**:
  - Multiple environment support (development, staging, production)
  - Environment-specific features (logging, analytics, etc.)
  - Auto-detection of build environment

### 3. Deployment Configuration (`lib/config/deployment_config.dart`)
- **Purpose**: Build-time configuration for different deployment scenarios
- **Features**:
  - Easy environment switching
  - Build command helpers
  - Environment variable management

## Supported Environments

### Development Environments

1. **Development (Physical Device)**
   - Base URL: `http://192.168.1.180:8000`
   - For testing on physical Android devices connected to same network
   - Mock data enabled, debug logs enabled

2. **Development (Emulator)**
   - Base URL: `http://10.0.2.2:8000`
   - For Android emulator (10.0.2.2 maps to host machine's localhost)
   - Mock data enabled, debug logs enabled

3. **Development (Local)**
   - Base URL: `http://localhost:8000`
   - For web/desktop development
   - Mock data enabled, debug logs enabled

### Production Environments

4. **Staging**
   - Base URL: `https://staging-api.emotionai.app`
   - Pre-production testing environment
   - Analytics enabled, crash reporting enabled

5. **Production**
   - Base URL: `https://api.emotionai.app`
   - Live production environment
   - All monitoring features enabled

## Backend API Endpoints

### Current Supported Endpoints

✅ **Authentication**
- `/auth/login` - User login with JWT tokens
- `/auth/register` - User registration

✅ **Chat System**
- `/api/v1/chat` - Send messages to AI agents
- `/api/v1/agents` - List available agents
- `/api/v1/agents/{type}/status` - Get agent status

✅ **Health Checks**
- `/health/` - Basic health check
- `/health/detailed` - Detailed system status

### Legacy Endpoints (Recently Added)

✅ **Data Management** (Now implemented with mock data)
- `/emotional_records/` - Emotional records CRUD
- `/breathing_sessions/` - Breathing sessions CRUD
- `/breathing_patterns/` - Breathing patterns CRUD
- `/custom_emotions/` - Custom emotions CRUD

## Usage

### 1. Basic Usage in Code

```dart
import 'package:emotion_ai/config/api_config.dart';

// Get configured URLs
final loginUrl = ApiConfig.loginUrl();
final chatUrl = ApiConfig.chatUrl();

// Check environment
if (ApiConfig.isDevelopment) {
  print('Running in development mode');
}

// Get headers with authentication
final headers = ApiConfig.authHeaders(token);
```

### 2. Environment Detection

The app automatically detects the environment based on build-time configuration:

```dart
// In main.dart
EnvironmentConfig.autoDetectEnvironment();
if (EnvironmentConfig.isDevelopment) {
  EnvironmentConfig.printCurrentConfig();
  ApiConfig.printConfig();
}
```

### 3. Manual Environment Setup

```dart
import 'package:emotion_ai/config/environment_config.dart';

// Set specific environment
EnvironmentConfig.setEnvironment(Environment.development);
EnvironmentConfig.setEnvironment(Environment.production);
```

## Build Commands

### Development Builds

```bash
# Physical Android device (default)
flutter run --dart-define=ENVIRONMENT=development
flutter build apk --dart-define=ENVIRONMENT=development

# Android emulator
flutter run --dart-define=ENVIRONMENT=development_emulator
flutter build apk --dart-define=ENVIRONMENT=development_emulator

# Local development (web/desktop)
flutter run --dart-define=ENVIRONMENT=development_local
```

### Production Builds

```bash
# Staging environment
flutter build apk --dart-define=ENVIRONMENT=staging --release
flutter build appbundle --dart-define=ENVIRONMENT=staging --release

# Production environment
flutter build apk --dart-define=ENVIRONMENT=production --release
flutter build appbundle --dart-define=ENVIRONMENT=production --release
```

## Network Configuration

### For Physical Android Devices

1. **Ensure both device and development machine are on same network**
2. **Find your computer's IP address:**
   ```bash
   # Windows
   ipconfig
   
   # macOS/Linux
   ifconfig
   ```
3. **Update the development environment if needed:**
   - Current default: `192.168.1.180:8000`
   - Update in `lib/config/environment_config.dart` if your IP differs

### For Android Emulator

- Uses `10.0.2.2:8000` (automatically maps to host machine's localhost)
- No additional configuration needed

## Backend Compatibility

### ✅ Working Endpoints (New Clean Architecture)

- Authentication (login/register) with JWT tokens
- Chat system with agent selection (therapy/wellness)
- Health checks and monitoring
- Crisis detection capabilities

### ✅ Recently Implemented Endpoints

The following endpoints have been added to resolve Flutter app compatibility:

1. **Emotional Records API** (`/emotional_records/`)
   - ✅ GET, POST operations implemented with mock data
   - Used by: Calendar events, records screen, sync functions

2. **Breathing Sessions API** (`/breathing_sessions/`)
   - ✅ GET, POST operations implemented with mock data
   - Used by: Breathing exercises, calendar events, sync functions

3. **Breathing Patterns API** (`/breathing_patterns/`)
   - ✅ GET, POST operations implemented with mock data
   - Used by: Breathing exercises customization

4. **Custom Emotions API** (`/custom_emotions/`)
   - ✅ GET, POST operations implemented with mock data
   - Used by: Emotion customization features

### Implementation Status

The backend now includes these endpoints in both:
- **Clean Architecture Backend** (`main.py`) - Proper router structure
- **Simple Backend** (`simple_main.py`) - Direct implementation for testing

**Current Status**: Mock data implementation
**Next Step**: Connect to actual database/repository layer

## Troubleshooting

### Common Issues

1. **Connection Refused (Physical Device)**
   - Check if device and computer are on same network
   - Verify IP address in configuration matches your computer's IP
   - Ensure backend is running and accessible from network

2. **Connection Refused (Emulator)**
   - Verify backend is running on localhost:8000
   - Check if emulator is properly configured

3. **404 Errors for Data Endpoints** (RESOLVED)
   - ✅ All data endpoints now implemented with mock data
   - Calendar and records screens should load without errors
   - If still getting 404s, restart the backend server

### Development Tips

1. **Check Current Configuration:**
   ```dart
   ApiConfig.printConfig();
   EnvironmentConfig.printCurrentConfig();
   ```

2. **Test Backend Connectivity:**
   ```bash
   # Test health endpoint
   curl http://192.168.1.180:8000/health/
   ```

3. **Monitor Network Requests:**
   - Use Flutter Inspector
   - Check backend logs
   - Use browser dev tools for web builds

## Migration from Hardcoded URLs

### Files Updated

All hardcoded URLs have been replaced with configuration-based URLs in:

- ✅ `lib/data/api_service.dart`
- ✅ `lib/main.dart` (sync functions)
- ✅ `lib/features/calendar/events/calendar_events_provider.dart`
- ✅ `lib/shared/notifiers/breathing_session_notifier.dart`

### Benefits

- **Environment Management**: Easy switching between development/staging/production
- **Network Flexibility**: Support for physical devices, emulators, and different network setups
- **Centralized Maintenance**: All API endpoints managed in one place
- **Feature Flags**: Environment-specific features (debug logs, mock data, analytics)
- **Build Automation**: Environment-specific builds with dart-define

## Next Steps

1. **Implement Missing Backend Endpoints**: Add the missing CRUD endpoints to the FastAPI backend
2. **Add Feature Flags**: Implement more granular feature controls
3. **Environment-Specific Assets**: Add environment-specific app icons, names, etc.
4. **CI/CD Integration**: Automate builds for different environments
5. **Configuration Validation**: Add runtime validation of configuration settings

---

For questions or issues with the configuration system, please refer to the code comments in the config files or create an issue in the project repository. 