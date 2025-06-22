import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/analytics_service.dart';

/// Result class for image loading operations
class ImageLoadResult {
  final List<Screenshot> screenshots;
  final String? errorMessage;
  final bool success;

  const ImageLoadResult({
    required this.screenshots,
    this.errorMessage,
    required this.success,
  });

  factory ImageLoadResult.success(List<Screenshot> screenshots) {
    return ImageLoadResult(screenshots: screenshots, success: true);
  }

  factory ImageLoadResult.error(String errorMessage) {
    return ImageLoadResult(
      screenshots: [],
      errorMessage: errorMessage,
      success: false,
    );
  }
}

/// Progress callback for loading operations
typedef LoadingProgressCallback = void Function(int current, int total);

/// Service class responsible for loading images from various sources
class ImageLoaderService {
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  /// Load images from camera or gallery using image picker
  Future<ImageLoadResult> loadFromImagePicker({
    required ImageSource source,
    required List<Screenshot> existingScreenshots,
  }) async {
    try {
      final startTime = DateTime.now();

      // Log feature usage
      String sourceStr = source == ImageSource.camera ? 'camera' : 'gallery';
      AnalyticsService().logFeatureUsed('image_picker_$sourceStr');

      List<XFile>? images;

      if (source == ImageSource.camera) {
        // Take a photo with the camera
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null) {
          images = [image];
        }
      } else if (kIsWeb) {
        images = await _picker.pickMultiImage();
      } else {
        images = await _picker.pickMultiImage();
      }

      if (images == null || images.isEmpty) {
        return ImageLoadResult.success([]);
      }

      List<Screenshot> newScreenshots = [];

      for (var image in images) {
        final bytes = await image.readAsBytes();
        final String imageId = _uuid.v4();
        final String imageName = image.name;

        // Check if a screenshot with the same path already exists
        bool exists = false;
        if (!kIsWeb && image.path.isNotEmpty) {
          exists = existingScreenshots.any((s) => s.path == image.path);
        }

        if (exists) {
          print(
            'Skipping already loaded image: ${image.path.isNotEmpty ? image.path : imageName}',
          );
          continue;
        }

        newScreenshots.add(
          Screenshot(
            id: imageId,
            path: kIsWeb ? null : image.path,
            bytes: kIsWeb || !File(image.path).existsSync() ? bytes : null,
            title: imageName,
            tags: [],
            aiProcessed: false,
            addedOn: DateTime.now(),
            fileSize: bytes.length,
          ),
        );
      }

      // Log image loading analytics
      final loadTime = DateTime.now().difference(startTime).inMilliseconds;
      AnalyticsService().logImageLoadTime(loadTime, sourceStr);

      return ImageLoadResult.success(newScreenshots);
    } catch (e) {
      // Log error analytics
      AnalyticsService().logNetworkError(e.toString(), 'image_picker');
      print('Error picking images: $e');
      return ImageLoadResult.error('Error picking images: $e');
    }
  }

  /// Load screenshots from Android device directories
  Future<ImageLoadResult> loadAndroidScreenshots({
    required List<Screenshot> existingScreenshots,
    required bool isLimitEnabled,
    required int screenshotLimit,
    LoadingProgressCallback? onProgress,
    List<String>? customPaths,
  }) async {
    if (kIsWeb) {
      return ImageLoadResult.success([]);
    }

    try {
      // Android API level specific permission handling
      var status = await Permission.photos.request();

      // For Android 11 specifically, also check storage permission as a fallback
      if (!status.isGranted && Platform.isAndroid) {
        // Try legacy storage permission for Android 10/11 compatibility
        var storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted) {
          status = storageStatus;
        }
      }

      if (!status.isGranted) {
        String errorMessage =
            'Photos permission denied. Cannot load screenshots.';
        if (Platform.isAndroid) {
          errorMessage +=
              '\n\nFor Android 11 users: Please ensure both Photos and Files permissions are granted in your device settings.';
        }
        return ImageLoadResult.error(errorMessage);
      }

      // Get common Android screenshot directories
      List<String> possibleScreenshotPaths = await _getScreenshotPaths();

      // Add custom paths if provided
      if (customPaths != null && customPaths.isNotEmpty) {
        possibleScreenshotPaths.addAll(customPaths);
      }

      List<FileSystemEntity> allFiles = [];

      for (String dirPath in possibleScreenshotPaths) {
        final directory = Directory(dirPath);
        if (await directory.exists()) {
          allFiles.addAll(
            directory.listSync().whereType<File>().where(
              (file) =>
                  file.path.toLowerCase().endsWith('.png') ||
                  file.path.toLowerCase().endsWith('.jpg') ||
                  file.path.toLowerCase().endsWith('.jpeg'),
            ),
          );
        }
      }

      // Sort by last modified date (newest first)
      allFiles.sort((a, b) {
        return File(
          b.path,
        ).lastModifiedSync().compareTo(File(a.path).lastModifiedSync());
      });

      // Apply limit if enabled
      final limitedFiles =
          isLimitEnabled
              ? allFiles.take(screenshotLimit).toList()
              : allFiles.toList();

      List<Screenshot> loadedScreenshots = [];
      int progress = 0;

      // Process files in batches to avoid memory spikes
      const int batchSize = 20;
      for (int i = 0; i < limitedFiles.length; i += batchSize) {
        final batch = limitedFiles.skip(i).take(batchSize);

        for (var fileEntity in batch) {
          final file = File(fileEntity.path);

          // Skip if already exists by path
          if (existingScreenshots.any((s) => s.path == file.path)) {
            print('Skipping already loaded file via path check: ${file.path}');
            progress++;
            onProgress?.call(progress, limitedFiles.length);
            continue;
          }

          // Check if the file path contains ".trashed" and skip if it does
          if (file.path.contains('.trashed')) {
            print('Skipping trashed file: ${file.path}');
            progress++;
            onProgress?.call(progress, limitedFiles.length);
            continue;
          }

          final fileSize = await file.length();

          // Skip very large files to prevent memory issues
          if (fileSize > 50 * 1024 * 1024) {
            // Skip files larger than 50MB
            print('Skipping large file: ${file.path} ($fileSize bytes)');
            progress++;
            onProgress?.call(progress, limitedFiles.length);
            continue;
          }

          loadedScreenshots.add(
            Screenshot(
              id: _uuid.v4(),
              path: file.path,
              title: file.path.split('/').last,
              tags: [],
              aiProcessed: false,
              addedOn: await file.lastModified(),
              fileSize: fileSize,
            ),
          );

          progress++;
          onProgress?.call(progress, limitedFiles.length);
        }

        // Small delay to prevent UI blocking
        if (i % batchSize == 0) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      return ImageLoadResult.success(loadedScreenshots);
    } catch (e) {
      print('Error loading Android screenshots: $e');
      return ImageLoadResult.error('Error loading Android screenshots: $e');
    }
  }

  /// Get common Android screenshot directory paths
  Future<List<String>> _getScreenshotPaths() async {
    List<String> paths = [];

    try {
      // Get external storage directory
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        String baseDir = externalDir.path.split('/Android')[0];

        // Common screenshot paths on different Android devices
        paths.addAll([
          '$baseDir/DCIM/Screenshots',
          '$baseDir/Pictures/Screenshots',
        ]);
      }
    } catch (e) {
      print('Error getting screenshot paths: $e');
    }

    return paths;
  }

  /// Create a Screenshot object from image bytes (useful for web uploads)
  Screenshot createScreenshotFromBytes({
    required Uint8List bytes,
    required String fileName,
    String? path,
  }) {
    return Screenshot(
      id: _uuid.v4(),
      path: path,
      bytes: bytes,
      title: fileName,
      tags: [],
      aiProcessed: false,
      addedOn: DateTime.now(),
      fileSize: bytes.length,
    );
  }

  /// Validate if a file is a supported image format
  bool isValidImageFile(String filePath) {
    final lowercasePath = filePath.toLowerCase();
    return lowercasePath.endsWith('.png') ||
        lowercasePath.endsWith('.jpg') ||
        lowercasePath.endsWith('.jpeg');
  }

  /// Get file size in a human-readable format
  String getFileSizeString(int fileSizeBytes) {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
