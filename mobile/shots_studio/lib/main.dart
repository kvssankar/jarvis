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

  Future<void> _takeScreenshot() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
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
        setState(() {
          _screenshots.add(newScreenshot);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
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
      appBar: const HomeAppBar(), // Use HomeAppBar widget
      floatingActionButton: FloatingActionButton(
        onPressed: _takeScreenshot,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add_a_photo, color: Colors.black),
      ),
      body: SingleChildScrollView(
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
