import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shots_studio/models/screenshot_model.dart';

class FullScreenImageViewer extends StatelessWidget {
  final Screenshot screenshot;

  const FullScreenImageViewer({super.key, required this.screenshot});

  @override
  Widget build(BuildContext context) {
    Widget imageContent;

    if (screenshot.path != null) {
      imageContent = Image.file(File(screenshot.path!));
    } else if (screenshot.bytes != null) {
      imageContent = Image.memory(screenshot.bytes!);
    } else {
      imageContent = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 100, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              'Image not available',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          screenshot.title ?? 'Screenshot',
          style: const TextStyle(color: Colors.white, fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: imageContent,
        ),
      ),
    );
  }
}
