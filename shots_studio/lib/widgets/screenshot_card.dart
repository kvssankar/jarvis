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
        child: Stack(
          // Added Stack to overlay the checkmark
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [Expanded(child: imageWidget)],
            ),
            if (screenshot.aiProcessed)
              Positioned(
                bottom: 4,
                right: 4,
                child: Icon(
                  Icons.check_circle,
                  color: Colors.amber.shade200,
                  size: 20,
                ),
              ),
            // Show collection indicator if screenshot belongs to any collections
            if (screenshot.collectionIds.isNotEmpty)
              Positioned(
                top: 4,
                left: 4,
                child: Tooltip(
                  message:
                      'Added to ${screenshot.collectionIds.length} collection(s)',
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder,
                          color: Colors.amber.shade200,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${screenshot.collectionIds.length}',
                          style: TextStyle(
                            color: Colors.amber.shade200,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
