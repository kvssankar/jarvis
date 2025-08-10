// AutoCategorization Service
// This service handles the automatic categorization of screenshots which are already processed by AI.
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/ai_service_manager.dart';
import 'package:shots_studio/services/ai_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/utils/ai_provider_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AICategorizer {
  final AIServiceManager _aiServiceManager = AIServiceManager();
  bool _isRunning = false;
  int _processedCount = 0;
  int _totalCount = 0;

  bool get isRunning => _isRunning;
  int get processedCount => _processedCount;
  int get totalCount => _totalCount;

  Future<AICategorizeResult> startScanning({
    required Collection collection,
    required List<Screenshot> allScreenshots,
    required List<String> currentScreenshotIds,
    required BuildContext context,
    required Function(Collection) onUpdateCollection,
    required Function(List<String> screenshotIds) onScreenshotsAdded,
    required Function(int processed, int total) onProgressUpdate,
    Function()? onCompleted,
  }) async {
    // Prevent multiple scanning attempts
    if (_isRunning) {
      return AICategorizeResult(success: false, error: 'Already scanning');
    }

    final prefs = await SharedPreferences.getInstance();
    final String? apiKey = prefs.getString('apiKey');
    if (apiKey == null || apiKey.isEmpty) {
      SnackbarService().showError(
        context,
        'API key missing. Please add it in settings.',
      );
      return AICategorizeResult(success: false, error: 'API key not set');
    }

    final String modelName = prefs.getString('modelName') ?? 'gemini-2.0-flash';
    final int maxParallel = AIProviderConfig.getMaxCategorizationLimitForModel(
      modelName,
    );

    // Keep track of the current collection state as it gets updated
    Collection currentCollection = collection;

    // Filter candidate screenshots that are not already in the collection
    final List<Screenshot> candidateScreenshots =
        allScreenshots
            .where(
              (s) =>
                  !currentScreenshotIds.contains(s.id) &&
                  !s.isDeleted &&
                  !currentCollection.scannedSet.contains(s.id) &&
                  s.aiProcessed,
            )
            .toList();

    _isRunning = true;
    _processedCount = 0;
    _totalCount = candidateScreenshots.length;

    onProgressUpdate(_processedCount, _totalCount);

    // Log analytics for scanning start
    AnalyticsService().logFeatureUsed('scanning_started');

    // If no candidate screenshots, show helpful message and return
    if (candidateScreenshots.isEmpty) {
      _isRunning = false;
      onCompleted?.call(); // Notify completion for empty case too

      // Show informative snackbar to explain why nothing happened
      SnackbarService().showInfo(
        context,
        'All screenshots have been checked already.',
      );

      return AICategorizeResult(success: true, addedScreenshotIds: []);
    }

    final config = AIConfig(
      apiKey: apiKey,
      modelName: modelName,
      maxParallel: maxParallel,
      showMessage: ({
        required String message,
        Color? backgroundColor,
        Duration? duration,
      }) {
        SnackbarService().showInfo(context, message);
      },
    );

    try {
      // Initialize the AI service manager
      _aiServiceManager.initialize(config);

      final result = await _aiServiceManager.categorizeScreenshots(
        collection: currentCollection,
        screenshots: candidateScreenshots,
        onBatchProcessed: (batch, response) {
          _processedCount += batch.length;
          onProgressUpdate(_processedCount, _totalCount);

          // Add all batch screenshot IDs to the scanned set (regardless of whether they matched)
          final List<String> batchIds = batch.map((s) => s.id).toList();
          final updatedCollection = currentCollection.addScannedScreenshots(
            batchIds,
          );
          currentCollection = updatedCollection; // Update our local reference
          onUpdateCollection(updatedCollection);

          // Process batch results immediately if successful
          if (!response.containsKey('error') && response.containsKey('data')) {
            try {
              final String responseText = response['data'];
              final RegExp jsonRegExp = RegExp(r'\{.*\}', dotAll: true);
              final match = jsonRegExp.firstMatch(responseText);

              if (match != null) {
                final parsedResponse = jsonDecode(match.group(0)!);
                if (parsedResponse['matching_screenshots'] is List) {
                  final List<String> batchMatchingIds = List<String>.from(
                    parsedResponse['matching_screenshots'],
                  );

                  if (batchMatchingIds.isNotEmpty) {
                    // Update screenshot models immediately
                    for (String screenshotId in batchMatchingIds) {
                      final screenshot = allScreenshots.firstWhere(
                        (s) => s.id == screenshotId,
                      );
                      if (!screenshot.collectionIds.contains(
                        currentCollection.id,
                      )) {
                        screenshot.collectionIds.add(currentCollection.id);
                      }
                    }

                    // Log analytics for scanned screenshots
                    AnalyticsService().logScreenshotsAutoCategorized(
                      batchMatchingIds.length,
                    );

                    // Notify about added screenshots
                    onScreenshotsAdded(batchMatchingIds);
                  }
                }
              }
            } catch (e) {
              // Silently handle parsing errors for individual batches
              print('Error parsing batch response: $e');
            }
          }
        },
      );

      _isRunning = false;
      onCompleted?.call(); // Notify completion immediately

      if (result.cancelled) {
        SnackbarService().showInfo(context, 'Scan cancelled.');
        AnalyticsService().logFeatureUsed('scanning_cancelled');
        return AICategorizeResult(
          success: false,
          cancelled: true,
          error: 'Cancelled by user',
        );
      }

      if (result.success) {
        final List<String> totalMatchingScreenshotIds = result.data ?? [];

        // Log final analytics for total scanned screenshots
        if (totalMatchingScreenshotIds.isNotEmpty) {
          AnalyticsService().logScreenshotsAutoCategorized(
            totalMatchingScreenshotIds.length,
          );
          AnalyticsService().logFeatureUsed('scanning_completed');
        }

        // Show final summary
        if (totalMatchingScreenshotIds.isNotEmpty) {
          SnackbarService().showInfo(
            context,
            'Scan complete. Added ${totalMatchingScreenshotIds.length} screenshots.',
          );
        } else {
          SnackbarService().showInfo(
            context,
            'Scan complete. No matches found.',
          );
        }

        return AICategorizeResult(
          success: true,
          addedScreenshotIds: totalMatchingScreenshotIds,
        );
      } else {
        SnackbarService().showError(context, result.error ?? 'Scan failed');
        AnalyticsService().logFeatureUsed('scanning_failed');
        return AICategorizeResult(
          success: false,
          error: result.error ?? 'Scan failed',
        );
      }
    } catch (e) {
      _isRunning = false;
      onCompleted?.call(); // Notify completion on error too
      AnalyticsService().logFeatureUsed('scanning_error');
      SnackbarService().showError(context, 'Scan error: ${e.toString()}');
      return AICategorizeResult(
        success: false,
        error: 'Scan error: ${e.toString()}',
      );
    } finally {
      _isRunning = false;
      onCompleted?.call();
      _processedCount = 0;
      _totalCount = 0;
    }
  }

  void stopScanning() {
    _aiServiceManager.cancelAllOperations();
    _isRunning = false;
    _processedCount = 0;
    _totalCount = 0;
  }
}

class AICategorizeResult {
  final bool success;
  final bool cancelled;
  final String? error;
  final List<String>? addedScreenshotIds;

  AICategorizeResult({
    required this.success,
    this.cancelled = false,
    this.error,
    this.addedScreenshotIds,
  });
}
