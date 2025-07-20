import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/analytics_service.dart';

/// Service for handling hard deletion of screenshot files from device storage
class HardDeleteService {
  static const bool _kDebugMode = kDebugMode;

  /// Check if hard delete is available on the current platform
  static bool isHardDeleteAvailable() {
    // Hard delete is only available on mobile platforms where we have file access
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  /// Check and request necessary permissions for hard delete
  static Future<bool> checkAndRequestPermissions() async {
    if (!isHardDeleteAvailable()) {
      if (_kDebugMode) {
        print('HardDeleteService: Hard delete not available on this platform');
      }
      return false;
    }

    try {
      if (Platform.isAndroid) {
        // Check Android SDK version to determine which permissions to use
        // For Android 11+ (API 30+), we need MANAGE_EXTERNAL_STORAGE
        // For older versions, WRITE_EXTERNAL_STORAGE is sufficient

        if (_kDebugMode) {
          print('HardDeleteService: Checking Android permissions...');
        }

        // First try MANAGE_EXTERNAL_STORAGE for Android 11+
        var manageStorageStatus = await Permission.manageExternalStorage.status;
        if (_kDebugMode) {
          print(
            'HardDeleteService: Initial MANAGE_EXTERNAL_STORAGE status: $manageStorageStatus',
          );
        }

        if (!manageStorageStatus.isGranted) {
          if (_kDebugMode) {
            print(
              'HardDeleteService: Requesting MANAGE_EXTERNAL_STORAGE permission...',
            );
          }
          manageStorageStatus =
              await Permission.manageExternalStorage.request();
          if (_kDebugMode) {
            print(
              'HardDeleteService: MANAGE_EXTERNAL_STORAGE permission after request: $manageStorageStatus',
            );
          }
        }

        // If MANAGE_EXTERNAL_STORAGE is granted, we're good
        if (manageStorageStatus.isGranted) {
          if (_kDebugMode) {
            print(
              'HardDeleteService: MANAGE_EXTERNAL_STORAGE permission granted',
            );
          }
          return true;
        }

        // Fallback to traditional storage permission for older Android versions
        var storageStatus = await Permission.storage.status;
        if (_kDebugMode) {
          print('HardDeleteService: Storage permission status: $storageStatus');
        }

        if (!storageStatus.isGranted) {
          if (_kDebugMode) {
            print('HardDeleteService: Requesting storage permission...');
          }
          storageStatus = await Permission.storage.request();
          if (_kDebugMode) {
            print(
              'HardDeleteService: Storage permission after request: $storageStatus',
            );
          }
        }

        final bool hasPermission =
            manageStorageStatus.isGranted || storageStatus.isGranted;

        if (_kDebugMode) {
          print('HardDeleteService: Final permission result: $hasPermission');
          print(
            'HardDeleteService: MANAGE_EXTERNAL_STORAGE: ${manageStorageStatus.isGranted}',
          );
          print('HardDeleteService: STORAGE: ${storageStatus.isGranted}');
        }

        return hasPermission;
      }

      // For iOS, we typically don't need special permissions for app-created files
      if (Platform.isIOS) {
        if (_kDebugMode) {
          print('HardDeleteService: iOS platform - permissions not required');
        }
        return true;
      }

      return false;
    } catch (e) {
      if (_kDebugMode) {
        print('HardDeleteService: Error checking permissions: $e');
      }
      return false;
    }
  }

  /// Attempt to hard delete a screenshot file from device storage
  static Future<HardDeleteResult> hardDeleteScreenshot(
    Screenshot screenshot,
  ) async {
    if (!isHardDeleteAvailable()) {
      return HardDeleteResult(
        success: false,
        error: 'Hard delete not available on this platform',
        fileExisted: false,
      );
    }

    // Check if screenshot has a valid file path
    if (screenshot.path == null || screenshot.path!.isEmpty) {
      if (_kDebugMode) {
        print(
          'HardDeleteService: Screenshot has no file path, cannot hard delete',
        );
      }
      return HardDeleteResult(
        success: false,
        error: 'No file path available for deletion',
        fileExisted: false,
      );
    }

    try {
      final file = File(screenshot.path!);

      // Check if file exists before attempting deletion
      final bool fileExisted = await file.exists();

      if (_kDebugMode) {
        print(
          'HardDeleteService: Attempting to delete file: ${screenshot.path}',
        );
        print('HardDeleteService: File exists: $fileExisted');
      }

      if (!fileExisted) {
        return HardDeleteResult(
          success: true, // Consider this success since the file is already gone
          error: null,
          fileExisted: false,
          message: 'File was already deleted or moved',
        );
      }

      // Check permissions before attempting deletion
      final bool hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) {
        return HardDeleteResult(
          success: false,
          error: 'Insufficient permissions for file deletion',
          fileExisted: fileExisted,
        );
      }

      // Attempt to delete the file
      await file.delete();

      // Verify deletion was successful
      final bool stillExists = await file.exists();

      if (_kDebugMode) {
        print(
          'HardDeleteService: File still exists after deletion attempt: $stillExists',
        );
      }

      if (stillExists) {
        return HardDeleteResult(
          success: false,
          error: 'File deletion failed - file still exists',
          fileExisted: fileExisted,
        );
      }

      // Log successful hard delete
      AnalyticsService().logFeatureUsed('screenshot_hard_deleted');

      if (_kDebugMode) {
        print(
          'HardDeleteService: Successfully hard deleted file: ${screenshot.path}',
        );
      }

      return HardDeleteResult(
        success: true,
        error: null,
        fileExisted: fileExisted,
        message: 'File successfully deleted from device',
      );
    } catch (e) {
      if (_kDebugMode) {
        print('HardDeleteService: Error during hard delete: $e');
      }

      return HardDeleteResult(
        success: false,
        error: 'Failed to delete file: ${e.toString()}',
        fileExisted: true, // Assume it existed if we got an error
      );
    }
  }

