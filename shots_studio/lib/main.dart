import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shots_studio/screens/screenshot_details_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shots_studio/widgets/home_app_bar.dart';
import 'package:shots_studio/widgets/collections_section.dart';
import 'package:shots_studio/widgets/screenshots_section.dart';
import 'package:shots_studio/screens/app_drawer_screen.dart';
import 'dart:typed_data';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:shots_studio/models/gemini_model.dart';
import 'package:shots_studio/screens/search_screen.dart';
import 'package:shots_studio/widgets/privacy_dialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shots Studio',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: Colors.amber.shade200,
          secondary: Colors.amber.shade100,
          surface: Colors.black,
        ),
        cardTheme: CardTheme(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Screenshot> _screenshots = [];
  final List<Collection> _collections = [];
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();
  bool _isLoading = false;
  bool _isProcessingAI = false;
  int _aiProcessedCount = 0;
  int _aiTotalToProcess = 0;
  GeminiModel? _geminiModelInstance;

  String? _apiKey;
  String _selectedModelName = 'gemini-2.0-flash';
  int _screenshotLimit = 50;
  int _maxParallelAI = 4;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadAndroidScreenshots();
    }
    // Show privacy dialog after the first frame
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => showPrivacyDialogIfNeeded(context),
    );
  }

  void _updateApiKey(String newApiKey) {
    setState(() {
      _apiKey = newApiKey;
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

  void _updateMaxParallelAI(int newMaxParallel) {
    setState(() {
      _maxParallelAI = newMaxParallel;
    });
  }

  void _showSnackbar({
    required String message,
    Color? backgroundColor,
    Duration? duration,
  }) {
    if (!mounted) return; // Check if the widget is still in the tree
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: 4), // Default duration
      ),
    );
  }

  Future<void> _processWithGemini() async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      _showSnackbar(
        message: 'API Key is not set. Please set it in the drawer.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    // Filter unprocessed screenshots
    final unprocessedScreenshots =
        _screenshots.where((s) => !s.aiProcessed).toList();

    if (unprocessedScreenshots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No unprocessed screenshots found.')),
      );
      return;
    }

    setState(() {
      _isProcessingAI = true;
      _aiTotalToProcess = unprocessedScreenshots.length;
      _aiProcessedCount = 0;
    });

    // Create a list of collections with isAutoAddEnabled set to true
    // Include both name and description for each collection
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

    _geminiModelInstance = GeminiModel(
      modelName: _selectedModelName,
      apiKey: _apiKey!,
      maxParallel: _maxParallelAI,
      showMessage: _showSnackbar,
    );

    // final results = await geminiModel.processBatchedImages(unprocessedScreenshots, (
    final results = await _geminiModelInstance!.processBatchedImages(
      unprocessedScreenshots,
      (batch, result) {
        // This callback is called after each batch is processed
        final updatedScreenshots = _geminiModelInstance!
            .parseResponseAndUpdateScreenshots(batch, result);

        setState(() {
          _aiProcessedCount += updatedScreenshots.length;
          for (var updatedScreenshot in updatedScreenshots) {
            final index = _screenshots.indexWhere(
              (s) => s.id == updatedScreenshot.id,
            );
            if (index != -1) {
              _screenshots[index] = updatedScreenshot;

              List<String> suggestedCollections = [];
              try {
                if (result['suggestedCollections'] != null) {
                  Map<dynamic, dynamic>? suggestionsMap;

                  // Handle different types of map that might come from the AI response
                  if (result['suggestedCollections']
                      is Map<String, List<String>>) {
                    suggestionsMap =
                        result['suggestedCollections']
                            as Map<String, List<String>>;
                  } else if (result['suggestedCollections']
                      is Map<dynamic, dynamic>) {
                    suggestionsMap =
                        result['suggestedCollections'] as Map<dynamic, dynamic>;
                  } else if (result['suggestedCollections'] is Map) {
                    suggestionsMap = Map<dynamic, dynamic>.from(
                      result['suggestedCollections'] as Map,
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

    final processedCount = results['processedCount'] as int;

    // Count how many screenshots were auto-categorized
    int autoCategorizedCount = 0;
    for (var screenshot in _screenshots.where((s) => s.aiProcessed)) {
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

    setState(() {
      _isProcessingAI = false;
      _geminiModelInstance = null;
      // _aiProcessedCount = 0;
      // _aiTotalToProcess = 0;
    });
  }

  void _stopProcessingAI() {
    if (_isProcessingAI) {
      setState(() {
        _isProcessingAI = false;
        _aiProcessedCount = 0;
        _aiTotalToProcess = 0;
      });
      _geminiModelInstance?.cancel();
      _geminiModelInstance = null;

      _showSnackbar(
        message: 'AI Processing Cancelled.',
        backgroundColor: Colors.orange,
      );
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
          final id = _uuid.v4();
          String? imagePath;
          Uint8List? imageBytes;
          int? fileSize;

          if (kIsWeb) {
            imageBytes = await image.readAsBytes();
            fileSize = imageBytes.length;
          } else {
            imagePath = image.path;
            final file = File(imagePath);
            fileSize = await file.length();
          }

          newScreenshots.add(
            Screenshot(
              id: id,
              path: imagePath,
              bytes: imageBytes,
              title: image.name,
              tags: [],
              aiProcessed: false,
              addedOn: DateTime.now(),
              fileSize: fileSize, // Assign fileSize
            ),
          );
        }

        setState(() {
          _screenshots.addAll(newScreenshots);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error picking images: $e');
    }
  }

  Future<void> _loadAndroidScreenshots() async {
    if (kIsWeb) return;

    try {
      var status = await Permission.photos.request();
      if (!status.isGranted) {
        // Handle permission denied
        _showSnackbar(
          message: 'Photos permission denied. Cannot load screenshots.',
          backgroundColor: Colors.redAccent,
        );
        return;
      }

      setState(() {
        _isLoading = true;
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

      // Limit number of screenshots to prevent memory issues (adjust as needed)
      final limitedFiles = allFiles.take(_screenshotLimit).toList();

      List<Screenshot> loadedScreenshots = [];
      for (var fileEntity in limitedFiles) {
        final file = File(fileEntity.path);

        // Skip if already exists
        if (_screenshots.any((s) => s.path == file.path)) {
          print('Skipping already loaded file: ${file.path}');
          continue;
        }

        // Check if the file path contains ".trashed" and skip if it does
        if (file.path.contains('.trashed')) {
          print('Skipping trashed file: ${file.path}');
          continue;
        }

        final fileSize = await file.length(); // Get file size
        loadedScreenshots.add(
          Screenshot(
            id: _uuid.v4(),
            path: file.path,
            title: file.path.split('/').last,
            tags: [],
            aiProcessed: false,
            addedOn: await file.lastModified(),
            fileSize: fileSize, // Assign fileSize
          ),
        );
      }

      setState(() {
        _screenshots.addAll(loadedScreenshots);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
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
  }

  void _deleteCollection(String collectionId) {
    setState(() {
      _collections.removeWhere((c) => c.id == collectionId);
    });
  }

  void _navigateToSearchScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => SearchScreen(
              allScreenshots: _screenshots,
              allCollections: _collections,
              onUpdateCollection: _updateCollection,
            ),
      ),
    );
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show options for selecting screenshots
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.grey[900],
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
        child: const Icon(Icons.add_a_photo, color: Colors.black),
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading screenshots...'),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CollectionsSection(
                      collections: _collections,
                      screenshots: _screenshots,
                      onCollectionAdded: _addCollection,
                      onUpdateCollection: _updateCollection,
                      onDeleteCollection: _deleteCollection,
                    ), // Use CollectionsSection widget
                    ScreenshotsSection(
                      screenshots: _screenshots,
                      onScreenshotTap: _showScreenshotDetail,
                    ), // Use ScreenshotsSection widget
                    const SizedBox(height: 80), // Space for FAB
                  ],
                ),
              ),
    );
  }

  void _showScreenshotDetail(Screenshot screenshot) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ScreenshotDetailScreen(
              screenshot: screenshot,
              allCollections: _collections, // Pass all collections
              onUpdateCollection: _updateCollection, // Pass update callback
            ),
      ),
    );
  }
}
