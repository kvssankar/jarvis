import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServerMessageService {
  static const String messagesUrl =
      'https://ansahmohammad.github.io/shots-studio/messages.json';

  // Add cooldown for server requests to avoid spamming
  static DateTime? _lastRequestTime;
  static const Duration _requestCooldown = Duration(minutes: 30);

  /// Fetches server messages and filters relevant ones
  /// Returns null if no messages or error, MessageInfo if message is available
  static Future<MessageInfo?> checkForMessages({
    bool forceFetch = false,
  }) async {
    try {
      // Check cooldown unless force fetch is requested
      if (!forceFetch && _lastRequestTime != null) {
        final timeSinceLastRequest = DateTime.now().difference(
          _lastRequestTime!,
        );
        if (timeSinceLastRequest < _requestCooldown) {
          return null;
        }
      }

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Fetch messages from GitHub Pages
      final messages = await _getServerMessages();
      _lastRequestTime = DateTime.now();

      if (messages == null || messages.isEmpty) {
        return null;
      }

      // Process messages and find the most relevant one
      final relevantMessage = await _processMessages(messages, currentVersion);
      return relevantMessage;
    } catch (e) {
      _lastRequestTime = DateTime.now();
      return null;
    }
  }

  /// Fetches messages from GitHub Pages
  static Future<List<dynamic>?> _getServerMessages() async {
    try {
      final uri = Uri.parse(messagesUrl);

      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'shots_studio_app',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Expect an object with a "messages" array
        if (data is Map<String, dynamic> && data.containsKey('messages')) {
          return data['messages'] as List<dynamic>;
        } else if (data is List) {
          // Fallback: direct array format
          return data;
        }

        return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Process messages and return the most relevant one that should be shown
  static Future<MessageInfo?> _processMessages(
    List<dynamic> messages,
    String currentVersion,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    for (final messageData in messages) {
      try {
        final message = MessageInfo.fromJson(messageData);

        // Check if message should be shown
        if (!message.show) continue;

        if (!_isVersionTargeted(message.version, currentVersion)) {
          continue;
        }

        if (message.validUntil != null &&
            DateTime.now().isAfter(message.validUntil!)) {
          continue;
        }

        if (message.showOnce) {
          final hasBeenShown =
              prefs.getBool('message_shown_${message.id}') ?? false;
          if (hasBeenShown) continue;
        }

        return message;
      } catch (e) {
        continue;
      }
    }

    return null;
  }

  static bool _isVersionTargeted(String? targetVersion, String currentVersion) {
    if (targetVersion == null || targetVersion.isEmpty) {
      return true;
    }

    final target = targetVersion.toLowerCase().trim();
    final current = currentVersion.toLowerCase().trim();

    // Special case: "ALL" targets all versions
    if (target == 'all') {
      return true;
    }

    if (target == current) {
      return true;
    }

    // Wildcard matching (e.g., "1.8.*" matches "1.8.75")
    if (target.endsWith('*')) {
      final prefix = target.substring(0, target.length - 1);
      return current.startsWith(prefix);
    }

    // TODO: Version range matching could be added here in the future

    return false;
  }

  /// Marks a message as shown so it won't be displayed again (for show_once messages)
  static Future<void> markMessageAsShown(String messageId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('message_shown_$messageId', true);
  }

  /// Test method to simulate server response for development
  static Future<MessageInfo?> getTestMessage() async {
    const testMessageJson = {
      "show": true,
      "id": "msg_2025_06_21_01",
      "title": "New Tagging Feature!",
      "message":
          "You can now organize screenshots into smart collections. Try it out now.",
      "type": "info",
      "priority": "medium",
      "show_once": true,
      "valid_until": "2025-07-01T00:00:00Z",
      "is_notification": false,
      "version": "ALL",
    };

    try {
      return MessageInfo.fromJson(testMessageJson);
    } catch (e) {
      return null;
    }
  }
}

/// Contains information about a server message
class MessageInfo {
  final bool show;
  final String id;
  final String title;
  final String message;
  final MessageType type;
  final MessagePriority priority;
  final bool showOnce;
  final DateTime? validUntil;
  final bool isNotification;
  final String? version;
  final String? actionText;
  final String? actionUrl;
  final MessageActionType? actionType;
  final String? updateRoute;

  MessageInfo({
    required this.show,
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.showOnce,
    this.validUntil,
    required this.isNotification,
    this.version,
    this.actionText,
    this.actionUrl,
    this.actionType,
    this.updateRoute,
  });

  factory MessageInfo.fromJson(Map<String, dynamic> json) {
    return MessageInfo(
      show: json['show'] ?? false,
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: _parseMessageType(json['type']),
      priority: _parseMessagePriority(json['priority']),
      showOnce: json['show_once'] ?? true,
      validUntil:
          json['valid_until'] != null
              ? DateTime.tryParse(json['valid_until'])
              : null,
      isNotification: json['is_notification'] ?? false,
      version: json['version']?.toString(),
      actionText: json['action_text']?.toString(),
      actionUrl: json['action_url']?.toString(),
      actionType: _parseActionType(json['action_type']),
      updateRoute: json['update_route']?.toString(),
    );
  }

  static MessageType _parseMessageType(dynamic type) {
    switch (type?.toString().toLowerCase()) {
      case 'info':
        return MessageType.info;
      case 'warning':
        return MessageType.warning;
      case 'update':
        return MessageType.update;
      default:
        return MessageType.info;
    }
  }

  static MessagePriority _parseMessagePriority(dynamic priority) {
    switch (priority?.toString().toLowerCase()) {
      case 'low':
        return MessagePriority.low;
      case 'medium':
        return MessagePriority.medium;
      case 'high':
        return MessagePriority.high;
      default:
        return MessagePriority.medium;
    }
  }

  static MessageActionType _parseActionType(dynamic actionType) {
    switch (actionType?.toString().toLowerCase()) {
      case 'url':
        return MessageActionType.url;
      case 'custom':
        return MessageActionType.custom;
      default:
        return MessageActionType.none;
    }
  }

  @override
  String toString() {
    return 'MessageInfo(id: $id, title: $title, type: $type, priority: $priority)';
  }
}

enum MessageType { info, warning, update }

enum MessagePriority { low, medium, high }

enum MessageActionType { url, custom, none }
