import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/analytics_service.dart';

class FullScreenImageViewer extends StatefulWidget {
  final List<Screenshot> screenshots;
  final int initialIndex;
  final Function(int)? onScreenshotChanged;

  const FullScreenImageViewer({
    super.key,
    required this.screenshots,
    required this.initialIndex,
    this.onScreenshotChanged,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    // Ensure initialIndex is within bounds
    _currentIndex = widget.initialIndex.clamp(0, widget.screenshots.length - 1);
    _pageController = PageController(initialPage: _currentIndex);

    // Track full screen viewer access
    AnalyticsService().logScreenView('full_screen_image_viewer');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    widget.onScreenshotChanged?.call(index);

    // Track swipe navigation
    AnalyticsService().logFeatureUsed('full_screen_swipe_navigation');
  }

  Widget _buildImageContent(Screenshot screenshot) {
    if (screenshot.path != null) {
      final file = File(screenshot.path!);
      if (file.existsSync()) {
        return Image.file(
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
        return Center(
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
      return Image.memory(
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
  }

  @override
  Widget build(BuildContext context) {
    // Ensure currentIndex is still valid (defensive programming)
    if (_currentIndex < 0 || _currentIndex >= widget.screenshots.length) {
      _currentIndex = 0;
    }

    final currentScreenshot = widget.screenshots[_currentIndex];

    return PopScope(
      canPop: false, // Prevent default pop behavior
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Handle the back gesture/button by returning the current index
          Navigator.of(context).pop(_currentIndex);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(_currentIndex),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          title: Text(
            currentScreenshot.title ?? 'Screenshot',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (widget.screenshots.length > 1)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '${_currentIndex + 1} / ${widget.screenshots.length}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body:
            widget.screenshots.length == 1
                ? Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: _buildImageContent(currentScreenshot),
                  ),
                )
                : PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: widget.screenshots.length,
                  itemBuilder: (context, index) {
                    return Center(
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: _buildImageContent(widget.screenshots[index]),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
