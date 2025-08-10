#!/bin/bash

# Build script for different flavors of Shots Studio
# Usage: ./build_flavors.sh [flavor] [build_type]
# Flavors: fdroid (default), github, playstore
# Build types: debug (default), release, profile

FLAVOR=${1:-fdroid}
BUILD_TYPE=${2:-debug}

echo "Building Shots Studio - Flavor: $FLAVOR, Type: $BUILD_TYPE"

case $FLAVOR in
    fdroid)
        echo "Building F-Droid flavor..."
        flutter build apk --$BUILD_TYPE --flavor fdroid --dart-define=BUILD_SOURCE=fdroid
        ;;
    github)
        echo "Building GitHub flavor..."
        flutter build apk --$BUILD_TYPE --flavor github --dart-define=BUILD_SOURCE=github
        ;;
    playstore)
        echo "Building Play Store flavor..."
        flutter build apk --$BUILD_TYPE --flavor playstore --dart-define=BUILD_SOURCE=playstore
        ;;
    *)
        echo "Unknown flavor: $FLAVOR"
        echo "Available flavors: fdroid, github, playstore"
        exit 1
        ;;
esac

echo "Build completed!"
