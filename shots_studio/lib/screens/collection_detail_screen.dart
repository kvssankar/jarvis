import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/ai_service_manager.dart';
import 'package:shots_studio/services/ai_service.dart';
import 'package:shots_studio/widgets/screenshots/screenshot_card.dart';
import 'package:shots_studio/screens/manage_collection_screenshots_screen.dart';
import 'package:shots_studio/screens/screenshot_swipe_detail_screen.dart';
import 'package:shots_studio/screens/create_collection_screen.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CollectionDetailScreen extends StatefulWidget {
  final Collection collection;
  final List<Screenshot> allScreenshots;
  final Function(Collection) onUpdateCollection;
  final Function(String) onDeleteCollection;
  final Function(String) onDeleteScreenshot;

  const CollectionDetailScreen({
    super.key,
    required this.collection,
    required this.allScreenshots,
    required this.onUpdateCollection,
    required this.onDeleteCollection,
    required this.onDeleteScreenshot,
  });

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late List<String> _currentScreenshotIds;
  late bool _isAutoAddEnabled;

  // Auto-categorization state
  bool _isAutoCategorizing = false;
  int _autoCategorizeProcessedCount = 0;
  int _autoCategorizeTotalCount = 0;
  final AIServiceManager _aiServiceManager = AIServiceManager();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collection.name);
    _descriptionController = TextEditingController(
      text: widget.collection.description,
    );
    _currentScreenshotIds = List.from(widget.collection.screenshotIds);
    _isAutoAddEnabled = widget.collection.isAutoAddEnabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final updatedCollection = widget.collection.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      screenshotIds: List<String>.from(
        _currentScreenshotIds,
      ), // Create new list
      lastModified: DateTime.now(),
      screenshotCount: _currentScreenshotIds.length,
      isAutoAddEnabled: _isAutoAddEnabled,
    );
    widget.onUpdateCollection(updatedCollection);
  }

  Future<void> _editCollection() async {
    final currentCollection = widget.collection.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      screenshotIds: List<String>.from(
        _currentScreenshotIds,
      ), // Create new list
      isAutoAddEnabled: _isAutoAddEnabled,
    );

    final Collection? updatedCollection = await Navigator.of(
      context,
    ).push<Collection>(
      MaterialPageRoute(
        builder:
            (context) => CreateCollectionScreen(
              availableScreenshots: widget.allScreenshots,
              initialSelectedIds: Set.from(_currentScreenshotIds),
              existingCollection: currentCollection,
            ),
      ),
    );

    if (updatedCollection != null) {
      setState(() {
        _nameController.text = updatedCollection.name ?? '';
        _descriptionController.text = updatedCollection.description ?? '';
        _currentScreenshotIds = List.from(updatedCollection.screenshotIds);
        _isAutoAddEnabled = updatedCollection.isAutoAddEnabled;
      });

      widget.onUpdateCollection(updatedCollection);
    }
  }

  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Delete Collection?'),
          content: const Text(
            'Are you sure you want to delete this collection?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      widget.onDeleteCollection(widget.collection.id);
      Navigator.of(context).pop();
    }
  }

  Future<void> _addOrManageScreenshots() async {
    final Set<String> previousScreenshotIds = Set.from(_currentScreenshotIds);

    final List<String>? newScreenshotIdsList = await Navigator.of(
      context,
    ).push<List<String>>(
      MaterialPageRoute(
        builder:
            (context) => ManageCollectionScreenshotsScreen(
              availableScreenshots: widget.allScreenshots,
              initialSelectedIds: Set.from(_currentScreenshotIds),
            ),
      ),
    );

    if (newScreenshotIdsList != null) {
      final Set<String> newScreenshotIdsSet = Set.from(newScreenshotIdsList);

      // Update Screenshot models' collectionIds
      for (var screenshot in widget.allScreenshots) {
        final bool wasInCollection = previousScreenshotIds.contains(
          screenshot.id,
        );
        final bool isInCollection = newScreenshotIdsSet.contains(screenshot.id);

        if (isInCollection && !wasInCollection) {
          // Screenshot was added to this collection
          if (!screenshot.collectionIds.contains(widget.collection.id)) {
            screenshot.collectionIds.add(widget.collection.id);
          }
        } else if (!isInCollection && wasInCollection) {
          // Screenshot was removed from this collection
          screenshot.collectionIds.remove(widget.collection.id);
        }
      }

      setState(() {
        _currentScreenshotIds = newScreenshotIdsList;
        _saveChanges();
      });
    }
  }

  void _removeScreenshotFromCollection(String screenshotIdToRemove) {
    final screenshot = widget.allScreenshots.firstWhere(
      (s) => s.id == screenshotIdToRemove,
    );
    screenshot.collectionIds.remove(widget.collection.id);
    // }

    setState(() {
      _currentScreenshotIds.remove(screenshotIdToRemove);
      _saveChanges();
    });
  }

  Future<void> _startAutoCategorization() async {
    // Prevent multiple auto-categorization attempts
    if (_isAutoCategorizing) return;

    final prefs = await SharedPreferences.getInstance();
    final String? apiKey = prefs.getString('apiKey');
    if (apiKey == null || apiKey.isEmpty) {
      SnackbarService().showError(
        context,
        'API key not set. Please configure it in settings.',
      );
      return;
    }

    final String modelName =
        prefs.getString('selected_model') ?? 'gemini-2.0-flash';
    final int maxParallel = prefs.getInt('max_parallel_ai') ?? 4;

    final List<Screenshot> candidateScreenshots =
        widget.allScreenshots
            .where((s) => !_currentScreenshotIds.contains(s.id) && !s.isDeleted)
            .toList();

    if (candidateScreenshots.isEmpty) {
      SnackbarService().showInfo(
        context,
        'No screenshots available for categorization.',
      );
      return;
    }

    setState(() {
      _isAutoCategorizing = true;
      _autoCategorizeProcessedCount = 0;
      _autoCategorizeTotalCount = candidateScreenshots.length;
    });

    final config = AIConfig(
      apiKey: apiKey,
      modelName: modelName,
      maxParallel: maxParallel,
      showMessage: ({
        required String message,
        Color? backgroundColor,
        Duration? duration,
      }) {
        SnackbarService().showInfo(context, message);
      },
    );

    try {
      // Initialize the AI service manager
      _aiServiceManager.initialize(config);

      final result = await _aiServiceManager.categorizeScreenshots(
        collection: widget.collection,
        screenshots: candidateScreenshots,
        onBatchProcessed: (batch, response) {
          setState(() {
            _autoCategorizeProcessedCount += batch.length;
          });

          // Process batch results immediately if successful
          if (!response.containsKey('error') && response.containsKey('data')) {
            try {
              final String responseText = response['data'];
              final RegExp jsonRegExp = RegExp(r'\{.*\}', dotAll: true);
              final match = jsonRegExp.firstMatch(responseText);

              if (match != null) {
                final parsedResponse = jsonDecode(match.group(0)!);
                if (parsedResponse['matching_screenshots'] is List) {
                  final List<String> batchMatchingIds = List<String>.from(
                    parsedResponse['matching_screenshots'],
                  );

                  if (batchMatchingIds.isNotEmpty) {
                    setState(() {
                      // Add matching screenshots from this batch immediately
                      // Create a new list to ensure proper change detection
                      _currentScreenshotIds = [
                        ..._currentScreenshotIds,
                        ...batchMatchingIds,
                      ];
                    });

                    // Update screenshot models immediately
                    for (String screenshotId in batchMatchingIds) {
                      final screenshot = widget.allScreenshots.firstWhere(
                        (s) => s.id == screenshotId,
                      );
                      if (!screenshot.collectionIds.contains(
                        widget.collection.id,
                      )) {
                        screenshot.collectionIds.add(widget.collection.id);
                      }
                    }

                    // Save changes immediately
                    _saveChanges();

                    // // Show immediate feedback
                    // SnackbarService().showInfo(
                    //   context,
                    //   'Added ${batchMatchingIds.length} screenshots from batch',
                    // );
                  }
                }
              }
            } catch (e) {
              // Silently handle parsing errors for individual batches
              print('Error parsing batch response: $e');
            }
          }
        },
      );

      if (result.cancelled) {
        SnackbarService().showInfo(context, 'Auto-categorization cancelled.');
        return;
      }

      if (result.success) {
        final List<String> totalMatchingScreenshotIds = result.data ?? [];

        // Show final summary (batches have already been processed)
        if (totalMatchingScreenshotIds.isNotEmpty) {
          SnackbarService().showInfo(
            context,
            'Auto-categorization completed. Total: ${totalMatchingScreenshotIds.length} screenshots added.',
          );
        } else {
          SnackbarService().showInfo(
            context,
            'Auto-categorization completed. No matching screenshots found.',
          );
        }
      } else {
        SnackbarService().showError(
          context,
          result.error ?? 'Auto-categorization failed',
        );
      }
    } catch (e) {
      SnackbarService().showError(
        context,
        'Error during auto-categorization: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isAutoCategorizing = false;
        _autoCategorizeProcessedCount = 0;
        _autoCategorizeTotalCount = 0;
      });
    }
  }

  void _stopAutoCategorization() {
    _aiServiceManager.cancelAllOperations();
    setState(() {
      _isAutoCategorizing = false;
      _autoCategorizeProcessedCount = 0;
      _autoCategorizeTotalCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenshotsInCollection =
        widget.allScreenshots
            .where((s) => _currentScreenshotIds.contains(s.id))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _nameController.text.isEmpty
              ? 'Collection Details'
              : _nameController.text,
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          if (_isAutoCategorizing)
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value:
                        _autoCategorizeTotalCount > 0
                            ? _autoCategorizeProcessedCount /
                                _autoCategorizeTotalCount
                            : null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.stop, size: 16),
                  onPressed: _stopAutoCategorization,
                  tooltip: 'Stop Auto-categorization',
                ),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              onPressed: _startAutoCategorization,
              tooltip: 'Auto-categorize Screenshots',
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editCollection,
            tooltip: 'Edit Collection',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _nameController.text.isEmpty
                  ? 'Collection Name'
                  : _nameController.text,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              decoration: InputDecoration(
                hintText: 'Collection description',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                filled: true,
                fillColor: Theme.of(context).colorScheme.secondaryContainer,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1,
                  ),
                ),
              ),
              maxLines: 3,
              readOnly: true,
              enableInteractiveSelection: true,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Tooltip(
                    message:
                        'When enabled, AI will automatically add relevant screenshots to this collection',
                    child: Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Enable Auto-Add Screenshots (AI)',
                            style: TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                Switch(
                  value: _isAutoAddEnabled,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (bool value) {
                    setState(() {
                      _isAutoAddEnabled = value;
                      _saveChanges();
                    });
                  },
                ),
              ],
            ),
            if (_isAutoAddEnabled)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.tertiary.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gemini AI will automatically categorize new screenshots into this collection based on content analysis',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Screenshots in Collection',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: _addOrManageScreenshots,
                  tooltip: 'Add/Manage Screenshots',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  screenshotsInCollection.isEmpty
                      ? Center(
                        child: Text(
                          'No screenshots in this collection. Tap + to add.',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                      : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: screenshotsInCollection.length,
                        cacheExtent: 800,
                        itemBuilder: (context, index) {
                          final screenshot = screenshotsInCollection[index];
                          return Stack(
                            children: [
                              ScreenshotCard(
                                screenshot: screenshot,
                                destinationBuilder: (context) {
                                  final int initialIndex =
                                      screenshotsInCollection.indexWhere(
                                        (s) => s.id == screenshot.id,
                                      );
                                  return ScreenshotSwipeDetailScreen(
                                    screenshots: List.from(
                                      screenshotsInCollection,
                                    ),
                                    initialIndex:
                                        initialIndex >= 0 ? initialIndex : 0,
                                    allCollections: [widget.collection],
                                    onUpdateCollection:
                                        widget.onUpdateCollection,
                                    onDeleteScreenshot:
                                        widget.onDeleteScreenshot,
                                    onScreenshotUpdated: () {
                                      setState(() {});
                                    },
                                  );
                                },
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.remove_circle,
                                    color: theme.colorScheme.error,
                                  ),
                                  onPressed:
                                      () => _removeScreenshotFromCollection(
                                        screenshot.id,
                                      ),
                                  tooltip: 'Remove from collection',
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
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
