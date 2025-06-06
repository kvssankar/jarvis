import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/analytics_service.dart';

class FullScreenImageViewer extends StatelessWidget {
  final Screenshot screenshot;

  const FullScreenImageViewer({super.key, required this.screenshot});

  @override
  Widget build(BuildContext context) {
    // Track full screen viewer access
    AnalyticsService().logScreenView('full_screen_image_viewer');

    Widget imageContent;

    if (screenshot.path != null) {
      final file = File(screenshot.path!);
      if (file.existsSync()) {
        imageContent = Image.file(
          file,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    size: 100,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Image could not be loaded',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } else {
        imageContent = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 100,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Image file not found',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The original file may have been moved or deleted',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
    } else if (screenshot.bytes != null) {
      imageContent = Image.memory(
        screenshot.bytes!,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 100,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Image could not be loaded',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      imageContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 100,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Image not available',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(
          screenshot.title ?? 'Screenshot',
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
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
