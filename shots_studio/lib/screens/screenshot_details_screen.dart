import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/collection_model.dart'; // Import Collection model
import 'package:shots_studio/widgets/tag_input_field.dart';
import 'package:shots_studio/widgets/tag_chip.dart';

class ScreenshotDetailScreen extends StatefulWidget {
  final Screenshot screenshot;
  final List<Collection> allCollections; // To list collections
  final Function(Collection) onUpdateCollection; // To update collections

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

    if (isCurrentlyIn) {
      updatedScreenshotIds.remove(widget.screenshot.id);
    } else {
      updatedScreenshotIds.add(widget.screenshot.id);
    }

    Collection updatedCollection = collection.copyWith(
      screenshotIds: updatedScreenshotIds,
      screenshotCount: updatedScreenshotIds.length,
      lastModified: DateTime.now(),
    );
    widget.onUpdateCollection(updatedCollection);
    setModalState(() {}); // Update the bottom sheet UI
    setState(() {}); // Update the main page UI (e.g., "Part of X collections")
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    String imageName = widget.screenshot.title ?? 'Screenshot';

    if (widget.screenshot.path != null) {
      imageWidget = Image.file(
        File(widget.screenshot.path!),
        fit: BoxFit.cover,
      );
    } else if (widget.screenshot.bytes != null) {
      imageWidget = Image.memory(widget.screenshot.bytes!, fit: BoxFit.cover);
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
            Container(
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController, // Use the controller
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Processed',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                        const Spacer(),
                        Icon(
                          widget.screenshot.aiProcessed
                              ? Icons.check_circle
                              : Icons.hourglass_empty,
                          color: Colors.amber[200],
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
                    children:
                        widget.allCollections
                            .where(
                              (collection) => collection.screenshotIds.contains(
                                widget.screenshot.id,
                              ),
                            )
                            .map(
                              (collection) => Chip(
                                label: Text(collection.name ?? 'Unnamed'),
                                backgroundColor: Colors.blueGrey[700],
                                labelStyle: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _showAddToCollectionDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Add to / Manage Collections',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
