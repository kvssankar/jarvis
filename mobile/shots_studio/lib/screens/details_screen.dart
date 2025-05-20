import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:shots_studio/models/screenshot_model.dart'; // Import Screenshot model

class ScreenshotDetailScreen extends StatelessWidget {
  final Screenshot screenshot; // Changed from imageData to screenshot

  const ScreenshotDetailScreen({
    super.key,
    required this.screenshot,
  }); // Updated parameter

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    String imageName =
        screenshot.title ?? 'Screenshot'; // Use title from model or default

    if (screenshot.path != null) {
      imageWidget = Image.file(File(screenshot.path!), fit: BoxFit.cover);
    } else if (screenshot.bytes != null) {
      imageWidget = Image.memory(screenshot.bytes!, fit: BoxFit.cover);
    } else {
      imageWidget = const Center(child: Icon(Icons.broken_image));
      imageName = 'Invalid Image';
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Screenshot Detail',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[900],
              ),
              margin: const EdgeInsets.all(16),
              clipBehavior: Clip.antiAlias,
              child: imageWidget,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    imageName, // Use imageName derived from screenshot.title
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: TextEditingController(
                      text: screenshot.description,
                    ), // Use description from model
                    decoration: InputDecoration(
                      hintText: 'Add a description...',
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white70),
                    maxLines: 3,
                    onChanged: (value) {
                      // Here you would typically update the model and persist changes
                      screenshot.description = value;
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tags',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...screenshot.tags.map(
                        (tag) => _buildTag(tag),
                      ), // Use tags from model
                      _buildTag(
                        '+ Add Tag',
                      ), // This could be a button to add new tags
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Processed',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                        const Spacer(),
                        Icon(
                          screenshot.aiProcessed
                              ? Icons.check_circle
                              : Icons.hourglass_empty,
                          color: Colors.amber[200],
                        ), // Use aiProcessed from model
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white70)),
    );
  }
}