  /// Perform hard delete on multiple screenshots
  static Future<BulkHardDeleteResult> hardDeleteScreenshots(
    List<Screenshot> screenshots,
  ) async {
    if (!isHardDeleteAvailable()) {
      return BulkHardDeleteResult(
        totalAttempted: screenshots.length,
        successCount: 0,
        failureCount: screenshots.length,
        results: [],
        overallError: 'Hard delete not available on this platform',
      );
    }

    final List<HardDeleteResult> results = [];
    int successCount = 0;
    int failureCount = 0;

    // Check permissions once for all deletions
    final bool hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) {
      return BulkHardDeleteResult(
        totalAttempted: screenshots.length,
        successCount: 0,
        failureCount: screenshots.length,
        results: [],
        overallError: 'Insufficient permissions for file deletion',
      );
    }

    if (_kDebugMode) {
      print(
        'HardDeleteService: Starting bulk hard delete of ${screenshots.length} screenshots',
      );
    }

    for (final screenshot in screenshots) {
      final result = await hardDeleteScreenshot(screenshot);
      results.add(result);

      if (result.success) {
        successCount++;
      } else {
        failureCount++;
      }
    }

    // Log bulk hard delete analytics
    AnalyticsService().logFeatureUsed('screenshots_bulk_hard_deleted');
    AnalyticsService().logFeatureUsed(
      'hard_delete_success_count_$successCount',
    );
    AnalyticsService().logFeatureUsed(
      'hard_delete_failure_count_$failureCount',
    );

    if (_kDebugMode) {
      print(
        'HardDeleteService: Bulk hard delete completed - Success: $successCount, Failed: $failureCount',
      );
    }

    return BulkHardDeleteResult(
      totalAttempted: screenshots.length,
      successCount: successCount,
      failureCount: failureCount,
      results: results,
    );
  }
}

/// Result of a single hard delete operation
class HardDeleteResult {
  final bool success;
  final String? error;
  final bool fileExisted;
  final String? message;

  HardDeleteResult({
    required this.success,
    this.error,
    required this.fileExisted,
    this.message,
  });

  @override
  String toString() {
    return 'HardDeleteResult{success: $success, error: $error, fileExisted: $fileExisted, message: $message}';
  }
}

/// Result of bulk hard delete operations
class BulkHardDeleteResult {
  final int totalAttempted;
  final int successCount;
  final int failureCount;
  final List<HardDeleteResult> results;
  final String? overallError;

  BulkHardDeleteResult({
    required this.totalAttempted,
    required this.successCount,
    required this.failureCount,
    required this.results,
    this.overallError,
  });

  double get successRate =>
      totalAttempted > 0 ? successCount / totalAttempted : 0.0;

  @override
  String toString() {
    return 'BulkHardDeleteResult{totalAttempted: $totalAttempted, successCount: $successCount, failureCount: $failureCount, successRate: ${(successRate * 100).toStringAsFixed(1)}%}';
  }
}
