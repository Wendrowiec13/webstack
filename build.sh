#!/bin/bash

# Build configuration (Debug or Release)
CONFIGURATION="${1:-Debug}"

# Project settings
PROJECT_NAME="WebStack"
SCHEME="WebStack"
BUILD_DIR="build"

echo "Building $PROJECT_NAME in $CONFIGURATION mode..."

# Build the app
xcodebuild \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$BUILD_DIR" \
    clean build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build succeeded!"
    echo ""
    echo "App location: $BUILD_DIR/Build/Products/$CONFIGURATION/$PROJECT_NAME.app"
    echo ""
    echo "To run the app:"
    echo "  open $BUILD_DIR/Build/Products/$CONFIGURATION/$PROJECT_NAME.app"
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
