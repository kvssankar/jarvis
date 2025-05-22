import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shots_studio/screens/screenshot_details_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shots_studio/widgets/home_app_bar.dart';
import 'package:shots_studio/widgets/collections_section.dart';
import 'package:shots_studio/widgets/screenshots_section.dart';
import 'dart:typed_data';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PixelShot',
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

  @override
  void initState() {
    super.initState();
    // Load Android screenshots if on Android platform
    if (!kIsWeb) {
      _loadAndroidScreenshots();
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
        // For web, we can only pick one image at a time
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null) {
          images = [image];
        }
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
    print('Loading Android screenshots... ISN"T WORKING');
    if (kIsWeb) return;

    try {
      // Request storage permission
      // TODO: Handle permission request not working
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Get common Android screenshot directories
      List<String> possibleScreenshotPaths = await _getScreenshotPaths();
      List<FileSystemEntity> allFiles = [];
      print('Possible screenshot paths: $possibleScreenshotPaths');
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
      print('Found ${allFiles.length} screenshot files');

      // Sort files by last modified time (newest first)
      allFiles.sort((a, b) {
        return File(
          b.path,
        ).lastModifiedSync().compareTo(File(a.path).lastModifiedSync());
      });

      // Limit number of screenshots to prevent memory issues (adjust as needed)
      final filesToProcess = allFiles.take(100).toList();

      for (var file in filesToProcess) {
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

        _screenshots.add(newScreenshot);
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
          '$baseDir/Download',
          '$baseDir/DCIM/Camera',
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
      appBar: HomeAppBar(
        onRefresh: _loadAndroidScreenshots,
      ), // Use HomeAppBar widget with refresh functionality
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
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Loading screenshots...'),
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
