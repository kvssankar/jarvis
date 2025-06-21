# Server Message System Documentation

## Overview

The server message system allows sending announcements, notifications, and updates to app users from a static JSON file hosted on GitHub Pages. It's secure, simple, configurable, and supports both dialog and notification display modes.

## Features

- **GitHub Pages hosting**: Messages are fetched from a static JSON file for security and simplicity
- **Version targeting**: Messages can target specific app versions using exact match or wildcards
- **Multiple message types**: Info, Warning, Update
- **Priority levels**: Low, Medium, High
- **Display modes**: Dialog or notification
- **Show-once functionality**: Messages can be marked to show only once per user
- **Expiration dates**: Messages can have validity periods
- **Request cooldown**: Prevents excessive requests with configurable cooldown periods
- **Analytics integration**: Tracks message views and interactions

## Architecture

### Components

1. **ServerMessageService** (`/lib/services/server_message_service.dart`)
   - Handles fetching messages from GitHub Pages
   - Manages message filtering and processing with version targeting
   - Handles show-once logic and expiration

2. **ServerMessageDialog** (`/lib/widgets/server_message_dialog.dart`)
   - UI component for displaying messages as dialogs
   - Supports notification display mode
   - Integrates with analytics

3. **NotificationService** (extended)
   - Added support for server message notifications
   - Configurable notification channels

## GitHub Pages Configuration

### URL Configuration

```dart
// In ServerMessageService
static const String messagesUrl = 'https://ansahmohammad.github.io/shots-studio/messages.json';
```

### JSON File Format

The JSON file hosted on GitHub Pages should follow this structure:

```json
{
  "version": "1.0",
  "last_updated": "2025-01-21T12:00:00Z",
  "messages": [
    {
      "show": true,
      "id": "welcome_new_users_2025",
      "title": "Welcome to Shots Studio!",
      "message": "Thanks for downloading Shots Studio! Organize your screenshots like never before.",
      "type": "info",
      "priority": "medium",
      "show_once": true,
      "valid_until": "2025-12-31T23:59:59Z",
      "is_notification": false,
      "version": "ALL"
    },
    {
      "show": true,
      "id": "feature_collections_v18",
      "title": "New Collections Feature!",
      "message": "You can now organize screenshots into smart collections based on tags and dates!",
      "type": "update",
      "priority": "high",
      "show_once": true,
      "valid_until": "2025-06-01T00:00:00Z",
      "is_notification": false,
      "version": "1.8.*"
    }
  ]
}
```

### Message Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `show` | boolean | Yes | Whether to display the message |
| `id` | string | Yes | Unique identifier for the message |
| `title` | string | Yes | Message title |
| `message` | string | Yes | Message content |
| `type` | string | Yes | Message type: `info`, `warning`, `update` |
| `priority` | string | Yes | Priority level: `low`, `medium`, `high` |
| `show_once` | boolean | No | Show only once per user (default: true) |
| `valid_until` | string | No | ISO 8601 date when message expires |
| `is_notification` | boolean | No | Show as notification instead of dialog (default: false) |
| `version` | string | No | Target app version (supports wildcards) |

### Version Targeting

The `version` field supports various targeting options:

- **`"ALL"`** - Show to all app versions
- **`"1.8.75"`** - Show only to exact version 1.8.75
- **`"1.8.*"`** - Show to all 1.8.x versions (wildcard matching)
- **`null` or empty** - Same as "ALL"

Examples:
```json
{
  "version": "ALL",          // Show to all versions
  "version": "1.8.75",       // Show only to v1.8.75
  "version": "1.8.*",        // Show to v1.8.0, v1.8.75, v1.8.100, etc.
  "version": "1.*"           // Show to all v1.x versions
}
```

## Request Details

```
GET https://ansahmohammad.github.io/shots-studio/messages.json
```

**Headers:**
```
Accept: application/json
User-Agent: shots_studio_app
Content-Type: application/json
```

**No query parameters needed** - the app version targeting is handled client-side.

## Usage

### Automatic Checking

The system automatically checks for messages:
1. On app startup (after privacy dialog and API key setup)
2. When app resumes from background (with 30-minute cooldown)

### Manual Testing

For development and testing, there's a "Test Server Message" button available in Developer Mode:

