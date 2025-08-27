// Background Service for AI Processing - Simplified Version
import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/ai_service.dart';
import 'package:shots_studio/services/screenshot_analysis_service.dart';
import 'package:shots_studio/utils/ai_provider_config.dart';
import 'package:shots_studio/services/server_message_service.dart';
import 'package:shots_studio/services/notification_service.dart';
import 'package:shots_studio/services/message_service.dart';
import 'package:shots_studio/services/transaction_analysis_service.dart';

@pragma('vm:entry-point')
class BackgroundProcessingService {
  static bool _serviceRunning = false;
  static bool _processingActive = false;
  static StreamSubscription<BatteryState>? _batterySubscription;
  static StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription;
  static List<ConnectivityResult>? _initialConnectivity;

  // Notification constants
  static const String notificationChannelId = 'ai_processing_channel';
  static const int notificationId = 888;

  static const String CHANNEL_INIT = "initialize";
  static const String CHANNEL_PROCESS = "process_screenshots";
  static const String CHANNEL_BATCH_UPDATE = "batch_processed";
  static const String CHANNEL_COMPLETED = "processing_completed";
  static const String CHANNEL_ERROR = "processing_error";
  static const String CHANNEL_STOP = "stop_processing";
  static const String CHANNEL_SAFETY_STOP = "safety_stop";
  static const String CHANNEL_BATTERY_LOW = "battery_low";
  static const String CHANNEL_NETWORK_CHANGED = "network_changed";

  static final BackgroundProcessingService _instance =
      BackgroundProcessingService._internal();

  factory BackgroundProcessingService() {
    return _instance;
  }

  @pragma('vm:entry-point')
  BackgroundProcessingService._internal();

