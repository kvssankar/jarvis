import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/screens/full_screen_image_viewer.dart';
import 'package:shots_studio/widgets/tag_input_field.dart';
import 'package:shots_studio/widgets/tag_chip.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';

class ScreenshotDetailScreen extends StatefulWidget {
  final Screenshot screenshot;
  final List<Collection> allCollections;
  final Function(Collection) onUpdateCollection;

  const ScreenshotDetailScreen({
    super.key,
    required this.screenshot,
    required this.allCollections,
    required this.onUpdateCollection,
  });

  @override
  State<ScreenshotDetailScreen> createState() => _ScreenshotDetailScreenState();
}

class _ScreenshotDetailScreenState extends State<ScreenshotDetailScreen> {
  late List<String> _tags;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.screenshot.tags);
    _descriptionController = TextEditingController(
      text: widget.screenshot.description,
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateScreenshotDetails() {
    // This can be called when description or tags change and need to be persisted
    // For now, tags are updated directly, description on change.
    // If you had a separate save button, it would go here.
    // For simplicity, we're updating the model directly.
    // Potentially, you might want a callback to HomeScreen to update the main _screenshots list
    // if Screenshot objects are not treated as mutable references throughout the app.
  }

  void _addTag(String tag) {
    setState(() {
      if (!_tags.contains(tag)) {
        _tags.add(tag);
        widget.screenshot.tags = _tags;
      }
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      widget.screenshot.tags = _tags;
    });
  }

  Widget _buildTag(String label) {
    final bool isAddButton = label == '+ Add Tag';

    if (isAddButton) {
      return TagInputField(onTagAdded: _addTag);
    }

    return TagChip(label: label, onDelete: () => _removeTag(label));
  }

  void _showAddToCollectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Add to Collection',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child:
                        widget.allCollections.isEmpty
                            ? const Center(
                              child: Text(
                                'No collections available.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                            : ListView.builder(
                              itemCount: widget.allCollections.length,
                              itemBuilder: (context, index) {
                                final collection = widget.allCollections[index];
                                final bool isAlreadyIn = collection
                                    .screenshotIds
                                    .contains(widget.screenshot.id);
                                return ListTile(
                                  title: Text(
                                    collection.name ?? 'Untitled',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  trailing: Icon(
                                    isAlreadyIn
                                        ? Icons.check_circle
                                        : Icons.add_circle_outline,
                                    color:
                                        isAlreadyIn
                                            ? Colors.amber.shade200
                                            : Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                  ),
                                  onTap: () {
                                    _toggleScreenshotInCollection(
                                      collection,
                                      setModalState,
                                    );
                                  },
                                );
                              },
                            ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      child: const Text(
                        'DONE',
                        style: TextStyle(color: Colors.amber),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _toggleScreenshotInCollection(
    Collection collection,
    StateSetter setModalState,
  ) {
    final bool isCurrentlyIn = collection.screenshotIds.contains(
      widget.screenshot.id,
    );
    List<String> updatedScreenshotIds = List.from(collection.screenshotIds);
    List<String> updatedCollectionIdsInScreenshot = List.from(
      widget.screenshot.collectionIds,
    );

    if (isCurrentlyIn) {
      updatedScreenshotIds.remove(widget.screenshot.id);
      updatedCollectionIdsInScreenshot.remove(collection.id);
    } else {
      updatedScreenshotIds.add(widget.screenshot.id);
      updatedCollectionIdsInScreenshot.add(collection.id);
    }

    widget.screenshot.collectionIds = updatedCollectionIdsInScreenshot;

    Collection updatedCollection = collection.copyWith(
      screenshotIds: updatedScreenshotIds,
      screenshotCount: updatedScreenshotIds.length,
      lastModified: DateTime.now(),
    );
    widget.onUpdateCollection(updatedCollection);
    setModalState(() {});
    setState(() {});
  }

  void _clearAndRequestAiReprocessing() {
    setState(() {
      widget.screenshot.aiProcessed = false;
    });
    _updateScreenshotDetails();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI details cleared. Ready for re-processing.'),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    if (i >= suffixes.length) {
      i = suffixes.length - 1;
    }
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    String imageName = widget.screenshot.title ?? 'Screenshot';

    if (widget.screenshot.path != null) {
      imageWidget = Image.file(
        File(widget.screenshot.path!),
        fit: BoxFit.contain,
      );
    } else if (widget.screenshot.bytes != null) {
      imageWidget = Image.memory(widget.screenshot.bytes!, fit: BoxFit.contain);
    } else {
      imageWidget = const Center(child: Icon(Icons.broken_image));
      imageName = 'Invalid Image';
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Screenshot Detail',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => FullScreenImageViewer(
                          screenshot: widget.screenshot,
                        ),
                  ),
                );
              },
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[900],
                ),
                margin: const EdgeInsets.all(16),
                clipBehavior: Clip.antiAlias,
                child: imageWidget,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    imageName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // Format DateTime using intl package
                    DateFormat(
                      'MMM d, yyyy, hh:mm a',
                    ).format(widget.screenshot.addedOn),
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                  if (widget.screenshot.fileSize != null &&
                      widget.screenshot.fileSize! > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Size: ${_formatFileSize(widget.screenshot.fileSize!)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Add a description...',
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white70),
                    maxLines: 3,
                    onChanged: (value) {
                      widget.screenshot.description = value;
                    },
                    onEditingComplete: () {
                      widget.screenshot.description =
                          _descriptionController.text;
                      _updateScreenshotDetails();
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tags',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._tags.map((tag) => _buildTag(tag)),
                      _buildTag('+ Add Tag'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'AI Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI Analysis Status:',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              if (widget.screenshot.aiProcessed &&
                                  widget.screenshot.aiMetadata != null) ...[
                                Text(
                                  'Model: ${widget.screenshot.aiMetadata!.modelName}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                Text(
                                  'Analyzed on: ${DateFormat('MMM d, yyyy HH:mm a').format(widget.screenshot.aiMetadata!.processingTime)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          widget.screenshot.aiProcessed
                              ? Icons.check_circle
                              : Icons.hourglass_empty,
                          color: Colors.amber[200],
                        ),
                        if (widget.screenshot.aiProcessed)
                          IconButton(
                            icon: Icon(
                              Icons.refresh,
                              color: Colors.orangeAccent,
                            ),
                            tooltip: 'Clear AI analysis to re-process',
                            onPressed: _clearAndRequestAiReprocessing,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Collections',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (widget.screenshot.collectionIds.isEmpty)
                        const Text(
                          "This isn’t in any collection yet. Hit the + button to give it a cozy home 😺",
                          style: TextStyle(color: Colors.white70),
                        )
                      else
                        ...widget.screenshot.collectionIds.map((collectionId) {
                          final collection = widget.allCollections.firstWhere(
                            (c) => c.id == collectionId,
                          );

                          return Chip(
                            label: Text(collection.name ?? 'Unnamed'),
                            backgroundColor: Colors.blueGrey[700],
                            labelStyle: const TextStyle(color: Colors.white),
                          );
                        }),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddToCollectionDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.grey[900],
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(
                Icons.share,
                color: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: () async {
                final file = File(widget.screenshot.path!);
                if (await file.exists()) {
                  await SharePlus.instance.share(
                    ShareParams(
                      text: 'Check out this screenshot!',
                      files: [XFile(file.path)],
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Screenshot file not found')),
                  );
                }
              },
            ),

            // IconButton(
            //   icon: Icon(
            //     Icons.alarm,
            //     color: Theme.of(context).colorScheme.secondary,
            //   ),
            //   onPressed: () {
            //     // TODO: Implement reminder action
            //     print('Reminder button pressed');
            //   },
            // ),
            // IconButton(
            //   icon: Icon(
            //     Icons.delete_outline,
            //     color: Theme.of(context).colorScheme.secondary,
            //   ),
            //   onPressed: () {
            //     // TODO: Implement delete action
            //     print('Delete button pressed');
            //   },
            // ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}
