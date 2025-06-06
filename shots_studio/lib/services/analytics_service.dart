import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  late FirebaseAnalytics _analytics;
  late FirebaseCrashlytics _crashlytics;
  bool _initialized = false;
  bool _analyticsEnabled = true; // Default to true (opt-out model)
  static const String _analyticsConsentKey = 'analytics_consent_enabled';

  // Initialize analytics
  Future<void> initialize() async {
    if (_initialized) return;

    _analytics = FirebaseAnalytics.instance;
    _crashlytics = FirebaseCrashlytics.instance;

    // Load consent preference
    await _loadAnalyticsConsent();

    // Set analytics collection based on consent
    await _analytics.setAnalyticsCollectionEnabled(_analyticsEnabled);
    await _analytics.setConsent(
      adStorageConsentGranted: _analyticsEnabled,
      analyticsStorageConsentGranted: _analyticsEnabled,
    );

    // Pass all uncaught errors from the framework to Crashlytics only if consent is given
    if (_analyticsEnabled) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Pass all uncaught asynchronous errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }

    _initialized = true;

    // Log app startup only if consent is given
    if (_analyticsEnabled) {
      await logAppStartup();
    }
  }

  // Load analytics consent from SharedPreferences
  Future<void> _loadAnalyticsConsent() async {
    final prefs = await SharedPreferences.getInstance();
    _analyticsEnabled =
        prefs.getBool(_analyticsConsentKey) ??
        true; // Default to true (opt-out)
  }

  // Save analytics consent to SharedPreferences
  Future<void> _saveAnalyticsConsent(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_analyticsConsentKey, enabled);
  }

  bool get analyticsEnabled => _analyticsEnabled;

  // Enable analytics and telemetry
  Future<void> enableAnalytics() async {
    _analyticsEnabled = true;
    await _saveAnalyticsConsent(true);

    if (_initialized) {
      await _analytics.setAnalyticsCollectionEnabled(true);
      await _analytics.setConsent(
        adStorageConsentGranted: true,
        analyticsStorageConsentGranted: true,
      );

      // Re-enable crash reporting
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      // Log that analytics was re-enabled
      await logFeatureUsed('analytics_enabled');
    }
  }

  // Disable analytics and telemetry
  Future<void> disableAnalytics() async {
    // Log that analytics is being disabled before we actually disable it
    if (_analyticsEnabled && _initialized) {
      await logFeatureUsed('analytics_disabled');
    }

    _analyticsEnabled = false;
    await _saveAnalyticsConsent(false);

    if (_initialized) {
      await _analytics.setAnalyticsCollectionEnabled(false);
      await _analytics.setConsent(
        adStorageConsentGranted: false,
        analyticsStorageConsentGranted: false,
      );

      // Disable crash reporting
      FlutterError.onError = null;
      PlatformDispatcher.instance.onError = null;
    }
  }

  // Helper method to check if analytics should be logged
  bool _shouldLog() {
    return _initialized && _analyticsEnabled;
  }

  // Screenshot Processing Analytics
  Future<void> logBatchProcessingTime(
    int processingTimeMs,
    int screenshotCount,
  ) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'batch_processing_time',
      parameters: {
        'processing_time_ms': processingTimeMs,
        'screenshot_count': screenshotCount,
        'avg_time_per_screenshot': processingTimeMs / screenshotCount,
      },
    );
  }

  Future<void> logAIProcessingSuccess(int screenshotCount) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'ai_processing_success',
      parameters: {'screenshot_count': screenshotCount},
    );
  }

  Future<void> logAIProcessingFailure(String error, int screenshotCount) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'ai_processing_failure',
      parameters: {'error': error, 'screenshot_count': screenshotCount},
    );

    // Also log to Crashlytics
    await _crashlytics.recordError(
      'AI Processing Failed',
      StackTrace.current,
      reason: error,
      fatal: false,
    );
  }

  // Collection Management
  Future<void> logCollectionCreated() async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(name: 'collection_created');
  }

  Future<void> logCollectionDeleted() async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(name: 'collection_deleted');
  }

  Future<void> logCollectionStats(
    int totalCollections,
    int avgScreenshots,
    int minScreenshots,
    int maxScreenshots,
  ) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'collection_screenshot_stats',
      parameters: {
        'total_collections': totalCollections,
        'avg_screenshots_per_collection': avgScreenshots,
        'min_screenshots_per_collection': minScreenshots,
        'max_screenshots_per_collection': maxScreenshots,
      },
    );
  }

  // User Interaction
  Future<void> logScreenView(String screenName) async {
    if (!_shouldLog()) return;

    await _analytics.logScreenView(screenName: screenName);
  }

  Future<void> logFeatureUsed(String featureName) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'feature_used',
      parameters: {'feature_name': featureName},
    );
  }

  Future<void> logUserPath(String fromScreen, String toScreen) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'user_path',
      parameters: {'from_screen': fromScreen, 'to_screen': toScreen},
    );
  }

  // Performance Metrics
  Future<void> logAppStartup() async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'app_startup',
      parameters: {'timestamp': DateTime.now().millisecondsSinceEpoch},
    );
  }

  Future<void> logImageLoadTime(int loadTimeMs, String imageSource) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'image_load_time',
      parameters: {
        'load_time_ms': loadTimeMs,
        'image_source': imageSource, // 'gallery', 'camera', 'device'
      },
    );
  }

  // Error Tracking
  Future<void> logNetworkError(String error, String context) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'network_error',
      parameters: {'error': error, 'context': context},
    );

    await _crashlytics.recordError(
      'Network Error',
      StackTrace.current,
      reason: '$context: $error',
      fatal: false,
    );
  }

  // User Engagement
  Future<void> logActiveDay() async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'active_day',
      parameters: {'date': DateTime.now().toIso8601String().split('T')[0]},
    );
  }

  Future<void> logFeatureAdopted(String featureName) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'feature_adopted',
      parameters: {'feature_name': featureName},
    );
  }

  Future<void> logReturnUser(int daysSinceLastOpen) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'return_user',
      parameters: {'days_since_last_open': daysSinceLastOpen},
    );
  }

  Future<void> logUsageTime(String timeOfDay) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'usage_time',
      parameters: {'time_of_day': timeOfDay},
    );
  }

  // Search and Discovery
  Future<void> logSearchQuery(String query, int resultsCount) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'search_query',
      parameters: {
        'query_length': query.length,
        'results_count': resultsCount,
        'has_results': resultsCount > 0,
      },
    );
  }

  Future<void> logSearchTimeToResult(int timeMs, bool successful) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'search_time_to_result',
      parameters: {'time_ms': timeMs, 'successful': successful},
    );
  }

  Future<void> logSearchSuccess(String query, int timeMs) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'search_success',
      parameters: {'query_length': query.length, 'time_to_success_ms': timeMs},
    );
  }

  // Storage and Resources
  Future<void> logStorageUsage(int totalSizeBytes, int screenshotCount) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'storage_usage',
      parameters: {
        'total_size_bytes': totalSizeBytes,
        'screenshot_count': screenshotCount,
        'avg_size_per_screenshot': totalSizeBytes / screenshotCount,
      },
    );
  }

  Future<void> logBackgroundResourceUsage(
    int processingTimeMs,
    int memoryUsageMB,
  ) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'background_resource_usage',
      parameters: {
        'processing_time_ms': processingTimeMs,
        'memory_usage_mb': memoryUsageMB,
      },
    );
  }

  // App Health
  Future<void> logBatteryImpact(String level) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'battery_impact',
      parameters: {
        'impact_level': level, // 'low', 'medium', 'high'
      },
    );
  }

  Future<void> logNetworkUsage(int bytesUsed, String operation) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'network_usage',
      parameters: {
        'bytes_used': bytesUsed,
        'operation': operation, // 'ai_processing', 'image_upload', etc.
      },
    );
  }

  Future<void> logBackgroundTaskCompleted(
    String taskName,
    bool successful,
    int durationMs,
  ) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'background_task_completed',
      parameters: {
        'task_name': taskName,
        'successful': successful,
        'duration_ms': durationMs,
      },
    );
  }

  // Statistics (Very Important)
  Future<void> logTotalScreenshotsProcessed(int count) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'total_screenshots_processed',
      parameters: {'count': count},
    );
  }

  Future<void> logTotalCollections(int count) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'total_collections',
      parameters: {'count': count},
    );
  }

  Future<void> logScreenshotsInCollection(
    int collectionId,
    int screenshotCount,
  ) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'screenshots_in_collection',
      parameters: {'collection_screenshot_count': screenshotCount},
    );
  }

  Future<void> logScreenshotsAutoCategorized(int count) async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(
      name: 'screenshots_auto_categorized',
      parameters: {'count': count},
    );
  }

  Future<void> logReminderSet() async {
    if (!_shouldLog()) return;

    await _analytics.logEvent(name: 'reminder_set');
  }

  Future<void> logInstallInfo() async {
    if (!_shouldLog()) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();

      String platform = 'unknown';
      String osVersion = 'unknown';

      if (!kIsWeb) {
        if (Platform.isAndroid) {
          platform = 'android';
        } else if (Platform.isIOS) {
          platform = 'ios';
        } else if (Platform.isLinux) {
          platform = 'linux';
        } else if (Platform.isWindows) {
          platform = 'windows';
        } else if (Platform.isMacOS) {
          platform = 'macos';
        }
      } else {
        platform = 'web';
      }

      await _analytics.logEvent(
        name: 'install_info',
        parameters: {
          'install_date': DateTime.now().toIso8601String(),
          'app_version': packageInfo.version,
          'build_number': packageInfo.buildNumber,
          'platform': platform,
          'os_version': osVersion,
        },
      );
    } catch (e) {
      print('Error logging install info: $e');
    }
  }

  // Helper method to calculate time of day
  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  // Log current usage time
  Future<void> logCurrentUsageTime() async {
    await logUsageTime(_getTimeOfDay());
  }
}