  // Initialize background service
  Future<bool> initializeService() async {
    try {
      final service = FlutterBackgroundService();

      // Always stop existing service first to ensure clean state
      if (await service.isRunning()) {
        service.invoke('stopService');
        await Future.delayed(const Duration(seconds: 2));
      }

      // Configure the service
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: notificationChannelId,
          initialNotificationTitle: 'AI Processing Service',
          initialNotificationContent: 'Starting...',
          foregroundServiceNotificationId: notificationId,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );

      // Start the service explicitly
      await service.startService();

      // Wait longer for service to initialize
      await Future.delayed(const Duration(seconds: 5));

      // Check if service started successfully
      final isRunning = await service.isRunning();

      // Try to send a test message to trigger onStart if it hasn't been called
      if (isRunning) {
        service.invoke('test', {'message': 'wake_up'});
        await Future.delayed(const Duration(seconds: 2));
      }

      return isRunning;
    } catch (e) {
      return false;
    }
  }

  // iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  // Main background service handler - simplified
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    try {
      // Initialize plugins
      DartPluginRegistrant.ensureInitialized();

      _serviceRunning = true;

      // Initialize flutter_local_notifications for custom notifications
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      // Configure Android service
      if (service is AndroidServiceInstance) {
        service.setAsForegroundService();

        service.on('setAsForeground').listen((event) {
          service.setAsForegroundService();
        });

        service.on('setAsBackground').listen((event) {
          service.setAsBackgroundService();
        });
      }

      // Initialize safety monitoring (will be properly configured when processing starts)
      // _initializeSafetyMonitoring(service, flutterLocalNotificationsPlugin);

      // Helper method to update custom notification with progress
      void updateCustomNotification({
        required String title,
        required String content,
        bool showProgress = false,
        int? progress,
        int? maxProgress,
        bool ongoing = false,
      }) {
        if (service is AndroidServiceInstance) {
          // Use flutter_local_notifications for custom notification
          flutterLocalNotificationsPlugin.show(
            notificationId,
            title,
            content,
            NotificationDetails(
              android: AndroidNotificationDetails(
                notificationChannelId,
                'AI Processing Service',
                channelDescription:
                    'Channel for AI screenshot processing notifications',
                icon: '@mipmap/ic_launcher_monochrome',
                ongoing: ongoing,
                showProgress: showProgress,
                maxProgress: maxProgress ?? 100,
                progress: progress ?? 0,
                importance: Importance.low,
                priority: Priority.low,
                playSound: false,
                enableVibration: false,
                autoCancel: false,
                category: AndroidNotificationCategory.progress,
              ),
            ),
          );
        }
      }

      updateCustomNotification(
        title: 'Shots Studio AI Service',
        content: 'Service is ready',
        ongoing: false,
      );

      // Handle test/wake-up messages
      service.on('test').listen((event) {
        service.invoke('test_response', {
          'status': 'awake',
          'message': 'Service is running',
        });
      });

      // Handle test notification request
      service.on('test_notification').listen((event) {
        updateCustomNotification(
          title: 'Test Notification',
          content: 'This is a test notification with custom icon',
          showProgress: true,
          progress: 50,
          maxProgress: 100,
          ongoing: false,
        );
      });

      // Handle server message check request
      service.on('check_server_messages').listen((event) async {
        await _checkServerMessages(service);
      });

      // Start periodic server message checking (every 30 minutes)
      Timer.periodic(const Duration(minutes: 30), (timer) async {
        if (!_serviceRunning) {
          timer.cancel();
          return;
        }
        await _checkServerMessages(service);
      });

      // Handle stop service request
      service.on('stopService').listen((event) async {
        _serviceRunning = false;
        _processingActive = false;
        await _cleanupSafetyMonitoring();
        service.stopSelf();
      });

      // Handle message processing requests
      service.on('process_messages').listen((event) async {
        if (event == null) {
          return;
        }

        try {
          // Update notification to show processing started
          final data = Map<String, dynamic>.from(event);
          final messagesJson = data['messages'] as String;
          final List<dynamic> messageListDynamic = jsonDecode(messagesJson);
          final totalCount = messageListDynamic.length;

          updateCustomNotification(
            title: 'Processing Messages',
            content: 'Started processing $totalCount messages',
            showProgress: true,
            progress: 0,
            maxProgress: totalCount,
            ongoing: true,
          );

          await _processMessages(service, event, updateCustomNotification);
        } catch (e) {
          updateCustomNotification(
            title: 'Processing Error',
            content: 'Error: ${e.toString()}',
            ongoing: false,
          );
          service.invoke(CHANNEL_ERROR, {'error': e.toString()});
        }
      });

      // Handle stop processing requests
      service.on(CHANNEL_STOP).listen((event) async {
        _serviceRunning = false;
        _processingActive = false;
        await _cleanupSafetyMonitoring();
        // Stop the service completely when processing is stopped
        service.stopSelf();
      });

      // Signal ready
      service.invoke(CHANNEL_INIT, {
        'ready': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      service.invoke(CHANNEL_INIT, {'ready': false, 'error': e.toString()});
    }
  }

  // Initialize safety monitoring for battery and network changes
  static void _initializeSafetyMonitoring(
    ServiceInstance service,
    FlutterLocalNotificationsPlugin notificationPlugin,
    String modelName,
  ) async {
    try {
      final battery = Battery();
      final connectivity = Connectivity();

      // Check if we should enable battery monitoring (only for Gemma models)
      final isGemmaModel = modelName.toLowerCase().contains('gemma');

      // Check if we should enable network monitoring (only for Gemini models)
      final isGeminiModel = modelName.toLowerCase().contains('gemini');

      if (isGeminiModel) {
        // Store initial connectivity state for Gemini models
        _initialConnectivity = await connectivity.checkConnectivity();

        // Monitor connectivity changes for Gemini models only
        _connectivitySubscription = connectivity.onConnectivityChanged.listen((
          connectivityResults,
        ) async {
          if (_processingActive && _initialConnectivity != null) {
            await _handleConnectivityChange(
              service,
              notificationPlugin,
              connectivityResults,
            );
          }
        });
      }

      if (isGemmaModel) {
        // Monitor battery level changes for Gemma models only
        _batterySubscription = battery.onBatteryStateChanged.listen((
          batteryState,
        ) async {
          if (_processingActive && batteryState == BatteryState.unknown) {
            // Try to get battery level directly
            final batteryLevel = await battery.batteryLevel;
            if (batteryLevel <= 20) {
              await _handleLowBattery(
                service,
                notificationPlugin,
                batteryLevel,
              );
            }
          }
        });

        // Check battery level periodically during processing for Gemma models only
        Timer.periodic(const Duration(minutes: 2), (timer) async {
          if (!_serviceRunning || !_processingActive) {
            timer.cancel();
            return;
          }

          try {
            final batteryLevel = await battery.batteryLevel;
            if (batteryLevel <= 20) {
              await _handleLowBattery(
                service,
                notificationPlugin,
                batteryLevel,
              );
              timer.cancel();
            }
          } catch (e) {
            // Silently handle battery check errors
          }
        });
      }
    } catch (e) {
      // Silently handle initialization errors
    }
  }

  // Handle low battery situation
  static Future<void> _handleLowBattery(
    ServiceInstance service,
    FlutterLocalNotificationsPlugin notificationPlugin,
    int batteryLevel,
  ) async {
    try {
      _serviceRunning = false;
      _processingActive = false;

      // Show safety notification
      await _showSafetyNotification(
        notificationPlugin,
        'Gemma Processing Stopped',
        'Processing stopped due to low battery ($batteryLevel%). Connect to charger to continue using Gemma.',
        'battery_low',
      );

      // Notify the app
      service.invoke(CHANNEL_SAFETY_STOP, {
        'reason': 'battery_low',
        'batteryLevel': batteryLevel,
        'modelType': 'gemma',
        'message':
            'Gemma processing stopped due to low battery ($batteryLevel%)',
      });

      // Clean up subscriptions
      await _cleanupSafetyMonitoring();

      // Stop the service
      service.stopSelf();
    } catch (e) {
      // Handle error silently
    }
  }

  // Handle network connectivity change
  static Future<void> _handleConnectivityChange(
    ServiceInstance service,
    FlutterLocalNotificationsPlugin notificationPlugin,
    List<ConnectivityResult> newConnectivity,
  ) async {
    try {
      // Check if switched from WiFi to mobile data
      final hadWifi =
          _initialConnectivity?.contains(ConnectivityResult.wifi) ?? false;
      final hasMobile = newConnectivity.contains(ConnectivityResult.mobile);
      final hasWifi = newConnectivity.contains(ConnectivityResult.wifi);

      if (hadWifi && !hasWifi && hasMobile) {
        _serviceRunning = false;
        _processingActive = false;

        // Show safety notification
        await _showSafetyNotification(
          notificationPlugin,
          'Gemini Processing Stopped',
          'Processing stopped - network changed from WiFi to mobile data. Gemini uses more data than other models.',
          'network_changed',
        );

        // Notify the app
        service.invoke(CHANNEL_SAFETY_STOP, {
          'reason': 'network_changed',
          'oldConnection': _initialConnectivity?.map((e) => e.name).toList(),
          'newConnection': newConnectivity.map((e) => e.name).toList(),
          'modelType': 'gemini',
          'message':
              'Gemini processing stopped - switched from WiFi to mobile data',
        });

        // Clean up subscriptions
        await _cleanupSafetyMonitoring();

        // Stop the service
        service.stopSelf();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Show safety notification with custom styling
  static Future<void> _showSafetyNotification(
    FlutterLocalNotificationsPlugin notificationPlugin,
    String title,
    String content,
    String category,
  ) async {
    try {
      await notificationPlugin.show(
        999, // Use different ID for safety notifications
        title,
        content,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'safety_channel',
            'Safety Notifications',
            channelDescription:
                'Important safety notifications for auto-processing',
            icon: '@mipmap/ic_launcher_monochrome',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            autoCancel: true,
            ongoing: false,
            category: AndroidNotificationCategory.alarm,
            color: const Color(0xFFFF6B6B), // Red color for safety alerts
          ),
        ),
      );
    } catch (e) {
      // Handle notification error silently
    }
  }

  // Clean up safety monitoring subscriptions
  static Future<void> _cleanupSafetyMonitoring() async {
    try {
      await _batterySubscription?.cancel();
      await _connectivitySubscription?.cancel();
      _batterySubscription = null;
      _connectivitySubscription = null;
      _initialConnectivity = null;
    } catch (e) {
      // Handle cleanup errors silently
    }
  }

  // Process messages method
  static Future<void> _processMessages(
    ServiceInstance service,
    Map<dynamic, dynamic> event,
    Function updateNotification,
  ) async {
    try {
      // Set processing active for safety monitoring
      _processingActive = true;

      // Extract data from event
      final String messagesJson = event['messages'] as String;
      final String apiKey = event['apiKey'] as String;
      final String modelName = event['modelName'] as String;
      final int maxParallel = event['maxParallel'] as int;

      // Initialize safety monitoring based on model type
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      _initializeSafetyMonitoring(
        service,
        flutterLocalNotificationsPlugin,
        modelName,
      );

      final List<dynamic> messageListDynamic = jsonDecode(messagesJson);
      final List<SmsMessage> messages =
          messageListDynamic
              .map((json) => SmsMessage.fromJson(json as Map<String, dynamic>))
              .toList();

      int processedCount = 0;
      final totalCount = messages.length;

      // Set up transaction analysis service
      final config = AIConfig(
        apiKey: apiKey,
        modelName: modelName,
        maxParallel: maxParallel,
      );

      final analysisService = TransactionAnalysisService(config);

      // Process messages for transactions
      final result = await analysisService.analyzeMessagesForTransactions(
        messages: messages,
        onProgress: (processed, total) {
          // Check if we should continue processing
          if (!_serviceRunning || !_processingActive) {
            if (!_processingActive) {
              throw Exception("Processing stopped for safety reasons");
            } else {
              throw Exception("Processing cancelled by user");
            }
          }

          processedCount = processed;

          // Update notification
          updateNotification(
            title: 'Processing Messages',
            content: 'Processing: $processedCount/$totalCount messages',
            showProgress: true,
            progress: processedCount,
            maxProgress: totalCount,
            ongoing: true,
          );

          // Send progress update to app
          service.invoke('messages_processed', {
            'processedTransactions': jsonEncode(
              [],
            ), // Will be filled with actual transactions
            'processedCount': processedCount,
            'totalCount': totalCount,
          });
        },
      );

      // Update notification based on final result
      if (result.success && result.data != null) {
        final transactions = result.data!;

        updateNotification(
          title: 'Processing Complete',
          content:
              'Found ${transactions.length} transactions from $totalCount messages',
          ongoing: false,
        );

        // Send final transactions to app
        service.invoke('messages_processed', {
          'processedTransactions': jsonEncode(
            transactions.map((t) => t.toJson()).toList(),
          ),
          'processedCount': totalCount,
          'totalCount': totalCount,
        });
      } else {
        updateNotification(
          title: 'Processing Failed',
          content: 'Error: ${result.error ?? "Unknown error"}',
          ongoing: false,
        );
      }

      // Send final results
      service.invoke(CHANNEL_COMPLETED, {
        'success': result.success,
        'error': result.error,
        'cancelled': !_serviceRunning,
        'processedCount': processedCount,
        'totalCount': totalCount,
      });

      // Stop the service after processing is complete
      await Future.delayed(const Duration(seconds: 2));

      // Clean up processing state and safety monitoring
      _processingActive = false;
      await _cleanupSafetyMonitoring();

      service.stopSelf();
    } catch (e) {
      updateNotification(
        title: 'Processing Error',
        content: 'Error: ${e.toString()}',
        ongoing: false,
      );
      service.invoke(CHANNEL_ERROR, {'error': e.toString()});

      // Stop the service on error as well
      await Future.delayed(const Duration(seconds: 2));

      // Clean up processing state and safety monitoring
      _processingActive = false;
      await _cleanupSafetyMonitoring();

      service.stopSelf();
    }
  }

  // Process screenshots method (keeping for compatibility)
  static Future<void> _processScreenshots(
    ServiceInstance service,
    Map<dynamic, dynamic> event,
    Function updateNotification,
  ) async {
    try {
      // Set processing active for safety monitoring
      _processingActive = true;

      // Extract data from event
      final String screenshotsJson = event['screenshots'] as String;
      final String apiKey = event['apiKey'] as String;
      final String modelName = event['modelName'] as String;
      final int maxParallel = event['maxParallel'] as int;
      final String? collectionsJson = event['collections'] as String?;

      // Initialize safety monitoring based on model type
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      _initializeSafetyMonitoring(
        service,
        flutterLocalNotificationsPlugin,
        modelName,
      );

      final List<dynamic> screenshotListDynamic = jsonDecode(screenshotsJson);
      final List<Screenshot> screenshots =
          screenshotListDynamic
              .map((json) => Screenshot.fromJson(json as Map<String, dynamic>))
              .toList();

      // Convert collections
      List<Map<String, String?>> autoAddCollections = [];
      if (collectionsJson != null && collectionsJson.isNotEmpty) {
        final List<dynamic> collectionListDynamic = jsonDecode(collectionsJson);
        autoAddCollections =
            collectionListDynamic
                .map((item) => Map<String, String?>.from(item as Map))
                .toList();
      }

      int processedCount = 0;
      final totalCount = screenshots.length;

      // Apply model-specific maxParallel limits
      final effectiveMaxParallel = AIProviderConfig.getEffectiveMaxParallel(
        modelName,
        maxParallel,
      );

      // Set up AI service
      final config = AIConfig(
        apiKey: apiKey,
        modelName: modelName,
        maxParallel: effectiveMaxParallel,
      );

      final analysisService = ScreenshotAnalysisService(config);

      // Process screenshots
      final result = await analysisService.analyzeScreenshots(
        screenshots: screenshots,
        onBatchProcessed: (batch, response) {
          // Check if we should continue processing (includes safety stops)
          if (!_serviceRunning || !_processingActive) {
            if (!_processingActive) {
              throw Exception("Processing stopped for safety reasons");
            } else {
              throw Exception("Processing cancelled by user");
            }
          }

          try {
            // Check if this batch was skipped because all screenshots were already processed
            if (response.containsKey('skipped') &&
                response['skipped'] == true) {
              // Count these as processed since they were already done
              processedCount += batch.length;

              // Update notification
              updateNotification(
                title: 'Processing Screenshots',
                content: 'Processing: $processedCount/$totalCount screenshots',
                showProgress: true,
                progress: processedCount,
                maxProgress: totalCount,
                ongoing: true,
              );

              // Send batch results to app (no actual updates needed)
              service.invoke(CHANNEL_BATCH_UPDATE, {
                'updatedScreenshots': jsonEncode([]), // No new updates
                'response': jsonEncode(response),
                'processedCount': processedCount,
                'totalCount': totalCount,
              });
              return;
            }

            // Process batch results normally
            final updatedScreenshots = analysisService
                .parseAndUpdateScreenshots(batch, response);
            processedCount += updatedScreenshots.length;

            // Update foreground notification with progress
            updateNotification(
              title: 'Processing Screenshots',
              content: 'Processing: $processedCount/$totalCount screenshots',
              showProgress: true,
              progress: processedCount,
              maxProgress: totalCount,
              ongoing: true,
            );

            // Send batch results to app
            service.invoke(CHANNEL_BATCH_UPDATE, {
              'updatedScreenshots': jsonEncode(
                updatedScreenshots.map((s) => s.toJson()).toList(),
              ),
              'response': jsonEncode(response),
              'processedCount': processedCount,
              'totalCount': totalCount,
            });
          } catch (e) {
            updateNotification(
              title: 'Processing Error',
              content: 'Batch processing error: $e',
              ongoing: false,
            );
            service.invoke(CHANNEL_ERROR, {
              'error': 'Batch processing error: $e',
            });
          }
        },
        autoAddCollections: autoAddCollections,
      );

      // Update notification based on final result
      if (result.success) {
        updateNotification(
          title: 'Processing Complete',
          content:
              'Completed processing $processedCount/$totalCount screenshots',
          ongoing: false,
        );
      } else if (!_serviceRunning) {
        // no notification if cancelled since user stopped the service
      } else {
        updateNotification(
          title: 'Processing Failed',
          content: 'Error: ${result.error ?? "Unknown error"}',
          ongoing: false,
        );
      }

      // Send final results
      service.invoke(CHANNEL_COMPLETED, {
        'success': result.success,
        'error': result.error,
        'statusCode': result.statusCode,
        'cancelled': !_serviceRunning,
        'processedCount': processedCount,
        'totalCount': totalCount,
      });

      // Stop the service after processing is complete
      // Allow a brief delay for the notification to be shown
      await Future.delayed(const Duration(seconds: 2));

      // Clean up processing state and safety monitoring
      _processingActive = false;
      await _cleanupSafetyMonitoring();

      service.stopSelf();
    } catch (e) {
      updateNotification(
        title: 'Processing Error',
        content: 'Error: ${e.toString()}',
        ongoing: false,
      );
      service.invoke(CHANNEL_ERROR, {'error': e.toString()});

      // Stop the service on error as well
      // Allow a brief delay for the notification to be shown
      await Future.delayed(const Duration(seconds: 2));

      // Clean up processing state and safety monitoring
      _processingActive = false;
      await _cleanupSafetyMonitoring();

      service.stopSelf();
    }
  }

  // Start background message processing
  Future<bool> startBackgroundMessageProcessing({
    required List<SmsMessage> messages,
    required String apiKey,
    required String modelName,
    required int maxParallel,
  }) async {
    try {
      final service = FlutterBackgroundService();

      if (!await service.isRunning()) {
        final initialized = await initializeService();
        if (!initialized) {
          return false;
        }
      }

      _serviceRunning = true;

      // Prepare payload
      final messagesJson = jsonEncode(messages.map((m) => m.toJson()).toList());

      final payload = {
        'messages': messagesJson,
        'apiKey': apiKey,
        'modelName': modelName,
        'maxParallel': maxParallel,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Send processing request
      service.invoke('process_messages', payload);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Stop background processing
  Future<bool> stopBackgroundProcessing() async {
    try {
      _serviceRunning = false;
      _processingActive = false;

      // Clean up safety monitoring
      await _cleanupSafetyMonitoring();

      final service = FlutterBackgroundService();
      if (await service.isRunning()) {
        service.invoke(CHANNEL_STOP);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Shutdown service completely
  Future<bool> shutdownService() async {
    try {
      _serviceRunning = false;
      _processingActive = false;

      // Clean up safety monitoring
      await _cleanupSafetyMonitoring();

      final service = FlutterBackgroundService();
      if (await service.isRunning()) {
        service.invoke('stopService');
        await Future.delayed(const Duration(seconds: 1));
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if service is running
  Future<bool> isServiceRunning() async {
    try {
      final service = FlutterBackgroundService();
      return await service.isRunning();
    } catch (e) {
      return false;
    }
  }

  // Test custom notification with progress
  Future<bool> testCustomNotification() async {
    try {
      final service = FlutterBackgroundService();

      if (!await service.isRunning()) {
        final initialized = await initializeService();
        if (!initialized) {
          return false;
        }
      }

      // Send test notification request
      service.invoke('test_notification');
      return true;
    } catch (e) {
      return false;
    }
  }

  // Start background service with server message checking
  Future<bool> startServerMessageChecking() async {
    try {
      final service = FlutterBackgroundService();

      if (!await service.isRunning()) {
        final initialized = await initializeService();
        if (!initialized) {
          return false;
        }
      }

      // Trigger immediate server message check
      service.invoke('check_server_messages');
      return true;
    } catch (e) {
      return false;
    }
  }

  // Method to trigger server message check from the app
  Future<void> checkServerMessagesNow() async {
    try {
      final service = FlutterBackgroundService();
      if (await service.isRunning()) {
        service.invoke('check_server_messages');
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Static method to check server messages from background service
  static Future<void> _checkServerMessages(ServiceInstance service) async {
    try {
      // Check for server messages
      final message = await ServerMessageService.checkForMessages(
        forceFetch: false,
      );

      if (message != null && message.isNotification) {
        // Initialize notification service instance
        final notificationService = NotificationService();

        // Show notification using NotificationService
        await notificationService.showServerMessageImmediate(
          messageId: message.id,
          title: message.title,
          body: message.message,
          isUrgent: message.priority == MessagePriority.high,
        );

        // Mark message as shown if it's a show-once message
        if (message.showOnce) {
          await ServerMessageService.markMessageAsShown(message.id);
        }

        // Send result back to app
        service.invoke('server_message_checked', {
          'messageFound': true,
          'messageId': message.id,
          'title': message.title,
        });
      } else {
        service.invoke('server_message_checked', {'messageFound': false});
      }
    } catch (e) {
      // Log error but don't crash the service
      service.invoke('server_message_error', {'error': e.toString()});
    }
  }

  // Add listener for safety stops from the app side
  Future<void> listenForSafetyStops(
    Function(Map<String, dynamic>) onSafetyStop,
  ) async {
    try {
      final service = FlutterBackgroundService();
      service.on(CHANNEL_SAFETY_STOP).listen((event) {
        if (event != null) {
          onSafetyStop(Map<String, dynamic>.from(event));
        }
      });
    } catch (e) {
      // Handle error silently
    }
  }

  // Check current battery level (helper method for the app)
  Future<int?> getCurrentBatteryLevel() async {
    try {
      final battery = Battery();
      return await battery.batteryLevel;
    } catch (e) {
      return null;
    }
  }

  // Check current connectivity (helper method for the app)
  Future<List<ConnectivityResult>?> getCurrentConnectivity() async {
    try {
      final connectivity = Connectivity();
      return await connectivity.checkConnectivity();
    } catch (e) {
      return null;
    }
  }
}
