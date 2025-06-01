import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shots_studio/screens/screenshot_details_screen.dart';
import 'package:shots_studio/screens/screenshot_swipe_detail_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shots_studio/widgets/home_app_bar.dart';
import 'package:shots_studio/widgets/collections/collections_section.dart';
import 'package:shots_studio/widgets/screenshots/screenshots_section.dart';
import 'package:shots_studio/screens/app_drawer_screen.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:shots_studio/services/ai_service_manager.dart';
import 'package:shots_studio/services/ai_service.dart';
import 'package:shots_studio/screens/search_screen.dart';
import 'package:shots_studio/widgets/privacy_dialog.dart';
import 'package:shots_studio/widgets/onboarding/api_key_guide_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shots_studio/services/notification_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/utils/memory_utils.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:shots_studio/widgets/ai_processing_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optimize image cache for better memory management
  MemoryUtils.optimizeImageCache();

  await NotificationService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // Use dynamic colors if available (Material You)
          lightScheme = lightDynamic.harmonized();
          darkScheme = darkDynamic.harmonized();
        } else {
          // Fallback to custom color schemes if dynamic colors are not available
          lightScheme = ColorScheme.fromSeed(
            seedColor: Colors.amber,
            brightness: Brightness.light,
          );
          darkScheme = ColorScheme.fromSeed(
            seedColor: Colors.amber,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'Shots Studio',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightScheme,
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkScheme,
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          themeMode:
              ThemeMode.system, // Automatically switch between light and dark
          home: const HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final List<Screenshot> _screenshots = [];
  final List<Collection> _collections = [];
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();
  bool _isLoading = false;
  bool _isProcessingAI = false;
  int _aiProcessedCount = 0;
  int _aiTotalToProcess = 0;
  final AIServiceManager _aiServiceManager = AIServiceManager();

  // Add a global key for the API key text field
  final GlobalKey<State> _apiKeyFieldKey = GlobalKey();

  // Add loading progress tracking
  int _loadingProgress = 0;
  int _totalToLoad = 0;

  String? _apiKey;
  String _selectedModelName = 'gemini-2.0-flash';
  int _screenshotLimit = 1200;
  int _maxParallelAI = 4;
  bool _isScreenshotLimitEnabled = false;
  bool _devMode = false;
  bool _autoProcessEnabled = true;

  // Shared preferences keys
  static const String _screenshotsKey = 'screenshots';
  static const String _collectionsKey = 'collections';
  static const String _apiKeyKey = 'apiKey';

  // update screenshots
  List<Screenshot> get _activeScreenshots {
    final activeScreenshots =
        _screenshots.where((screenshot) => !screenshot.isDeleted).toList();
    // Sort by addedOn date in descending order (newest first)
    activeScreenshots.sort((a, b) => b.addedOn.compareTo(a.addedOn));
    return activeScreenshots;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDataFromPrefs();
    _loadSettings();
    if (!kIsWeb) {
      _loadAndroidScreenshots();
    }
    // Show privacy dialog after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Show privacy dialog and only proceed to API key guide if accepted
      bool privacyAccepted = await showPrivacyDialogIfNeeded(context);
      if (privacyAccepted && context.mounted) {
        // API key guide will only show after privacy is accepted
        await showApiKeyGuideIfNeeded(context, _apiKey, _updateApiKey);
        // Automatically process any unprocessed screenshots
        _autoProcessWithGemini();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Only clear cache when app is completely detached to preserve collection thumbnails
    if (state == AppLifecycleState.detached) {
      MemoryUtils.clearImageCache();
    }

    // Auto-process unprocessed screenshots when the app comes to foreground
    if (state == AppLifecycleState.resumed) {
      // Add a small delay to ensure the UI is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _autoProcessWithGemini();
      });
    }
  }

  Future<void> _saveDataToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedScreenshots = jsonEncode(
      _screenshots.map((s) => s.toJson()).toList(),
    );
    await prefs.setString('screenshots', encodedScreenshots);

    final String encodedCollections = jsonEncode(
      _collections.map((c) => c.toJson()).toList(),
    );
    await prefs.setString('collections', encodedCollections);
    print("Data saved to SharedPreferences");
  }

  Future<void> _loadDataFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final String? storedScreenshots = prefs.getString('screenshots');
    if (storedScreenshots != null && storedScreenshots.isNotEmpty) {
      final List<dynamic> decodedScreenshots = jsonDecode(storedScreenshots);
      setState(() {
        _screenshots.clear();
        _screenshots.addAll(
          decodedScreenshots.map(
            (json) => Screenshot.fromJson(json as Map<String, dynamic>),
          ),
        );
      });
    }

    final String? storedCollections = prefs.getString('collections');
    if (storedCollections != null && storedCollections.isNotEmpty) {
      final List<dynamic> decodedCollections = jsonDecode(storedCollections);
      setState(() {
        _collections.clear();
        _collections.addAll(
          decodedCollections.map(
            (json) => Collection.fromJson(json as Map<String, dynamic>),
          ),
        );
      });
    }
    print("Data loaded from SharedPreferences");
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString('apiKey');
      _selectedModelName = prefs.getString('modelName') ?? 'gemini-2.0-flash';
      _screenshotLimit = prefs.getInt('limit') ?? 1200;
      _maxParallelAI = prefs.getInt('maxParallel') ?? 4;
      _isScreenshotLimitEnabled = prefs.getBool('limit_enabled') ?? false;
      _devMode = prefs.getBool('dev_mode') ?? false;
      _autoProcessEnabled = prefs.getBool('auto_process_enabled') ?? true;
    });
  }

  void _updateApiKey(String newApiKey) {
    setState(() {
      _apiKey = newApiKey;
    });
    // Save to SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('apiKey', newApiKey);
    });
  }

  void _updateModelName(String newModelName) {
    setState(() {
      _selectedModelName = newModelName;
    });
  }

  void _updateScreenshotLimit(int newLimit) {
    setState(() {
      _screenshotLimit = newLimit;
    });
  }

  void _updateScreenshotLimitEnabled(bool enabled) {
    setState(() {
      _isScreenshotLimitEnabled = enabled;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('limit_enabled', enabled);
    });
  }

  void _updateMaxParallelAI(int newMaxParallel) {
    setState(() {
      _maxParallelAI = newMaxParallel;
    });
  }

  void _updateDevMode(bool value) {
    setState(() {
      _devMode = value;
    });
    // Save to SharedPreferences
    _saveDevMode(value);
  }

  void _updateAutoProcessEnabled(bool enabled) {
    setState(() {
      _autoProcessEnabled = enabled;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('auto_process_enabled', enabled);
    });
  }

  Future<void> _saveDevMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dev_mode', value);
  }

  void _showSnackbarWrapper({
    required String message,
    Color? backgroundColor,
    Duration? duration,
  }) {
    SnackbarService().showSnackbar(
      context,
      message: message,
      backgroundColor: backgroundColor,
      duration: duration,
    );
  }

  Future<void> _processWithGemini() async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      SnackbarService().showError(
        context,
        'Gemini API key not configured. Please check app settings.',
      );
      return;
    }

    final unprocessedScreenshots =
        _activeScreenshots.where((s) => !s.aiProcessed).toList();

    if (unprocessedScreenshots.isEmpty) {
      SnackbarService().showInfo(
        context,
        'All screenshots have already been processed.',
      );
      return;
    }

    setState(() {
      _isProcessingAI = true;
      _aiProcessedCount = 0;
      _aiTotalToProcess = unprocessedScreenshots.length;
    });

    // Get list of collections that have auto-add enabled
    final autoAddCollections =
        _collections
            .where((collection) => collection.isAutoAddEnabled)
            .map(
              (collection) => {
                'name': collection.name,
                'description': collection.description,
                'id': collection.id,
              },
            )
            .toList();

    final config = AIConfig(
      apiKey: _apiKey!,
      modelName: _selectedModelName,
      maxParallel: _maxParallelAI,
      showMessage: _showSnackbarWrapper,
    );

    try {
      // Initialize the AI service manager
      _aiServiceManager.initialize(config);

      final result = await _aiServiceManager.analyzeScreenshots(
        screenshots: unprocessedScreenshots,
        onBatchProcessed: (batch, response) {
          // Update the processed screenshots
          final updatedScreenshots = _aiServiceManager
              .parseAndUpdateScreenshots(batch, response);

          setState(() {
            _aiProcessedCount += updatedScreenshots.length;

            for (var updatedScreenshot in updatedScreenshots) {
              final index = _screenshots.indexWhere(
                (s) => s.id == updatedScreenshot.id,
              );
              if (index != -1) {
                _screenshots[index] = updatedScreenshot;

                // Handle auto-categorization
                List<String> suggestedCollections = [];
                try {
                  if (response['suggestedCollections'] != null) {
                    Map<dynamic, dynamic>? suggestionsMap;

                    // Handle different types of map that might come from the AI response
                    if (response['suggestedCollections']
                        is Map<String, List<String>>) {
                      suggestionsMap =
                          response['suggestedCollections']
                              as Map<String, List<String>>;
                    } else if (response['suggestedCollections']
                        is Map<dynamic, dynamic>) {
                      suggestionsMap =
                          response['suggestedCollections']
                              as Map<dynamic, dynamic>;
                    } else if (response['suggestedCollections'] is Map) {
                      suggestionsMap = Map<dynamic, dynamic>.from(
                        response['suggestedCollections'] as Map,
                      );
                    }

                    // Now safely extract the suggestions list
                    if (suggestionsMap != null &&
                        suggestionsMap.containsKey(updatedScreenshot.id)) {
                      final suggestions = suggestionsMap[updatedScreenshot.id];
                      if (suggestions is List) {
                        suggestedCollections = List<String>.from(
                          suggestions.whereType<String>(),
                        );
                      } else if (suggestions is String) {
                        // Handle case where a single string might be returned instead of a list
                        suggestedCollections = [suggestions];
                      }
                    }
                  }
                } catch (e) {
                  print('Error accessing suggested collections: $e');
                }

                if (suggestedCollections.isNotEmpty) {
                  for (var collection in _collections) {
                    if (collection.isAutoAddEnabled &&
                        suggestedCollections.contains(collection.name) &&
                        !updatedScreenshot.collectionIds.contains(
                          collection.id,
                        ) &&
                        !collection.screenshotIds.contains(
                          updatedScreenshot.id,
                        )) {
                      // Auto-add screenshot to this collection
                      final updatedCollection = collection.addScreenshot(
                        updatedScreenshot.id,
                        isAutoCategorized: true,
                      );
                      _updateCollection(updatedCollection);

                      updatedScreenshot.collectionIds.add(collection.id);
                    }
                  }
                }
              }
            }
          });
        },
        autoAddCollections: autoAddCollections,
      );

      if (result.success) {
        final processedCount = result.data?['processedCount'] ?? 0;

        // Count how many screenshots were auto-categorized
        int autoCategorizedCount = 0;
        for (var screenshot in _activeScreenshots.where((s) => s.aiProcessed)) {
          if (screenshot.collectionIds.isNotEmpty) {
            autoCategorizedCount++;
          }
        }

        // Show completion message with auto-categorization info
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completed processing $processedCount of ${unprocessedScreenshots.length} screenshots.',
                ),
                if (autoCategorizedCount > 0)
                  Text(
                    'Auto-categorized $autoCategorizedCount screenshots based on content.',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        SnackbarService().showError(
          context,
          result.error ?? 'Failed to process screenshots',
        );
      }
    } catch (e) {
      SnackbarService().showError(context, 'Error processing screenshots: $e');
    }

    // Save data after all processing is done
    await _saveDataToPrefs();

    setState(() {
      _isProcessingAI = false;
      _aiProcessedCount = 0;
      _aiTotalToProcess = 0;
    });
  }

  Future<void> _stopProcessingAI() async {
    if (_isProcessingAI) {
      setState(() {
        _aiTotalToProcess = 0;
      });

      _aiServiceManager.cancelAllOperations();

      SnackbarService().showWarning(context, 'AI processing stopped by user.');

      await _saveDataToPrefs();
      setState(() {
        _isProcessingAI = false;
      });
    }
  }

  Future<void> _takeScreenshot(ImageSource source) async {
    try {
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

      if (images != null && images.isNotEmpty) {
        setState(() {
          _isLoading = true;
        });

        List<Screenshot> newScreenshots = [];
        for (var image in images) {
          final bytes = await image.readAsBytes();
          final String imageId = _uuid.v4();
          final String imageName = image.name;

          // Check if a screenshot with the same path (if available) or bytes already exists
          // For web, path might be null, so rely on bytes if path is not distinctive
          bool exists = false;
          if (!kIsWeb && image.path.isNotEmpty) {
            exists = _screenshots.any((s) => s.path == image.path);
          } else {
            // for web, check is removed since path is not available
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

        setState(() {
          _screenshots.addAll(newScreenshots);
          _isLoading = false;
          _loadingProgress = 0;
          _totalToLoad = 0;
        });
        await _saveDataToPrefs();

        // Auto-process the newly added screenshots
        if (newScreenshots.isNotEmpty) {
          _autoProcessWithGemini();
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadingProgress = 0;
        _totalToLoad = 0;
      });
      print('Error picking images: $e');
    }
  }

  Future<void> _loadAndroidScreenshots() async {
    if (kIsWeb) return;

    // Check if screenshots are already loaded to avoid redundant loading on hot reload/restart
    // This simple check might need refinement based on how often new screenshots are expected
    // if (_screenshots.isNotEmpty && !_isLoading) { // Basic check
    //   print("Android screenshots seem already loaded or loading is in progress.");
    //   return;
    // }

    try {
      var status = await Permission.photos.request();
      if (!status.isGranted) {
        SnackbarService().showError(
          context,
          'Photos permission denied. Cannot load screenshots.',
        );
        return;
      }

      setState(() {
        _isLoading = true;
        _loadingProgress = 0;
        _totalToLoad = 0;
      });

      // Get common Android screenshot directories
      List<String> possibleScreenshotPaths = await _getScreenshotPaths();
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

      allFiles.sort((a, b) {
        return File(
          b.path,
        ).lastModifiedSync().compareTo(File(a.path).lastModifiedSync());
      });

      // Apply limit if enabled
      final limitedFiles =
          _isScreenshotLimitEnabled
              ? allFiles.take(_screenshotLimit).toList()
              : allFiles.toList();

      setState(() {
        _totalToLoad = limitedFiles.length;
      });

      List<Screenshot> loadedScreenshots = [];

      // Process files in batches to avoid memory spikes
      const int batchSize = 20;
      for (int i = 0; i < limitedFiles.length; i += batchSize) {
        final batch = limitedFiles.skip(i).take(batchSize);

        for (var fileEntity in batch) {
          final file = File(fileEntity.path);

          // Skip if already exists by path
          if (_screenshots.any((s) => s.path == file.path)) {
            print('Skipping already loaded file via path check: ${file.path}');
            setState(() {
              _loadingProgress++;
            });
            continue;
          }

          // Check if the file path contains ".trashed" and skip if it does
          if (file.path.contains('.trashed')) {
            print('Skipping trashed file: ${file.path}');
            setState(() {
              _loadingProgress++;
            });
            continue;
          }

          final fileSize = await file.length();

          // Skip very large files to prevent memory issues
          if (fileSize > 50 * 1024 * 1024) {
            // Skip files larger than 50MB
            print('Skipping large file: ${file.path} ($fileSize bytes)');
            setState(() {
              _loadingProgress++;
            });
            continue;
          }

          loadedScreenshots.add(
            Screenshot(
              id: _uuid.v4(), // Generate new UUID for each
              path: file.path,
              title: file.path.split('/').last,
              tags: [],
              aiProcessed: false,
              addedOn: await file.lastModified(),
              fileSize: fileSize,
            ),
          );

          setState(() {
            _loadingProgress++;
          });
        }

        // Update UI periodically to show progress
        if (i % batchSize == 0 && loadedScreenshots.isNotEmpty) {
          setState(() {
            _screenshots.insertAll(0, loadedScreenshots);
          });
          loadedScreenshots.clear();
          // Small delay to prevent UI blocking
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      // Add any remaining screenshots
      if (loadedScreenshots.isNotEmpty) {
        setState(() {
          _screenshots.insertAll(0, loadedScreenshots);
        });
      }

      setState(() {
        _isLoading = false;
        _loadingProgress = 0;
        _totalToLoad = 0;
      });
      await _saveDataToPrefs();

      // Auto-process newly loaded screenshots
      if (_screenshots.isNotEmpty) {
        _autoProcessWithGemini();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadingProgress = 0;
        _totalToLoad = 0;
      });
      print('Error loading Android screenshots: $e');
    }
  }

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

  void _addCollection(Collection collection) {
    setState(() {
      _collections.add(collection);
    });
    _saveDataToPrefs();
  }

  void _updateCollection(Collection updatedCollection) {
    setState(() {
      final index = _collections.indexWhere(
        (c) => c.id == updatedCollection.id,
      );
      if (index != -1) {
        _collections[index] = updatedCollection;
      }
    });
    _saveDataToPrefs();
  }

  void _deleteCollection(String collectionId) {
    setState(() {
      _collections.removeWhere((c) => c.id == collectionId);
      for (var screenshot in _screenshots) {
        screenshot.collectionIds.remove(collectionId);
      }
    });
    _saveDataToPrefs();
  }

  void _deleteScreenshot(String screenshotId) {
    setState(() {
      // Mark screenshot as deleted instead of removing it
      final screenshotIndex = _screenshots.indexWhere(
        (s) => s.id == screenshotId,
      );
      if (screenshotIndex != -1) {
        _screenshots[screenshotIndex].isDeleted = true;
      }

      // Remove screenshot from all collections
      for (var collection in _collections) {
        if (collection.screenshotIds.contains(screenshotId)) {
          final updatedCollection = collection.removeScreenshot(screenshotId);
          _updateCollection(updatedCollection);
        }
      }
    });
    _saveDataToPrefs();
  }

  void _navigateToSearchScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => SearchScreen(
              allScreenshots: _activeScreenshots,
              allCollections: _collections,
              onUpdateCollection: _updateCollection,
              onDeleteScreenshot: _deleteScreenshot,
            ),
      ),
    );
  }

  // Helper method to check and auto-process screenshots
  Future<void> _autoProcessWithGemini() async {
    // Only auto-process if enabled, we have an API key, and we're not already processing
    if (_autoProcessEnabled &&
        _apiKey != null &&
        _apiKey!.isNotEmpty &&
        !_isProcessingAI) {
      // Check if there are any unprocessed screenshots
      final unprocessedScreenshots =
          _activeScreenshots.where((s) => !s.aiProcessed).toList();
      if (unprocessedScreenshots.isNotEmpty) {
        // Add a small delay to allow UI to update before processing starts
        await Future.delayed(const Duration(milliseconds: 300));
        _processWithGemini();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(
        onProcessWithAI: _isProcessingAI ? null : _processWithGemini,
        isProcessingAI: _isProcessingAI,
        aiProcessedCount: _aiProcessedCount,
        aiTotalToProcess: _aiTotalToProcess,
        onSearchPressed: _navigateToSearchScreen,
        onStopProcessingAI: _stopProcessingAI,
        devMode: _devMode,
        autoProcessEnabled: _autoProcessEnabled,
      ),
      drawer: AppDrawer(
        currentApiKey: _apiKey,
        currentModelName: _selectedModelName,
        onApiKeyChanged: _updateApiKey,
        onModelChanged: _updateModelName,
        currentLimit: _screenshotLimit,
        onLimitChanged: _updateScreenshotLimit,
        currentMaxParallel: _maxParallelAI,
        onMaxParallelChanged: _updateMaxParallelAI,
        currentLimitEnabled: _isScreenshotLimitEnabled,
        onLimitEnabledChanged: _updateScreenshotLimitEnabled,
        currentDevMode: _devMode,
        onDevModeChanged: _updateDevMode,
        currentAutoProcessEnabled: _autoProcessEnabled,
        onAutoProcessEnabledChanged: _updateAutoProcessEnabled,
        apiKeyFieldKey: _apiKeyFieldKey,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show options for selecting screenshots
          showModalBottomSheet(
            context: context,
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder:
                (context) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.photo_library),
                        title: const Text('Select from gallery'),
                        onTap: () {
                          Navigator.pop(context);
                          _takeScreenshot(ImageSource.gallery);
                        },
                      ),
                      if (!kIsWeb) // Camera option only for mobile
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Take a photo'),
                          onTap: () {
                            Navigator.pop(context);
                            _takeScreenshot(ImageSource.camera);
                          },
                        ),
                      if (!kIsWeb) // Android screenshot loading option
                        ListTile(
                          leading: const Icon(Icons.folder_open),
                          title: const Text('Load device screenshots'),
                          onTap: () {
                            Navigator.pop(context);
                            _loadAndroidScreenshots();
                          },
                        ),
                    ],
                  ),
                ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          Icons.add_a_photo,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('Loading screenshots...'),
                    if (_totalToLoad > 0) ...[
                      const SizedBox(height: 8),
                      Text('$_loadingProgress / $_totalToLoad'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value:
                            _totalToLoad > 0
                                ? _loadingProgress / _totalToLoad
                                : 0,
                      ),
                    ],
                  ],
                ),
              )
              : NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // AI Processing Container
                          AIProcessingContainer(
                            isProcessing: _isProcessingAI,
                            processedCount: _aiProcessedCount,
                            totalCount: _aiTotalToProcess,
                            onStop: _stopProcessingAI,
                          ),
                          // Collections Section
                          CollectionsSection(
                            collections: _collections,
                            screenshots: _activeScreenshots,
                            onCollectionAdded: _addCollection,
                            onUpdateCollection: _updateCollection,
                            onDeleteCollection: _deleteCollection,
                            onDeleteScreenshot: _deleteScreenshot,
                          ),
                        ],
                      ),
                    ),
                  ];
                },
                body: ScreenshotsSection(
                  screenshots: _activeScreenshots,
                  onScreenshotTap: _showScreenshotDetail,
                  screenshotDetailBuilder: (context, screenshot) {
                    final int initialIndex = _activeScreenshots.indexWhere(
                      (s) => s.id == screenshot.id,
                    );
                    return ScreenshotSwipeDetailScreen(
                      screenshots: List.from(_activeScreenshots),
                      initialIndex: initialIndex >= 0 ? initialIndex : 0,
                      allCollections: _collections,
                      onUpdateCollection: (updatedCollection) {
                        _updateCollection(updatedCollection);
                      },
                      onDeleteScreenshot: _deleteScreenshot,
                      onScreenshotUpdated: () {
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
    );
  }

  void _showScreenshotDetail(Screenshot screenshot) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder:
                (context) => ScreenshotDetailScreen(
                  screenshot: screenshot,
                  allCollections: _collections,
                  onUpdateCollection: (updatedCollection) {
                    _updateCollection(updatedCollection);
                  },
                  onDeleteScreenshot: _deleteScreenshot,
                  onScreenshotUpdated: () {
                    setState(() {});
                  },
                ),
          ),
        )
        .then((_) {
          _saveDataToPrefs();
          // Don't clear cache to preserve collection thumbnails
        });
  }
}
