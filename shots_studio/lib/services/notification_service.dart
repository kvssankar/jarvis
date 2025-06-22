import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {},
    );

    // Request notification permissions
    await requestNotificationPermissions();
    await _checkExactAlarmPermission();
  }

  Future<bool> requestNotificationPermissions() async {
    final status = await Permission.notification.request();

    // For Android 13+ (API 33+), also request POST_NOTIFICATIONS
    final bool? result =
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();

    return status == PermissionStatus.granted || result == true;
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // Check if scheduled time is in the future
    if (!scheduledTime.isAfter(DateTime.now())) {
      return;
    }

    // Ensure we have the necessary permissions
    await _checkExactAlarmPermission();

    try {
      // Cancel any existing notification with the same ID
      await flutterLocalNotificationsPlugin.cancel(id);

      // Calculate delay for simple scheduling
      final delay = scheduledTime.difference(DateTime.now());

      // Use Future.delayed for scheduling
      Future.delayed(delay, () async {
        await flutterLocalNotificationsPlugin.show(
          id,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'screenshot_reminder_channel',
              'Screenshot Reminders',
              channelDescription:
                  'Channel for screenshot reminder notifications',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: true,
              enableVibration: true,
              playSound: true,
              fullScreenIntent: true,
              autoCancel: false,
              ongoing: false,
              ticker: 'Scheduled notification triggered',
              icon: '@mipmap/ic_launcher_monochrome',
            ),
          ),
        );
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling notification: $e');
      }
    }
  }

  Future<void> showTestNotification() async {
    await flutterLocalNotificationsPlugin.show(
      999,
      'Test Notification',
      'This is a test notification to verify everything is working',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'screenshot_reminder_channel',
          'Screenshot Reminders',
          channelDescription: 'Channel for screenshot reminder notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/ic_launcher_monochrome',
        ),
      ),
    );
  }

  Future<void> showServerMessage({
    required int id,
    required String title,
    required String body,
    String channelId = 'server_messages_channel',
    String channelName = 'Server Messages',
    String channelDescription = 'Channel for server messages and announcements',
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: importance,
          priority: priority,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          autoCancel: true,
          ongoing: false,
          icon: '@mipmap/ic_launcher_monochrome',
        ),
      ),
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<bool> _checkExactAlarmPermission() async {
    try {
      final androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation == null) {
        return false;
      }

      // Check for SCHEDULE_EXACT_ALARM permission
      final hasExactAlarmPermission =
          await Permission.scheduleExactAlarm.isGranted;

      // Request SCHEDULE_EXACT_ALARM if not granted
      if (!hasExactAlarmPermission) {
        await Permission.scheduleExactAlarm.request();
      }

      // Return final permission status
      return await Permission.scheduleExactAlarm.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking exact alarm permission: $e');
      }
      return false;
    }
  }
}
