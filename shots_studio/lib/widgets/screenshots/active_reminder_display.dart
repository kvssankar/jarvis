import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/utils/reminder_utils.dart';

// Removed currently since only one reminder is supported,
// but can be extended in the future if needed.

class ActiveReminderDisplay extends StatelessWidget {
  final Screenshot screenshot;
  final VoidCallback onReminderCleared;

  const ActiveReminderDisplay({
    super.key,
    required this.screenshot,
    required this.onReminderCleared,
  });

  @override
  Widget build(BuildContext context) {
    if (screenshot.reminderTime == null) {
      return const SizedBox.shrink();
    }

    // Check if the reminder is expired
    if (screenshot.reminderTime!.isBefore(DateTime.now())) {
      // Call the clearing method asynchronously to avoid build issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ReminderUtils.clearReminder(context, screenshot);
        onReminderCleared();
      });
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Reminders',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.alarm,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set for ${DateFormat('MMM d, yyyy, h:mm a').format(screenshot.reminderTime!)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if (screenshot.reminderText?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        screenshot.reminderText!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  ReminderUtils.clearReminder(context, screenshot);
                  onReminderCleared();
                },
                tooltip: 'Clear reminder',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
