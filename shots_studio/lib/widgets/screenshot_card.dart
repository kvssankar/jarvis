import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shots_studio/models/screenshot_model.dart'; // Import Screenshot model

class ScreenshotCard extends StatelessWidget {
  final Screenshot screenshot; // Changed from imageData to screenshot
  final VoidCallback onTap;

  const ScreenshotCard({
    super.key,
    required this.screenshot, // Updated parameter
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (screenshot.path != null) {
      imageWidget = Image.file(File(screenshot.path!), fit: BoxFit.cover);
    } else if (screenshot.bytes != null) {
      imageWidget = Image.memory(screenshot.bytes!, fit: BoxFit.cover);
    } else {
      imageWidget = const Center(child: Icon(Icons.broken_image));
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [Expanded(child: imageWidget)],
        ),
      ),
    );
  }
}
