import 'package:flutter/material.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/screens/screenshot_details_screen.dart';

class ScreenshotSwipeDetailScreen extends StatefulWidget {
  final List<Screenshot> screenshots;
  final int initialIndex;
  final List<Collection> allCollections;
  final List<Screenshot> allScreenshots;
  final Function(Collection) onUpdateCollection;
  final Function(String) onDeleteScreenshot;
  final VoidCallback? onScreenshotUpdated;

  const ScreenshotSwipeDetailScreen({
    super.key,
    required this.screenshots,
    required this.initialIndex,
    required this.allCollections,
    required this.allScreenshots,
    required this.onUpdateCollection,
    required this.onDeleteScreenshot,
    this.onScreenshotUpdated,
  });

  @override
  State<ScreenshotSwipeDetailScreen> createState() =>
      _ScreenshotSwipeDetailScreenState();
}

class _ScreenshotSwipeDetailScreenState
    extends State<ScreenshotSwipeDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
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
  }

  void _onScreenshotDeleted(String screenshotId) {
    // Find the index of the deleted screenshot
    final deletedIndex = widget.screenshots.indexWhere(
      (s) => s.id == screenshotId,
    );

    if (deletedIndex != -1) {
      // Remove the screenshot from our local list
      widget.screenshots.removeAt(deletedIndex);

      // Call the parent's delete callback
      widget.onDeleteScreenshot(screenshotId);

      // If this was the last screenshot, go back
      if (widget.screenshots.isEmpty) {
        Navigator.of(context).pop();
        return;
      }

      // Adjust current index if necessary
      if (_currentIndex >= widget.screenshots.length) {
        _currentIndex = widget.screenshots.length - 1;
      }

      // Navigate to the adjusted index
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.screenshots.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('No Screenshots')),
        body: const Center(child: Text('No screenshots available')),
      );
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: widget.screenshots.length,
      itemBuilder: (context, index) {
        return ScreenshotDetailScreen(
          screenshot: widget.screenshots[index],
          allCollections: widget.allCollections,
          allScreenshots: widget.allScreenshots,
          onUpdateCollection: widget.onUpdateCollection,
          onDeleteScreenshot: _onScreenshotDeleted,
          onScreenshotUpdated: widget.onScreenshotUpdated,
          currentIndex: index,
          totalCount: widget.screenshots.length,
        );
      },
    );
  }
}
