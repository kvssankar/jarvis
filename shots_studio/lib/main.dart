import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shots_studio/l10n/app_localizations.dart';
import 'dart:async';

import 'package:shots_studio/models/transaction_model.dart';
import 'package:shots_studio/screens/privacy_screen.dart';
import 'package:shots_studio/widgets/onboarding/api_key_guide_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shots_studio/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:shots_studio/services/background_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/update_checker_service.dart';
import 'package:shots_studio/widgets/update_dialog.dart';
import 'package:shots_studio/widgets/server_message_dialog.dart';
import 'package:shots_studio/utils/theme_utils.dart';
import 'package:shots_studio/utils/theme_manager.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shots_studio/utils/build_source.dart';
import 'package:shots_studio/services/message_service.dart';
import 'package:shots_studio/screens/landing_screen.dart';
import 'package:shots_studio/screens/home_screen.dart';

import 'package:shots_studio/models/processed_message_model.dart';

void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://6f96d22977b283fc325e038ac45e6e5e@o4509484018958336.ingest.us.sentry.io/4509484020072448';

      options.tracesSampleRate =
          kDebugMode ? 0 : 0.1; // 30% in debug, 10% in production
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Analytics (PostHog)
      await AnalyticsService().initialize();

      await NotificationService().init();

      // Initialize background service for message processing only on non-web platforms
      if (!kIsWeb) {
        print("Main: Initial background service setup");
        // Set up notification channel for background service
        await _setupBackgroundServiceNotificationChannel();
      }

      runApp(SentryWidget(child: const MyApp()));
    },
  );
}

// Set up notification channel for background service
Future<void> _setupBackgroundServiceNotificationChannel() async {
  const AndroidNotificationChannel messageProcessingChannel =
      AndroidNotificationChannel(
        'message_processing_channel',
        'Message Processing Service',
        description: 'Channel for message processing notifications',
        importance: Importance.low,
      );

  const AndroidNotificationChannel serverMessagesChannel =
      AndroidNotificationChannel(
        'server_messages_channel',
        'Server Messages',
        description: 'Channel for server messages and announcements',
        importance: Importance.high,
      );

  const AndroidNotificationChannel urgentServerMessagesChannel =
      AndroidNotificationChannel(
        'server_messages_urgent',
        'Urgent Server Messages',
        description: 'Channel for urgent server messages',
        importance: Importance.max,
      );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(messageProcessingChannel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(serverMessagesChannel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(urgentServerMessagesChannel);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _amoledModeEnabled = false;
  String _selectedTheme = 'Adaptive Theme';
  Locale _selectedLocale = const Locale('en'); // Default to English

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
    _loadLocaleSettings();
  }

  Future<void> _loadThemeSettings() async {
    final amoledMode = await ThemeManager.getAmoledMode();
    final selectedTheme = await ThemeManager.getSelectedTheme();
    setState(() {
      _amoledModeEnabled = amoledMode;
      _selectedTheme = selectedTheme;
    });
  }

  Future<void> _loadLocaleSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('selected_language') ?? 'en';
    setState(() {
      _selectedLocale = Locale(languageCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final (lightScheme, darkScheme) = ThemeManager.createColorSchemes(
          lightDynamic: lightDynamic,
          darkDynamic: darkDynamic,
          selectedTheme: _selectedTheme,
          amoledModeEnabled: _amoledModeEnabled,
        );

        return MaterialApp(
          title: 'Transaction Analyzer',
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('hi'), // Hindi
            Locale('de'), // German
            Locale('zh'), // Chinese
            Locale('pt'), // Portuguese
            Locale('ar'), // Arabic
            Locale('es'), // Spanish
            Locale('fr'), // French
            Locale('it'), // Italian
            Locale('ja'), // Japanese
            Locale('ru'), // Russian
          ],
          locale: _selectedLocale,
          theme: ThemeUtils.createLightTheme(lightScheme),
          darkTheme: ThemeUtils.createDarkTheme(darkScheme),
          themeMode: ThemeMode.system,
          home: MainApp(
            onAmoledModeChanged: (enabled) async {
              await ThemeManager.setAmoledMode(enabled);
              setState(() {
                _amoledModeEnabled = enabled;
              });
            },
            onThemeChanged: (themeName) async {
              await ThemeManager.setSelectedTheme(themeName);
              setState(() {
                _selectedTheme = themeName;
              });
            },
            onLocaleChanged: (locale) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('selected_language', locale.languageCode);
              setState(() {
                _selectedLocale = locale;
              });
            },
          ),
        );
      },
    );
  }
}

