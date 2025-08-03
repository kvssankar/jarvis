# Build Flavors for Shots Studio

This project supports different build flavors based on the distribution source.

## Available Flavors

### 1. F-Droid (recommended for development)
- **Source**: F-Droid store
- **Update checking**: Disabled (F-Droid handles updates)
- **Build commands**: 
  ```bash
  # F-Droid build (must specify flavor)
  flutter build apk --release --flavor fdroid --dart-define=BUILD_SOURCE=fdroid
  ```
- **Run commands**:
  ```bash
  # F-Droid run (must specify flavor)
  flutter run --flavor fdroid --dart-define=BUILD_SOURCE=fdroid
  ```

### 2. GitHub
- **Source**: GitHub releases
- **Update checking**: Enabled
- **Build command**: 
  ```bash
  flutter build apk --release --flavor github --dart-define=BUILD_SOURCE=github
  ```
- **Run command**:
  ```bash
  flutter run --flavor github --dart-define=BUILD_SOURCE=github
  ```

### 3. Play Store
- **Source**: Google Play Store
- **Update checking**: Disabled (Play Store handles updates)
- **Build command**: 
  ```bash
  flutter build apk --release --flavor playstore --dart-define=BUILD_SOURCE=playstore
  ```
- **Run command**:
  ```bash
  flutter run --flavor playstore --dart-define=BUILD_SOURCE=playstore
  ```

## Build Configuration

The build flavors are configured in `android/app/build.gradle.kts` and use:

1. **Product Flavors**: Define different build variants
2. **Build Config Fields**: Pass the build source to the app at compile time
3. **Dart Defines**: Pass build source to Flutter code via `--dart-define`

## Analytics Tracking

Each build flavor automatically logs analytics events:
- `install_fdroid` - For F-Droid builds
- `install_github` - For GitHub builds  
- `install_playstore` - For Play Store builds

## Default Behavior

When using build flavors, you **must** specify which flavor to use:

- F-Droid is recommended for development: `flutter run --flavor fdroid --dart-define=BUILD_SOURCE=fdroid`
- Update checking is disabled for F-Droid and Play Store builds
- Update checking is enabled for GitHub builds
- Analytics event varies by flavor: `install_fdroid`, `install_github`, `install_playstore`
- Build source displays in the app's About section (e.g., "Version 1.8.117 (F-Droid)")

**Note**: Running `flutter run` without specifying a flavor will fail because the build system needs to know which flavor to use.

## Convenience Build Script

A build script is provided for easier flavor management:
```bash
# Make executable (one time)
chmod +x build_flavors.sh

# Usage: ./build_flavors.sh [flavor] [build_type]
./build_flavors.sh fdroid debug     # Default: F-Droid debug
./build_flavors.sh github release   # GitHub release build
./build_flavors.sh playstore release # Play Store release build
```

## Output Files

Built APKs are generated with the following naming patterns:

### F-Droid (Default)
- Uses standard Flutter naming: `app-fdroid-debug.apk` or `app-fdroid-release.apk`
- Location: `build/app/outputs/flutter-apk/`

### GitHub & Play Store
- Uses custom naming with version info
- Pattern: `shots_studio-{flavor}-{buildType}-{version}.apk`
- Examples:
  - `shots_studio-github-release-1.8.117.apk`
  - `shots_studio-playstore-release-1.8.117.apk`

## Build Source Display

The app now displays the build source in the About section:
- F-Droid builds show: "Version 1.8.117 (F-Droid)"
- GitHub builds show: "Version 1.8.117 (GitHub)"
- Play Store builds show: "Version 1.8.117 (Play Store)"
