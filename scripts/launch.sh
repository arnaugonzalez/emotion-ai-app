#!/bin/bash

# EmotionAI Universal Launch Script
# Usage: ./launch.sh [OPTIONS]

set -e

# Default values
BACKEND_TYPE="local"
DEVICE_TYPE="auto"
ENVIRONMENT="development"
DOCKER_HOST="192.168.1.180"
BUILD_MODE="debug"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header() {
    echo -e "${PURPLE}🚀 EmotionAI Launch Script${NC}"
    echo -e "${CYAN}=========================${NC}"
}

# Function to show help
show_help() {
    print_header
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -b, --backend TYPE      Backend type: local, docker, deployed (default: local)"
    echo "  -d, --device TYPE       Device type: auto, emulator, physical, desktop (default: auto)"
    echo "  -e, --environment ENV   Environment: development, staging, production (default: development)"
    echo "  -H, --docker-host HOST  Docker host IP (default: 192.168.1.180)"
    echo "  -m, --mode MODE         Build mode: debug, profile, release (default: debug)"
    echo "  --release               Build in release mode"
    echo "  --profile               Build in profile mode"
    echo
    echo "Quick launch commands:"
    echo "  $0 --avd               Launch for Android Virtual Device"
    echo "  $0 --physical          Launch for physical Android device"
    echo "  $0 --docker            Launch with Docker backend"
    echo "  $0 --staging           Launch staging environment"
    echo "  $0 --production        Launch production environment"
    echo
    echo "Examples:"
    echo "  $0 --backend docker --device emulator --docker-host 192.168.1.100"
    echo "  $0 --environment staging --device physical"
    echo "  $0 --production --release"
    echo
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -b|--backend)
            BACKEND_TYPE="$2"
            shift 2
            ;;
        -d|--device)
            DEVICE_TYPE="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -H|--docker-host)
            DOCKER_HOST="$2"
            shift 2
            ;;
        -m|--mode)
            BUILD_MODE="$2"
            shift 2
            ;;
        --release)
            BUILD_MODE="release"
            shift
            ;;
        --profile)
            BUILD_MODE="profile"
            shift
            ;;
        --avd)
            BACKEND_TYPE="local"
            DEVICE_TYPE="emulator"
            ENVIRONMENT="development_emulator"
            shift
            ;;
        --physical)
            BACKEND_TYPE="local"
            DEVICE_TYPE="physical"
            ENVIRONMENT="development"
            shift
            ;;
        --docker)
            BACKEND_TYPE="docker"
            DEVICE_TYPE="physical"
            ENVIRONMENT="development"
            shift
            ;;
        --staging)
            BACKEND_TYPE="deployed"
            DEVICE_TYPE="any"
            ENVIRONMENT="staging"
            shift
            ;;
        --production)
            BACKEND_TYPE="deployed"
            DEVICE_TYPE="any"
            ENVIRONMENT="production"
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate inputs
if [[ ! "$BACKEND_TYPE" =~ ^(local|docker|deployed)$ ]]; then
    print_error "Invalid backend type: $BACKEND_TYPE"
    exit 1
fi

if [[ ! "$DEVICE_TYPE" =~ ^(auto|emulator|physical|desktop|any)$ ]]; then
    print_error "Invalid device type: $DEVICE_TYPE"
    exit 1
fi

if [[ ! "$ENVIRONMENT" =~ ^(development|development_emulator|development_local|staging|production)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    exit 1
fi

if [[ ! "$BUILD_MODE" =~ ^(debug|profile|release)$ ]]; then
    print_error "Invalid build mode: $BUILD_MODE"
    exit 1
fi

# Auto-adjust environment based on device type
if [[ "$DEVICE_TYPE" == "emulator" && "$ENVIRONMENT" == "development" ]]; then
    ENVIRONMENT="development_emulator"
elif [[ "$DEVICE_TYPE" == "desktop" && "$ENVIRONMENT" == "development" ]]; then
    ENVIRONMENT="development_local"
fi

# Adjust Docker host for emulator
if [[ "$BACKEND_TYPE" == "docker" && "$DEVICE_TYPE" == "emulator" ]]; then
    DOCKER_HOST="10.0.2.2"
fi

# Print configuration
print_header
echo
print_info "Configuration:"
echo "  🌍 Environment: $ENVIRONMENT"
echo "  🔧 Backend Type: $BACKEND_TYPE"
echo "  📱 Device Type: $DEVICE_TYPE"
if [[ "$BACKEND_TYPE" == "docker" ]]; then
    echo "  🐳 Docker Host: $DOCKER_HOST"
fi
echo "  🔨 Build Mode: $BUILD_MODE"
echo

# Build Flutter command
FLUTTER_CMD="flutter run"

# Add build mode flags
if [[ "$BUILD_MODE" == "release" ]]; then
    FLUTTER_CMD="$FLUTTER_CMD --release"
elif [[ "$BUILD_MODE" == "profile" ]]; then
    FLUTTER_CMD="$FLUTTER_CMD --profile"
fi

# Add dart-define parameters
FLUTTER_CMD="$FLUTTER_CMD --dart-define=ENVIRONMENT=$ENVIRONMENT"
FLUTTER_CMD="$FLUTTER_CMD --dart-define=BACKEND_TYPE=$BACKEND_TYPE"
FLUTTER_CMD="$FLUTTER_CMD --dart-define=DEVICE_TYPE=$DEVICE_TYPE"

if [[ "$BACKEND_TYPE" == "docker" ]]; then
    FLUTTER_CMD="$FLUTTER_CMD --dart-define=DOCKER_HOST=$DOCKER_HOST"
fi

# Show the command that will be executed
print_info "Executing: $FLUTTER_CMD"
echo

# Run the command
print_info "Starting Flutter application..."
eval $FLUTTER_CMD

print_success "Launch complete!" 