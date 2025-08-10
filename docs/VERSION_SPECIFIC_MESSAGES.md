# Version-Specific Server Messages

This document explains the new version-specific server messaging system implemented in Shots Studio.

## Overview

Previously, all app versions fetched messages from a single `messages.json` file. This new system organizes messages by version, allowing for more targeted and relevant messaging.

## Directory Structure

```
docs/
├── messages.json                    # Fallback messages for all versions
├── 1.8.115/
│   └── messages.json               # Messages specific to version 1.8.115
├── 1.8.103/
│   └── messages.json               # Messages specific to version 1.8.103
└── [version]/
    └── messages.json               # Messages for specific version
```

## How It Works

1. **Version-Specific URL**: The app constructs a URL based on its current version:
   - Format: `https://ansahmohammad.github.io/shots-studio/[VERSION]/messages.json`
   - Example: `https://ansahmohammad.github.io/shots-studio/1.8.115/messages.json`

2. **Fallback Mechanism**: If version-specific messages don't exist (404 error), the system falls back to the general `messages.json` file.

3. **Error Handling**: If both the version-specific and fallback requests fail, the system gracefully returns null.

## Benefits

- **Targeted Messaging**: Messages can be tailored to specific app versions
- **Better Organization**: Messages are organized by version, making maintenance easier
- **Backward Compatibility**: Older versions can still receive messages through the fallback mechanism
- **Gradual Migration**: New versions can use version-specific messages while older versions continue using the general file

## Implementation Details

### Code Changes

The main changes were made in `ServerMessageService`:

1. **URL Construction**: Changed from static URL to dynamic version-based URL
2. **Fallback Logic**: Added fallback to general messages.json if version-specific file doesn't exist
3. **Error Handling**: Enhanced error handling for both primary and fallback requests

### Message Format

The message format remains the same - only the organization by directory structure has changed.

## Migration Guide

### For New Versions

1. Create a new directory named with the version number (e.g., `1.8.116/`)
2. Add a `messages.json` file with version-specific messages
3. Deploy to GitHub Pages

### For Existing Versions

Existing versions will continue to work with the fallback mechanism using the general `messages.json` file.

## Example Usage

For version `1.8.115`, the app will:
1. Try to fetch: `https://ansahmohammad.github.io/shots-studio/1.8.115/messages.json`
2. If that fails, fallback to: `https://ansahmohammad.github.io/shots-studio/messages.json`

This ensures that messages are always available while allowing for version-specific customization.
