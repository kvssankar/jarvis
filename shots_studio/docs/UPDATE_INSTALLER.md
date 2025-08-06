# Update Installer Feature

This document explains the new update installer feature that allows users to download and install app updates directly from within the app.

## Overview

The update installer consists of three main components:

1. **UpdateInstallerService** - Handles downloading APK files and managing installation
2. **Updated UpdateDialog** - Shows download progress and manages the update process
3. **Android Platform Integration** - Native Android code for handling APK installation permissions and installation

## Features

- **Automatic Platform Detection**: Only shows install option on Android devices
- **Download Progress**: Real-time progress tracking during APK download
- **Permission Management**: Automatically requests and handles install permissions
- **Error Handling**: Graceful fallback to browser-based download if installation fails
- **File Size Display**: Shows estimated download size before starting
- **Analytics Integration**: Tracks user interactions with update dialogs

## How It Works

### 1. Update Detection
The existing `UpdateCheckerService` detects when a new version is available by checking GitHub releases.

### 2. Update Dialog Enhancement
When an update is available, the `UpdateDialog` now:
- Checks if the platform supports direct installation (Android only)
- Fetches the download size of the APK file
- Shows either "Install" (for Android) or "Download" (for other platforms) button

### 3. Installation Process
For Android devices:

1. **Permission Check**: Verifies if the app has permission to install unknown apps
2. **Permission Request**: If not granted, redirects user to Android settings to enable it
3. **APK Download**: Downloads the APK file from GitHub releases with progress tracking
4. **Installation**: Uses Android's built-in APK installer to install the update
5. **Cleanup**: Temporary files are automatically handled by the system

### 4. Error Handling
If any step fails:
- Shows an error dialog with the specific error message
- Offers a fallback option to open GitHub releases page in browser
- Logs analytics events for debugging

## Files Modified/Added

### New Files
- `lib/services/update_installer_service.dart` - Main installer service
- `android/app/src/main/res/xml/provider_paths.xml` - FileProvider configuration

### Modified Files
- `lib/widgets/update_dialog.dart` - Enhanced with installer functionality
- `android/app/src/main/kotlin/com/example/shots_studio/MainActivity.kt` - Added native Android code
- `android/app/src/main/AndroidManifest.xml` - Added permissions and FileProvider

## Permissions Required

### Android Manifest Permissions
```xml
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
```

### Runtime Permissions
- Install unknown apps permission (handled automatically by the service)

## Usage

The update installer is automatically integrated into the existing update flow. No changes are needed in calling code:

```dart
// Existing usage remains the same
final updateInfo = await UpdateCheckerService.checkForUpdates();
if (updateInfo != null && context.mounted) {
  showDialog(
    context: context,
    builder: (context) => UpdateDialog(updateInfo: updateInfo),
  );
}
```

## Platform Support

- **Android**: Full support with direct APK installation
- **iOS**: Falls back to App Store (not applicable for this app)
- **Web/Desktop**: Falls back to browser download from GitHub

## User Experience

### Android Users
1. Update dialog appears with "Install" button
2. Shows download size estimate
3. Click "Install" to start download
4. Real-time progress indicator
5. Automatic installation when download completes
6. Success message with instruction to restart

### Other Platforms
1. Update dialog appears with "Download" button
2. Click "Download" opens GitHub releases page in browser
3. User manually downloads and installs

## Analytics

The following analytics events are tracked:
- `update_dialog_install_clicked_[version]` - User clicked install button
- `update_dialog_fallback_browser_[version]` - Fallback to browser used
- `update_dialog_later_clicked_[version]` - User dismissed update
- `update_dialog_update_clicked_[version]` - User clicked download for non-Android

## Error Scenarios

Common error scenarios and their handling:

1. **Permission Denied**: Shows error dialog and guides user to settings
2. **Network Error**: Shows error with retry option via browser
3. **File Not Found**: APK not available in GitHub release
4. **Download Interrupted**: Shows error and offers browser fallback
5. **Installation Failed**: Shows error and offers browser fallback

## Security Considerations

- APK files are downloaded directly from official GitHub releases
- File integrity is verified by checking download size
- Uses Android's built-in installation process for security
- Temporary files are stored in app's cache directory
- FileProvider ensures secure file access across apps

## Future Enhancements

Potential improvements for future versions:
- Checksum verification for downloaded APKs
- Delta updates for smaller downloads
- Background download with notifications
- Automatic restart after installation
- Update scheduling options
