import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb
import 'package:flutter/material.dart';
import 'package:shots_studio/screens/details_screen.dart'; // Updated import
import 'package:image_picker/image_picker.dart';
import 'package:shots_studio/widgets/screenshot_card.dart'; // New import
import 'dart:typed_data'; // Import for Uint8List
import 'package:shots_studio/models/screenshot_model.dart'; // Import Screenshot model
import 'package:uuid/uuid.dart'; // Import Uuid for generating IDs

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PixelShot',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takeScreenshot,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add_a_photo, color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Collections',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Container(
              height: 150,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.brown[800],
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create your first collection to',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'organize your screenshots',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Card(
                    child: Container(
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.amber[200],
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 32,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Screenshots',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _screenshots.length, // Updated to _screenshots.length
              itemBuilder: (context, index) {
                return ScreenshotCard(
                  screenshot: _screenshots[index], // Pass Screenshot object
                  onTap: () => _showScreenshotDetail(_screenshots[index]),
                );
              },
            ),
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  void _showScreenshotDetail(Screenshot screenshot) {
    // Parameter is now Screenshot
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ScreenshotDetailScreen(
              screenshot: screenshot,
            ), // Pass Screenshot object
      ),
    );
  }
}
