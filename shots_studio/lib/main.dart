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
import 'package:shots_studio/models/gemini_model.dart'; // Added import

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

  String? _apiKey;
  String _selectedModelName = 'gemini-2.0-flash';

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadAndroidScreenshots();
    }
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

  Future<void> _processWithGemini() async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API Key is not set. Please set it in the drawer.'),
        ),
      );
      return;
    }

    final geminiModel = GeminiModel(
      model_name: _selectedModelName,
      api_key: _apiKey!,
    );

    final response = geminiModel.ask();
    print('Gemini says: $response');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Gemini says: $response')));
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
        // For mobile gallery, allow multiple image selection
        images = await _picker.pickMultiImage();
      }

      if (images != null && images.isNotEmpty) {
        setState(() {
          _isLoading = true;
        });

        for (var image in images) {
          String id = _uuid.v4();
          DateTime now = DateTime.now();
          Screenshot newScreenshot;

          if (kIsWeb) {
            final Uint8List imageBytes = await image.readAsBytes();
            newScreenshot = Screenshot(
              id: id,
              bytes: imageBytes,
              title: 'Screenshot ${id.substring(0, 8)}',
              description: '',
              tags: [],
              aiProcessed: false,
              addedOn: now,
            );
          } else {
            newScreenshot = Screenshot(
              id: id,
              path: image.path,
              title: 'Screenshot ${image.path.split('/').last}',
              description: '',
              tags: [],
              aiProcessed: false,
              addedOn: now,
            );
          }
          _screenshots.add(newScreenshot);
        }

        setState(() {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Storage permission not granted to load screenshots.',
            ),
          ),
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
        final dir = Directory(dirPath);
        if (await dir.exists()) {
          final files = await dir.list().toList();
          allFiles.addAll(
            files.where(
              (file) =>
                  file.path.toLowerCase().endsWith('.jpg') ||
                  file.path.toLowerCase().endsWith('.jpeg') ||
                  file.path.toLowerCase().endsWith('.png'),
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
      final filesToProcess = allFiles.take(100).toList();

      for (var file in filesToProcess) {
        try {
          // TODO: Optimize this check
          if (_screenshots.any((s) => s.path == file.path)) {
            print('Skipping already loaded file: ${file.path}');
            continue; // Skip if already exists
          }

          String id = _uuid.v4();
          DateTime fileModifiedTime = File(file.path).lastModifiedSync();

          Screenshot newScreenshot = Screenshot(
            id: id,
            path: file.path,
            title: 'Screenshot ${file.path.split('/').last}',
            description: '',
            tags: [],
            aiProcessed: false,
            addedOn: fileModifiedTime,
          );

          // Check if the file path contains ".trashed" and skip if it does
          if (file.path.contains('.trashed')) {
            print('Skipping trashed file: ${file.path}');
            continue;
          }

          _screenshots.add(newScreenshot);
        } catch (e) {
          print('Error processing file ${file.path}: $e');
          continue;
        }
      }

      setState(() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(onProcessWithAI: _processWithGemini),
      drawer: AppDrawer(
        currentApiKey: _apiKey,
        currentModelName: _selectedModelName,
        onApiKeyChanged: _updateApiKey,
        onModelChanged: _updateModelName,
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