1. Enable Developer Mode in Advanced Settings
2. Look for "Test Server Message" button
3. This shows a predefined test message

### Code Integration

```dart
// Check for messages manually
final messageInfo = await ServerMessageService.checkForMessages();
if (messageInfo != null) {
  // Handle message display
  await ServerMessageDialog.showServerMessageDialogIfAvailable(context);
}

// Force fetch (bypass cooldown)
final messageInfo = await ServerMessageService.checkForMessages(forceFetch: true);
```

## Configuration

### GitHub Pages URL

Update the messages URL in `ServerMessageService`:

```dart
static const String messagesUrl = 'https://ansahmohammad.github.io/shots-studio/messages.json';
```

### Request Cooldown

Modify the cooldown period:

```dart
static const Duration _requestCooldown = Duration(minutes: 30);
```

### Hosting the Messages File

1. **Create the JSON file** in your GitHub repository (e.g., `docs/messages.json`)
2. **Enable GitHub Pages** for your repository
3. **Deploy the file** - it will be available at `https://yourusername.github.io/repository-name/messages.json`
4. **Update messages** by simply committing changes to the JSON file

### Benefits of GitHub Pages Approach

- **Security**: No backend API to secure or maintain
- **Simplicity**: Just a static JSON file
- **Reliability**: GitHub Pages has excellent uptime
- **Version Control**: Messages are tracked in git
- **No Cost**: GitHub Pages is free for public repositories
- **Easy Updates**: Just commit changes to update messages

## Version Targeting Examples

### Target All Users
```json
{
  "version": "ALL",
  "title": "Welcome!",
  "message": "Thanks for using our app!"
}
```

### Target Specific Version
```json
{
  "version": "1.8.75",
  "title": "Bug Fix Available",
  "message": "Update to 1.8.76 to fix the login issue."
}
```

### Target Version Range
```json
{
  "version": "1.8.*",
  "title": "New Feature!",
  "message": "Check out the new collections feature in version 1.8!"
}
```

### Notification Channels

The system creates a notification channel for server messages:
- **Channel ID**: `server_messages_channel`
- **Channel Name**: `Server Messages`
- **Importance**: High

## Analytics Integration

The system tracks the following events:
- `server_message_shown` - When a message is displayed
- `message_{id}_shown` - When specific message is displayed
- `server_message_dismissed` - When user dismisses message
- `message_{id}_dismissed` - When specific message is dismissed
- `server_message_action_taken` - When user takes action on message
- `server_message_check_failed` - When message check fails

## Error Handling

The system gracefully handles:
- Network errors
- Server timeouts
- Invalid JSON responses
- Missing message properties
- Expired messages

Errors are logged but don't interrupt user experience.

## Testing

### Test Message

The system includes a test message for development:

```dart
await ServerMessageDialog.showTestMessageDialog(context);
```

### Mock Server Response

For testing without a server, modify `getTestMessage()` in `ServerMessageService`.

## Best Practices

1. **Message Design**
   - Keep titles short and descriptive
   - Make messages actionable and clear
   - Use appropriate priority levels

2. **Server Implementation**
   - Implement proper caching
   - Use CDN for better performance
   - Handle version-specific messages

3. **User Experience**
   - Don't overwhelm users with too many messages
   - Use notifications sparingly (high priority only)
   - Respect show_once settings

4. **Privacy**
   - Device IDs are generated locally and anonymous
   - No personal information is sent to server
   - Messages should comply with privacy policies

## Troubleshooting

### Common Issues

1. **Messages not showing**
   - Check server URL configuration
   - Verify message `show` property is `true`
   - Check if message has expired
   - Verify cooldown period hasn't blocked request

2. **Notifications not working**
   - Ensure notification permissions are granted
   - Check notification channel setup
   - Verify `is_notification` is set to `true`

3. **Server errors**
   - Check server logs for API errors
   - Verify JSON response format
   - Test with development test message

### Debug Logging

Enable debug logging to track message flow:
- Server request/response logs
- Message processing logs
- Display mode decisions
- Analytics events

## Future Enhancements

Potential improvements:
- Rich text message formatting
- Action buttons in messages
- Image/media support in messages
- Localization support
- A/B testing integration
- Advanced targeting (user segments, app version ranges)
