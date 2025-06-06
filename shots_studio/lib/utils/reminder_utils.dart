import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/notification_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/widgets/screenshots/reminder_bottom_sheet.dart';

class ReminderUtils {
  static Future<Map<String, dynamic>?> showReminderBottomSheet(
    BuildContext context,
    DateTime? currentReminderTime,
    String? currentReminderText,
  ) async {
    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ReminderBottomSheet(
          initialReminderTime: currentReminderTime,
          initialReminderText: currentReminderText,
        );
      },
    );
  }

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
    DateTime? selectedReminderTime, {
    String? customMessage,
  }) {
    if (selectedReminderTime != null &&
        selectedReminderTime.isAfter(DateTime.now())) {
      final reminderMessage =
          customMessage?.isNotEmpty == true
              ? customMessage!
              : 'Reminder for screenshot: ${screenshot.title ?? 'Untitled'}';

      NotificationService().scheduleNotification(
        id: screenshot.id.hashCode,
        title: 'Screenshot Reminder',
        body: reminderMessage,
        scheduledTime: selectedReminderTime,
      );

      SnackbarService().showSuccess(
        context,
        'Reminder set for ${DateFormat('MMM d, yyyy, hh:mm a').format(selectedReminderTime)}',
      );
    } else {
      SnackbarService().showError(
        context,
        'Please select a future time for the reminder.',
      );
    }
  }

  static void clearReminder(BuildContext context, Screenshot screenshot) {
    NotificationService().cancelNotification(screenshot.id.hashCode);
    SnackbarService().showInfo(context, 'Reminder cleared');
  }

  static Future<void> showTestNotification() async {
    await NotificationService().showTestNotification();
  }

  static Future<void> showScheduledTestNotification() async {
    final scheduledTime = DateTime.now().add(const Duration(seconds: 10));

    await NotificationService().scheduleNotification(
      id: 9999,
      title: 'Scheduled Test Notification',
      body: 'This is a scheduled test notification (10 seconds)',
      scheduledTime: scheduledTime,
    );
  }
}
