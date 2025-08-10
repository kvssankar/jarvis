# Auto-Processing Safety Features

This document explains the intelligent safety features that protect users from excessive resource usage during background AI processing.

## Model-Specific Safety Features

### Gemma Models - Battery Protection
- **When:** Only active during Gemma model processing
- **Monitoring:** Checks battery level every 2 minutes
- **Threshold:** Stops processing when battery ≤ 20%
- **Reason:** Gemma runs locally and can drain battery quickly
- **Notification:** Shows specific "Gemma Processing Stopped" message

### Gemini Models - Network Protection  
- **When:** Only active during Gemini model processing
- **Monitoring:** Detects network connectivity changes
- **Trigger:** Stops when switching from WiFi to mobile data
- **Reason:** Gemini uses cloud API and can consume significant mobile data
- **Notification:** Shows specific "Gemini Processing Stopped" message

## How It Works

### Battery Monitoring (Gemma only)
```dart
// Only starts monitoring when Gemma processing begins
Timer.periodic(Duration(minutes: 2), (timer) async {
  final batteryLevel = await battery.batteryLevel;
  if (batteryLevel <= 20) {
    // Stop processing and show notification
  }
});
```

### Network Monitoring (Gemini only)
```dart
// Records initial connectivity when processing starts
connectivity.onConnectivityChanged.listen((newConnection) {
  if (hadWifi && nowHasMobile && !hasWifi) {
    // Stop processing and show notification
  }
});
```

## How the App Integration Works

When a safety condition is detected, here's what happens:

1. **Background Service Detects Issue**: Battery ≤20% (Gemma) or WiFi→Mobile (Gemini)
2. **Processing Stops**: Background processing is immediately halted
3. **Notification Shown**: User sees prominent safety notification
4. **App UI Updated**: Foreground app receives safety stop event and updates UI
5. **Animation Stops**: Processing animation in app stops immediately
6. **User Informed**: Appropriate snackbar message explains what happened

### Key Benefits

- **No Stuck UI**: App never shows "processing" when it's actually stopped
- **Clear Communication**: User knows exactly why processing stopped
- **Model-Specific**: Different safety rules for different AI models
- **Instant Response**: UI updates immediately when safety stop occurs

## Technical Details

- **Zero Impact When Idle:** Monitoring only active during processing
- **Auto Cleanup:** All monitoring stops when processing completes
- **Graceful Handling:** Processing stops cleanly with proper notifications
- **App Integration:** Apps can listen for safety stop events to update UI

## Usage Example

```dart
// Listen for safety stops in your app
backgroundService.listenForSafetyStops((event) {
  final reason = event['reason']; // 'battery_low' or 'network_changed'
  final modelType = event['modelType']; // 'gemma' or 'gemini'
  
  // Update UI accordingly
  if (reason == 'battery_low') {
    showMessage('Gemma processing paused due to low battery');
  } else if (reason == 'network_changed') {
    showMessage('Gemini processing paused - switched to mobile data');
  }
});
```

## Implementation Details

### New Channel Constants

```dart
static const String CHANNEL_SAFETY_STOP = "safety_stop";
static const String CHANNEL_BATTERY_LOW = "battery_low";
static const String CHANNEL_NETWORK_CHANGED = "network_changed";
```

### Safety Monitoring

The service automatically:
- Monitors battery state changes and levels
- Tracks connectivity changes during processing
- Shows prominent safety notifications
- Cleans up resources when stopping
- Sends detailed stop reasons to the app

### Safety Notifications

Safety notifications use:
- **Channel**: `safety_channel` (separate from processing notifications)
- **Priority**: High with sound and vibration
- **Color**: Red (`#FF6B6B`) to indicate importance
- **ID**: 999 (different from processing notification ID 888)

## Usage Example

### Listening for Safety Stops

```dart
final backgroundService = BackgroundProcessingService();

// Set up listener for safety stops
await backgroundService.listenForSafetyStops((safetyData) {
  final reason = safetyData['reason']; // 'battery_low' or 'network_changed'
  final message = safetyData['message'];
  
  if (reason == 'battery_low') {
    final batteryLevel = safetyData['batteryLevel'];
    print('Processing stopped: Battery at $batteryLevel%');
  } else if (reason == 'network_changed') {
    final oldConnection = safetyData['oldConnection'];
    final newConnection = safetyData['newConnection'];
    print('Processing stopped: Network changed from $oldConnection to $newConnection');
  }
  
  // Handle the safety stop in your app UI
  showUserFeedback(message);
});
```

### Checking Current Conditions

```dart
// Check battery level before starting processing
final batteryLevel = await backgroundService.getCurrentBatteryLevel();
if (batteryLevel != null && batteryLevel <= 20) {
  showWarning('Battery is low ($batteryLevel%). Consider charging before processing.');
}

// Check connectivity before starting processing
final connectivity = await backgroundService.getCurrentConnectivity();
final hasWifi = connectivity?.contains(ConnectivityResult.wifi) ?? false;
if (!hasWifi) {
  showWarning('Not connected to WiFi. Processing may use mobile data.');
}
```

## Safety Stop Data Structure

When a safety stop occurs, the app receives data with this structure:

### Battery Low
```dart
{
  'reason': 'battery_low',
  'batteryLevel': 15, // Current battery percentage
  'message': 'Processing stopped due to low battery (15%)'
}
```

### Network Changed
```dart
{
  'reason': 'network_changed',
  'oldConnection': ['wifi'],
  'newConnection': ['mobile'],
  'message': 'Processing stopped - switched from WiFi to mobile data'
}
```

## Dependencies

The safety features require these additional packages:

```yaml
dependencies:
  battery_plus: ^6.0.2
  connectivity_plus: ^6.0.5
```

## Configuration

### Customization Options

You can modify these constants in the code:

- **Battery threshold**: Currently set to 20% (line with `batteryLevel <= 20`)
- **Battery check interval**: Currently 2 minutes (`Duration(minutes: 2)`)
- **Notification color**: Currently red (`Color(0xFFFF6B6B)`)

### Disabling Safety Features

If you need to disable safety monitoring for testing or other reasons, you can:

1. Comment out the `_initializeSafetyMonitoring()` call in `onStart()`
2. Set `_processingActive = false` to disable checks

## Best Practices

1. **Always listen for safety stops** in your app to provide user feedback
2. **Check conditions before starting** long processing tasks
3. **Inform users** about safety features in your app's help/settings
4. **Test the safety features** by simulating low battery and network changes
5. **Consider allowing manual override** for advanced users who understand the risks

## Testing

To test the safety features:

1. **Battery Test**: Use Android's developer options to simulate battery levels
2. **Network Test**: Switch between WiFi and mobile data during processing
3. **Notification Test**: Verify that safety notifications appear correctly
4. **Recovery Test**: Ensure processing can resume after fixing the condition

The safety features are designed to be unobtrusive but effective, protecting users from accidental resource usage while maintaining a good user experience.
