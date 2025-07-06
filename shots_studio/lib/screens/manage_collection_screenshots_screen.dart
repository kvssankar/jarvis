import 'package:flutter/material.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/widgets/screenshots/screenshot_card.dart';
import 'package:shots_studio/utils/responsive_utils.dart';
import 'package:shots_studio/services/analytics_service.dart';

class ManageCollectionScreenshotsScreen extends StatefulWidget {
  final List<Screenshot> availableScreenshots;
  final Set<String> initialSelectedIds;

  const ManageCollectionScreenshotsScreen({
    super.key,
    required this.availableScreenshots,
    required this.initialSelectedIds,
  });

  @override
  State<ManageCollectionScreenshotsScreen> createState() =>
      _ManageCollectionScreenshotsScreenState();
}

class _ManageCollectionScreenshotsScreenState
    extends State<ManageCollectionScreenshotsScreen> {
  late Set<String> _selectedScreenshotIds;

  @override
  void initState() {
    super.initState();
    _selectedScreenshotIds = Set.from(widget.initialSelectedIds);

    // Track screen access
    AnalyticsService().logScreenView('manage_collection_screenshots_screen');
  }

  void _toggleScreenshotSelection(String screenshotId) {
    setState(() {
      if (_selectedScreenshotIds.contains(screenshotId)) {
        _selectedScreenshotIds.remove(screenshotId);
        // Track deselection
        AnalyticsService().logFeatureUsed(
          'screenshot_deselected_from_collection',
        );
      } else {
        _selectedScreenshotIds.add(screenshotId);
        // Track selection
        AnalyticsService().logFeatureUsed('screenshot_selected_for_collection');
      }
    });
  }

  void _save() {
    // Track save action
    AnalyticsService().logFeatureUsed('collection_screenshots_saved');
    AnalyticsService().logFeatureUsed(
      'collection_screenshots_count_${_selectedScreenshotIds.length}',
    );

    Navigator.of(context).pop(_selectedScreenshotIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Manage Screenshots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select screenshots to include in this collection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  widget.availableScreenshots.isEmpty
                      ? Center(
                        child: Text(
                          'No screenshots available',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                      : GridView.builder(
                        gridDelegate: ResponsiveUtils.getResponsiveGridDelegate(
                          context,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: widget.availableScreenshots.length,
                        cacheExtent: 1200,
                        itemBuilder: (context, index) {
                          final screenshot = widget.availableScreenshots[index];
                          final isSelected = _selectedScreenshotIds.contains(
                            screenshot.id,
                          );

                          return GestureDetector(
                            onTap:
                                () => _toggleScreenshotSelection(screenshot.id),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ScreenshotCard(
                                  screenshot: screenshot,
                                  onTap:
                                      () => _toggleScreenshotSelection(
                                        screenshot.id,
                                      ),
                                ),
                                if (isSelected)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surface
                                          .withValues(alpha: 0.7),
                                      border: Border.all(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.check_circle,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
