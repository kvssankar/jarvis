import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/notification_service.dart';

class ReminderUtils {
  static Future<DateTime?> selectReminderDateTime(
    BuildContext context,
    DateTime? currentReminderTime,
  ) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentReminderTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          currentReminderTime ?? DateTime.now(),
        ),
      );
      if (pickedTime != null) {
        return DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }
    return null;
  }

  static void setReminder(
    BuildContext context,
    Screenshot screenshot,
    DateTime? selectedReminderTime,
  ) {
    if (selectedReminderTime != null &&
        selectedReminderTime.isAfter(DateTime.now())) {
      NotificationService().scheduleNotification(
        id: screenshot.id.hashCode,
        title: 'Screenshot Reminder',
        body: 'Reminder for screenshot: ${screenshot.title ?? 'Untitled'}',
        scheduledTime: selectedReminderTime,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reminder set for ${DateFormat('MMM d, yyyy, hh:mm a').format(selectedReminderTime)}',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a future time for the reminder.'),
        ),
      );
    }
  }
}
