import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shots_studio/models/screenshot_model.dart';

class ScreenshotCard extends StatelessWidget {
  final Screenshot screenshot;
  final VoidCallback onTap;

  const ScreenshotCard({
    super.key,
    required this.screenshot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (screenshot.path != null) {
      imageWidget = Image.file(
        File(screenshot.path!),
        fit: BoxFit.cover,
        cacheWidth: 300, // cacheHeight is automatically calculated
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    } else if (screenshot.bytes != null) {
      imageWidget = Image.memory(
        screenshot.bytes!,
        fit: BoxFit.cover,
        cacheWidth: 300, // cacheHeight is automatically calculated
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    } else {
      imageWidget = const Center(child: Icon(Icons.broken_image));
    }

    return RepaintBoundary(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
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
            ],
          ),
        ),
      ),
    );
  }
}