class MainApp extends StatefulWidget {
  final Function(bool)? onAmoledModeChanged;
  final Function(String)? onThemeChanged;
  final Function(Locale)? onLocaleChanged;

  const MainApp({
    super.key,
    this.onAmoledModeChanged,
    this.onThemeChanged,
    this.onLocaleChanged,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  final List<Transaction> _transactions = [];
  final MessageService _messageService = MessageService();
  bool _isLoading = false;
  bool _isProcessingMessages = false;
  bool _isInitializingProcessing = false;
  int _processedCount = 0;
  int _totalToProcess = 0;

  String? _apiKey;
  String _selectedModelName = 'gemini-2.0-flash';
  int _maxParallelAI = 4;
  bool _devMode = false;
  bool _autoProcessEnabled = true;
  bool _analyticsEnabled = !kDebugMode;
  bool _amoledModeEnabled = false;
  bool _betaTestingEnabled = false;
  String _selectedTheme = 'Adaptive Theme';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Log analytics for app startup
    AnalyticsService().logScreenView('main_app');
    AnalyticsService().logCurrentUsageTime();

    _loadDataFromPrefs();
    _loadSettings();

    // Initialize server message checking in background
    if (!kIsWeb) {
      _initializeServerMessageChecking();
      _setupBackgroundServiceListeners();
    }

    // Show privacy dialog after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bool privacyAccepted = await showPrivacyScreenIfNeeded(context);
      if (privacyAccepted && context.mounted) {
        AnalyticsService().logInstallInfo();
        AnalyticsService().logInstallSource(BuildSource.current.value);

        await showApiKeyGuideIfNeeded(context, _apiKey, _updateApiKey);

        _checkForUpdates();
        _checkForServerMessages();
        _autoProcessMessages();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Initialize server message checking with background service
  Future<void> _initializeServerMessageChecking() async {
    try {
      final backgroundService = BackgroundProcessingService();
      await backgroundService.startServerMessageChecking();

      final service = FlutterBackgroundService();

      service.on('server_message_checked').listen((event) {
        if (event != null && mounted) {
          final data = Map<String, dynamic>.from(event);
          final messageFound = data['messageFound'] as bool? ?? false;

          if (messageFound) {
            print('Server message notification sent: ${data['title']}');
          }
        }
      });

      service.on('server_message_error').listen((event) {
        if (event != null) {
          final data = Map<String, dynamic>.from(event);
          print('Server message check error: ${data['error']}');
        }
      });
    } catch (e) {
      print('Failed to initialize server message checking: $e');
    }
  }

  /// Setup listeners for background service events
  void _setupBackgroundServiceListeners() {
    print("Setting up background service listeners for message processing...");

    final service = FlutterBackgroundService();

    // Listen for message processing updates
    service.on('messages_processed').listen((event) {
      try {
        if (event != null && mounted) {
          final data = Map<String, dynamic>.from(event);
          final processedTransactionsJson =
              data['processedTransactions'] as String?;
          final processedCount = data['processedCount'] as int? ?? 0;
          final totalCount = data['totalCount'] as int? ?? 0;

          if (processedTransactionsJson != null) {
            final List<dynamic> transactionsList = jsonDecode(
              processedTransactionsJson,
            );
            final List<Transaction> newTransactions =
                transactionsList
                    .map(
                      (json) =>
                          Transaction.fromJson(json as Map<String, dynamic>),
                    )
                    .toList();

            setState(() {
              _processedCount = processedCount;
              _totalToProcess = totalCount;

              // Add new transactions, avoiding duplicates
              for (var transaction in newTransactions) {
                final existingIndex = _transactions.indexWhere(
                  (t) => t.id == transaction.id,
                );
                if (existingIndex == -1) {
                  _transactions.add(transaction);
                }
              }
            });

            _saveDataToPrefs();
          }
        }
      } catch (e) {
        print("Main app: Error processing message update: $e");
      }
    });

    // Listen for processing completion
    service.on('processing_completed').listen((event) {
      try {
        if (event != null && mounted) {
          final data = Map<String, dynamic>.from(event);
          final success = data['success'] as bool? ?? false;
          final processedCount = data['processedCount'] as int? ?? 0;
          final totalCount = data['totalCount'] as int? ?? 0;
          final error = data['error'] as String?;
          final cancelled = data['cancelled'] as bool? ?? false;

          setState(() {
            _isProcessingMessages = false;
            _isInitializingProcessing = false;
            _processedCount = 0;
            _totalToProcess = 0;
          });

          if (cancelled) {
            SnackbarService().showWarning(
              context,
              'Processing cancelled. Processed $processedCount of $totalCount messages.',
            );
          } else if (success) {
            SnackbarService().showSuccess(
              context,
              'Completed processing $processedCount messages. Found ${_transactions.length} transactions.',
            );
          } else {
            SnackbarService().showError(
              context,
              error ?? 'Failed to process messages',
            );
          }

          _saveDataToPrefs();
        }
      } catch (e) {
        print("Main app: Error processing completion event: $e");
      }
    });

    // Listen for processing errors
    service.on('processing_error').listen((event) {
      try {
        if (event != null && mounted) {
          final data = Map<String, dynamic>.from(event);
          final error = data['error'] as String? ?? 'Unknown error';

          setState(() {
            _isProcessingMessages = false;
            _isInitializingProcessing = false;
            _processedCount = 0;
            _totalToProcess = 0;
          });

          SnackbarService().showError(context, 'Processing error: $error');
          _saveDataToPrefs();
        }
      } catch (e) {
        print("Main app: Error handling processing error event: $e");
      }
    });

    print("Background service listeners setup complete");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _autoProcessMessages();
      });

      Future.delayed(const Duration(seconds: 2), () {
        _checkForServerMessages();
      });
    }
  }

