import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/widgets/screenshots/screenshot_card.dart';
import 'package:shots_studio/services/analytics_service.dart';
import 'package:shots_studio/utils/responsive_utils.dart';

class ScreenshotsSection extends StatefulWidget {
  final List<Screenshot> screenshots;
  final Function(Screenshot) onScreenshotTap;
  final Widget Function(BuildContext, Screenshot)? screenshotDetailBuilder;
  final Function(List<String>)? onBulkDelete;
  final VoidCallback? onScreenshotUpdated;

  const ScreenshotsSection({
    super.key,
    required this.screenshots,
    required this.onScreenshotTap,
    this.screenshotDetailBuilder,
    this.onBulkDelete,
    this.onScreenshotUpdated,
  });

  @override
  State<ScreenshotsSection> createState() => _ScreenshotsSectionState();
}

class _ScreenshotsSectionState extends State<ScreenshotsSection> {
  static const int _itemsPerPage = 60; // Load 60 items at a time (20 rows of 3)
  int _currentPageIndex = 0;
  bool _isLoadingMore = false;
  late ScrollController _scrollController;

  // Selection mode state
  bool _isSelectionMode = false;
  final Set<String> _selectedScreenshotIds = <String>{};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    if (_isLoadingMore) return;

    final int totalItems = widget.screenshots.length;
    final int currentlyShowing = (_currentPageIndex + 1) * _itemsPerPage;

    if (currentlyShowing >= totalItems) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate a small delay to prevent rapid loading
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _currentPageIndex++;
          _isLoadingMore = false;
        });
      }
    });
  }

  List<Screenshot> get _visibleScreenshots {
    final int endIndex = (_currentPageIndex + 1) * _itemsPerPage;
    return widget.screenshots.take(endIndex).toList();
  }

  void _enterSelectionMode(String screenshotId) {
    HapticFeedback.mediumImpact();

    setState(() {
      _isSelectionMode = true;
      _selectedScreenshotIds.add(screenshotId);
    });
    AnalyticsService().logFeatureUsed('screenshot_selection_mode_entered');
  }

  void _exitSelectionMode() {
    // Provide light haptic feedback when exiting selection mode
    HapticFeedback.lightImpact();

    setState(() {
      _isSelectionMode = false;
      _selectedScreenshotIds.clear();
    });
    AnalyticsService().logFeatureUsed('screenshot_selection_mode_exited');
  }

  void _toggleScreenshotSelection(String screenshotId) {
    HapticFeedback.lightImpact();

    setState(() {
      if (_selectedScreenshotIds.contains(screenshotId)) {
        _selectedScreenshotIds.remove(screenshotId);
        AnalyticsService().logFeatureUsed('screenshot_deselected');

        // Exit selection mode if no screenshots are selected
        if (_selectedScreenshotIds.isEmpty) {
          _isSelectionMode = false;
          AnalyticsService().logFeatureUsed(
            'screenshot_selection_mode_auto_exited',
          );
        }
      } else {
        _selectedScreenshotIds.add(screenshotId);
        AnalyticsService().logFeatureUsed('screenshot_selected');
      }
    });
  }

  void _bulkDeleteSelected() async {
    if (_selectedScreenshotIds.isEmpty) return;

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete ${_selectedScreenshotIds.length} Screenshot${_selectedScreenshotIds.length > 1 ? 's' : ''}?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          content: Text(
            'This action cannot be undone. Are you sure you want to delete the selected screenshot${_selectedScreenshotIds.length > 1 ? 's' : ''}?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onTertiaryContainer,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // Provide haptic feedback for successful bulk delete
      HapticFeedback.heavyImpact();

      // Log bulk delete analytics
      AnalyticsService().logFeatureUsed('screenshot_bulk_delete_confirmed');

      // Perform bulk delete
      final selectedIds = List<String>.from(_selectedScreenshotIds);
      widget.onBulkDelete?.call(selectedIds);

      // Exit selection mode
      _exitSelectionMode();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${selectedIds.length} screenshot${selectedIds.length > 1 ? 's' : ''} deleted successfully',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } else {
      AnalyticsService().logFeatureUsed('screenshot_bulk_delete_cancelled');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with selection controls
        Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              _isSelectionMode
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _exitSelectionMode,
                            tooltip: 'Cancel selection',
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedScreenshotIds.length} selected',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (_selectedScreenshotIds.length ==
                              _visibleScreenshots.length)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedScreenshotIds.clear();
                                });
                                AnalyticsService().logFeatureUsed(
                                  'screenshot_deselect_all',
                                );
                              },
                              child: const Text('Deselect All'),
                            )
                          else
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedScreenshotIds.addAll(
                                    _visibleScreenshots.map((s) => s.id),
                                  );
                                });
                                AnalyticsService().logFeatureUsed(
                                  'screenshot_select_all',
                                );
                              },
                              child: const Text('Select All'),
                            ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed:
                                _selectedScreenshotIds.isNotEmpty
                                    ? _bulkDeleteSelected
                                    : null,
                            tooltip: 'Delete selected',
                          ),
                        ],
                      ),
                    ],
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Screenshots',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total : ${widget.screenshots.length}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
        ),
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            gridDelegate: ResponsiveUtils.getResponsiveGridDelegate(context),
            itemCount: _visibleScreenshots.length + (_isLoadingMore ? 3 : 0),
            itemBuilder: (context, index) {
              if (index >= _visibleScreenshots.length) {
                return Card(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                );
              }

              final screenshot = _visibleScreenshots[index];
              final isSelected = _selectedScreenshotIds.contains(screenshot.id);

              return ScreenshotCard(
                screenshot: screenshot,
                isSelectionMode: _isSelectionMode,
                isSelected: isSelected,
                onLongPress: () => _enterSelectionMode(screenshot.id),
                onSelectionToggle:
                    () => _toggleScreenshotSelection(screenshot.id),
                onCorruptionDetected: widget.onScreenshotUpdated,
                destinationBuilder:
                    widget.screenshotDetailBuilder != null && !_isSelectionMode
                        ? (context) =>
                            widget.screenshotDetailBuilder!(context, screenshot)
                        : null,
                onTap:
                    _isSelectionMode
                        ? () => _toggleScreenshotSelection(screenshot.id)
                        : (widget.screenshotDetailBuilder == null
                            ? () => widget.onScreenshotTap(screenshot)
                            : null),
              );
            },
          ),
        ),
        // if (widget.screenshots.length > _visibleScreenshots.length)
        //   Padding(
        //     padding: const EdgeInsets.all(16.0),
        //     child: Center(
        //       child: TextButton.icon(
        //         onPressed: _isLoadingMore ? null : _loadMoreItems,
        //         icon:
        //             _isLoadingMore
        //                 ? const SizedBox(
        //                   width: 16,
        //                   height: 16,
        //                   child: CircularProgressIndicator(strokeWidth: 2),
        //                 )
        //                 : const Icon(Icons.expand_more),
        //         label: Text(_isLoadingMore ? 'Loading...' : 'Load More'),
        //       ),
        //     ),
        //   ),
      ],
    );
  }
}
