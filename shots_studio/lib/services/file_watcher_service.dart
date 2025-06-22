import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/custom_path_service.dart';
import 'package:uuid/uuid.dart';

class FileWatcherService {
  static final FileWatcherService _instance = FileWatcherService._internal();
  factory FileWatcherService() => _instance;
  FileWatcherService._internal();

  StreamController<List<Screenshot>>? _newScreenshotsController;
  Stream<List<Screenshot>>? _newScreenshotsStream;

  final List<StreamSubscription> _subscriptions = [];
  final Set<String> _processedFiles = {};
  Timer? _debounceTimer;
  final Uuid _uuid = Uuid();

  /// Stream of newly detected screenshots
  Stream<List<Screenshot>> get newScreenshotsStream {
    _newScreenshotsController ??=
        StreamController<List<Screenshot>>.broadcast();
    _newScreenshotsStream ??= _newScreenshotsController!.stream;
    return _newScreenshotsStream!;
  }

  /// Start monitoring screenshot directories for new files
  Future<void> startWatching() async {
    if (kIsWeb) return; // Not supported on web

    try {
      final screenshotPaths = await _getScreenshotPaths();

      for (final path in screenshotPaths) {
        final directory = Directory(path);
        if (await directory.exists()) {
          print('FileWatcher: Starting to watch $path');

          // Initial scan to populate known files
          await _scanDirectoryInitial(directory);

          // Watch for changes
          final subscription = directory
              .watch(events: FileSystemEvent.create | FileSystemEvent.modify)
              .where((event) => _isImageFile(event.path))
              .listen(_handleFileSystemEvent);

          _subscriptions.add(subscription);
        }
      }
    } catch (e) {
      print('FileWatcher: Error starting watcher: $e');
    }
  }

  /// Stop monitoring file system
  Future<void> stopWatching() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _debounceTimer?.cancel();
    _processedFiles.clear();
  }

  /// Handle file system events with debouncing
  void _handleFileSystemEvent(FileSystemEvent event) {
    print('FileWatcher: Detected file event: ${event.path}');

    // Debounce rapid file events (e.g., during file creation)
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _processNewFile(event.path);
    });
  }

  /// Process a newly detected file
  Future<void> _processNewFile(String filePath) async {
    try {
      final file = File(filePath);

      // Skip if already processed or file doesn't exist
      if (_processedFiles.contains(filePath) || !await file.exists()) {
        return;
      }

      // Add small delay to ensure file is fully written
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify file is accessible and not empty
      final fileSize = await file.length();
      if (fileSize == 0) return;

      print('FileWatcher: Processing new screenshot: $filePath');

      final screenshot = Screenshot(
        id: _uuid.v4(),
        path: filePath,
        title: filePath.split('/').last,
        tags: [],
        aiProcessed: false,
        addedOn: await file.lastModified(),
        fileSize: fileSize,
      );

      _processedFiles.add(filePath);

      // Emit new screenshot
      _newScreenshotsController?.add([screenshot]);
    } catch (e) {
      print('FileWatcher: Error processing file $filePath: $e');
    }
  }

  /// Initial scan to populate known files
  Future<void> _scanDirectoryInitial(Directory directory) async {
    try {
      final files = directory.listSync().whereType<File>().where(
        (file) => _isImageFile(file.path),
      );

      for (final file in files) {
        _processedFiles.add(file.path);
      }

      print(
        'FileWatcher: Initial scan found ${files.length} existing files in ${directory.path}',
      );
    } catch (e) {
      print('FileWatcher: Error in initial scan: $e');
    }
  }

  /// Check if file is an image
  bool _isImageFile(String path) {
    final extension = path.toLowerCase();
    return extension.endsWith('.png') ||
        extension.endsWith('.jpg') ||
        extension.endsWith('.jpeg');
  }

  /// Get screenshot directory paths
  Future<List<String>> _getScreenshotPaths() async {
    final List<String> paths = [];

    try {
      if (Platform.isAndroid) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final baseDir = externalDir.path.split('/Android').first;
          paths.addAll([
            '$baseDir/DCIM/Screenshots',
            '$baseDir/Pictures/Screenshots',
            '$baseDir/Download',
          ]);
        }
      } else if (Platform.isIOS) {
        final documentsDir = await getApplicationDocumentsDirectory();
        paths.add('${documentsDir.path}/Screenshots');
      }

      // Add custom paths
      final customPaths = await CustomPathService.getCustomPaths();
      paths.addAll(customPaths);
    } catch (e) {
      print('FileWatcher: Error getting screenshot paths: $e');
    }

    return paths;
  }

  /// Dispose resources
  void dispose() {
    stopWatching();
    _newScreenshotsController?.close();
  }
}