  Future<void> _saveDataToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedTransactions = jsonEncode(
      _transactions.map((t) => t.toJson()).toList(),
    );
    await prefs.setString('transactions', encodedTransactions);
    print("Transaction data saved to SharedPreferences");
  }

  Future<void> _loadDataFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final String? storedTransactions = prefs.getString('transactions');
    if (storedTransactions != null && storedTransactions.isNotEmpty) {
      final List<dynamic> decodedTransactions = jsonDecode(storedTransactions);
      setState(() {
        _transactions.clear();
        _transactions.addAll(
          decodedTransactions.map(
            (json) => Transaction.fromJson(json as Map<String, dynamic>),
          ),
        );
      });
    }
    print("Transaction data loaded from SharedPreferences");
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString('apiKey');
      _selectedModelName = prefs.getString('modelName') ?? 'gemini-2.0-flash';
      _maxParallelAI = prefs.getInt('maxParallel') ?? 4;
      _devMode = prefs.getBool('dev_mode') ?? false;
      _autoProcessEnabled = prefs.getBool('auto_process_enabled') ?? true;
      _analyticsEnabled =
          prefs.getBool('analytics_consent_enabled') ?? !kDebugMode;
      _amoledModeEnabled = prefs.getBool('amoled_mode_enabled') ?? false;
      _betaTestingEnabled = prefs.getBool('beta_testing_enabled') ?? false;
      _selectedTheme = prefs.getString('selected_theme') ?? 'Adaptive Theme';
    });
  }

  void _updateApiKey(String newApiKey) {
    setState(() {
      _apiKey = newApiKey;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('apiKey', newApiKey);
    });
  }

  /// Check for app updates from GitHub releases
  Future<void> _checkForUpdates() async {
    final buildSource = BuildSource.current;
    if (!buildSource.allowsUpdateCheck) {
      print(
        'MainApp: Update check disabled for ${buildSource.displayName} builds',
      );
      return;
    }

    try {
      final updateInfo = await UpdateCheckerService.checkForUpdates();

      if (updateInfo != null && mounted) {
        showDialog(
          context: context,
          builder: (context) => UpdateDialog(updateInfo: updateInfo),
        );
        AnalyticsService().logFeatureUsed('update_available');
      }
    } catch (e) {
      print('MainApp: Update check failed: $e');
      AnalyticsService().logFeatureUsed('update_check_failed');
    }
  }

  /// Check for server messages and notifications
  Future<void> _checkForServerMessages() async {
    try {
      print("MainApp: Checking for server messages...");
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        await ServerMessageDialog.showServerMessageDialogIfAvailable(context);
      }
    } catch (e) {
      print('MainApp: Server message check failed: $e');
      AnalyticsService().logFeatureUsed('server_message_check_failed');
    }
  }

  Future<void> _autoProcessMessages() async {
    if (!_autoProcessEnabled) {
      print("Main app: Auto-processing disabled");
      return;
    }

    if (_isProcessingMessages) {
      print("Main app: Already processing messages");
      return;
    }

    // Check SMS permission
    final hasPermission = await _messageService.hasSmsPermission();
    if (!hasPermission) {
      print("Main app: No SMS permission");
      return;
    }

    // Check for API key
    if (_selectedModelName != 'gemma' &&
        (_apiKey == null || _apiKey!.isEmpty)) {
      print("Main app: No API key configured");
      return;
    }

    try {
      // Get recent messages that haven't been processed
      final recentMessages = await _messageService.readRecentMessages(days: 30);

      // Filter out messages that have already been processed
      final processedMessageIds = await _getProcessedMessageIds();
      final unprocessedMessages =
          recentMessages
              .where((msg) => !processedMessageIds.contains(msg.id))
              .toList();

      if (unprocessedMessages.isEmpty) {
        print("Main app: No new messages to process");
        return;
      }

      print(
        "Main app: Found ${unprocessedMessages.length} new messages to process",
      );
      await _processMessages(unprocessedMessages);
    } catch (e) {
      print("Main app: Error in auto-process messages: $e");
    }
  }

  Future<Set<String>> _getProcessedMessageIds() async {
    final prefs = await SharedPreferences.getInstance();
    final processedMessagesJson = prefs.getString('processed_messages') ?? '[]';
    final List<dynamic> processedMessagesList = jsonDecode(
      processedMessagesJson,
    );
    final processedMessages =
        processedMessagesList
            .map(
              (json) => ProcessedMessage.fromJson(json as Map<String, dynamic>),
            )
            .toList();

    return processedMessages.map((pm) => pm.messageId).toSet();
  }

  Future<void> _saveProcessedMessages(
    List<SmsMessage> messages,
    List<Transaction> transactions,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing processed messages
    final existingProcessedMessagesJson =
        prefs.getString('processed_messages') ?? '[]';
    final List<dynamic> existingProcessedMessagesList = jsonDecode(
      existingProcessedMessagesJson,
    );
    final existingProcessedMessages =
        existingProcessedMessagesList
            .map(
              (json) => ProcessedMessage.fromJson(json as Map<String, dynamic>),
            )
            .toList();

    // Create new processed messages
    final newProcessedMessages =
        messages.map((message) {
          final hasTransaction = transactions.any(
            (t) => t.originalMessage == message.body,
          );
          final transactionId =
              hasTransaction
                  ? transactions
                      .firstWhere((t) => t.originalMessage == message.body)
                      .id
                  : null;

          return ProcessedMessage(
            messageId: message.id,
            processedAt: DateTime.now(),
            hasTransaction: hasTransaction,
            transactionId: transactionId,
          );
        }).toList();

    // Combine and save
    final allProcessedMessages = [
      ...existingProcessedMessages,
      ...newProcessedMessages,
    ];
    final allProcessedMessagesJson = jsonEncode(
      allProcessedMessages.map((pm) => pm.toJson()).toList(),
    );

    await prefs.setString('processed_messages', allProcessedMessagesJson);
    print("Saved ${newProcessedMessages.length} processed messages");
  }

  Future<void> _processMessages(List<SmsMessage> messages) async {
    print("Main app: _processMessages called with ${messages.length} messages");

    setState(() {
      _isProcessingMessages = true;
      _isInitializingProcessing = true;
    });

    try {
      // Use background service for message processing
      final backgroundService = BackgroundProcessingService();

      final success = await backgroundService.startBackgroundMessageProcessing(
        messages: messages,
        apiKey: _apiKey ?? '',
        modelName: _selectedModelName,
        maxParallel: _maxParallelAI,
      );

      if (!success) {
        throw Exception('Failed to start background message processing');
      }

      print("Main app: Background message processing started successfully");

      // Save the message IDs as processed (even if processing fails, we don't want to retry immediately)
      await _saveProcessedMessages(messages, []);
    } catch (e) {
      print("Main app: Error processing messages: $e");
      setState(() {
        _isProcessingMessages = false;
        _isInitializingProcessing = false;
      });

      if (mounted) {
        SnackbarService().showError(
          context,
          'Failed to start message processing: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkIfShouldShowLanding(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final showLanding = snapshot.data ?? true;

        if (showLanding) {
          return LandingScreen(
            onPermissionsGranted: () {
              setState(() {
                // This will trigger a rebuild and show the home screen
              });
            },
          );
        }

        return HomeScreen(
          apiKey: _apiKey,
          modelName: _selectedModelName,
          maxParallel: _maxParallelAI,
          devMode: _devMode,
          autoProcessEnabled: _autoProcessEnabled,
          analyticsEnabled: _analyticsEnabled,
          betaTestingEnabled: _betaTestingEnabled,
          amoledModeEnabled: _amoledModeEnabled,
          selectedTheme: _selectedTheme,
          onApiKeyChanged: _updateApiKey,
          onModelChanged: (String modelName) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('modelName', modelName);
            setState(() {
              _selectedModelName = modelName;
            });
          },
          onMaxParallelChanged: (int maxParallel) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('maxParallel', maxParallel);
            setState(() {
              _maxParallelAI = maxParallel;
            });
          },
          onDevModeChanged: (bool devMode) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('dev_mode', devMode);
            setState(() {
              _devMode = devMode;
            });
          },
          onAutoProcessEnabledChanged: (bool enabled) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('auto_process_enabled', enabled);
            setState(() {
              _autoProcessEnabled = enabled;
            });
          },
          onAnalyticsEnabledChanged: (bool enabled) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('analytics_consent_enabled', enabled);
            setState(() {
              _analyticsEnabled = enabled;
            });
          },
          onBetaTestingEnabledChanged: (bool enabled) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('beta_testing_enabled', enabled);
            setState(() {
              _betaTestingEnabled = enabled;
            });
          },
          onAmoledModeChanged: widget.onAmoledModeChanged,
          onThemeChanged: widget.onThemeChanged,
          onLocaleChanged: widget.onLocaleChanged,
        );
      },
    );
  }

  Future<bool> _checkIfShouldShowLanding() async {
    // Check if SMS permission is granted
    final hasPermission = await _messageService.hasSmsPermission();
    return !hasPermission;
  }
}
