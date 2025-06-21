import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/server_message_service.dart';
import '../services/analytics_service.dart';
import '../services/notification_service.dart';

class ServerMessageDialog extends StatelessWidget {
  final MessageInfo messageInfo;

  const ServerMessageDialog({super.key, required this.messageInfo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          _buildTypeIcon(theme.colorScheme),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              messageInfo.title,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              messageInfo.message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Log analytics for message dismissal
            AnalyticsService().logFeatureUsed('server_message_dismissed');
            AnalyticsService().logFeatureUsed(
              'message_${messageInfo.id}_dismissed',
            );
            Navigator.of(context).pop();
          },
          child: const Text('Dismiss'),
        ),
        if (messageInfo.type == MessageType.update)
          FilledButton(
            onPressed: () async {
              // Log analytics for action taken
              AnalyticsService().logFeatureUsed('server_message_action_taken');
              AnalyticsService().logFeatureUsed(
                'message_${messageInfo.id}_action',
              );
              Navigator.of(context).pop();

              // Handle update route if provided
              if (messageInfo.updateRoute != null &&
                  messageInfo.updateRoute!.isNotEmpty) {
                await _launchUpdateRoute(messageInfo.updateRoute!);
              }
            },
            child: const Text('Learn More'),
          ),
      ],
    );
  }

  Widget _buildTypeIcon(ColorScheme colorScheme) {
    IconData iconData;
    Color iconColor;

    switch (messageInfo.type) {
      case MessageType.info:
        iconData = Icons.info_outline;
        iconColor = colorScheme.primary;
        break;
      case MessageType.warning:
        iconData = Icons.warning_outlined;
        iconColor = colorScheme.error;
        break;
      case MessageType.update:
        iconData = Icons.system_update;
        iconColor = colorScheme.secondary;
        break;
    }

    return Icon(iconData, color: iconColor);
  }

  /// Launch update route with multiple fallback strategies
  static Future<void> _launchUpdateRoute(String url) async {
    try {
      final uri = Uri.parse(url);

      // Strategy 1: platformDefault mode
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        return;
      } catch (e) {
        // Continue to next strategy
      }

      // Strategy 2: externalApplication mode
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      } catch (e) {
        // Continue to next strategy
      }

      // Strategy 3: Basic launch without mode
      try {
        await launchUrl(uri);
        return;
      } catch (e) {
        // All strategies failed
      }
    } catch (parseError) {
      // URL parsing failed
    }
  }

  /// Shows the server message dialog if a message is available
  static Future<void> showServerMessageDialogIfAvailable(
    BuildContext context,
  ) async {
    try {
      final messageInfo = await ServerMessageService.checkForMessages();

      if (messageInfo != null && context.mounted) {
        // Mark message as shown if it's a show_once message
        if (messageInfo.showOnce) {
          await ServerMessageService.markMessageAsShown(messageInfo.id);
        }

        // Log analytics for message shown
        AnalyticsService().logFeatureUsed('server_message_shown');
        AnalyticsService().logFeatureUsed('message_${messageInfo.id}_shown');

        // Show as notification or dialog based on message settings
        if (messageInfo.isNotification) {
          await _showAsNotification(messageInfo);
        } else {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => ServerMessageDialog(messageInfo: messageInfo),
          );
        }
      }
    } catch (e) {
      // Log error analytics
      AnalyticsService().logFeatureUsed('server_message_error');
    }
  }

  /// Shows the message as a notification instead of a dialog
  static Future<void> _showAsNotification(MessageInfo messageInfo) async {
    try {
      final notificationService = NotificationService();

      // Determine notification importance based on message priority
      Importance importance;
      Priority priority;

      switch (messageInfo.priority) {
        case MessagePriority.low:
          importance = Importance.low;
          priority = Priority.low;
          break;
        case MessagePriority.medium:
          importance = Importance.defaultImportance;
          priority = Priority.defaultPriority;
          break;
        case MessagePriority.high:
          importance = Importance.high;
          priority = Priority.high;
          break;
      }

      await notificationService.showServerMessage(
        id: messageInfo.id.hashCode,
        title: messageInfo.title,
        body: messageInfo.message,
        importance: importance,
        priority: priority,
      );
    } catch (e) {
      // Error showing notification - fail silently
    }
  }
}
