import 'package:flutter/material.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/widgets/screenshot_card.dart';
import 'package:uuid/uuid.dart';

class CreateCollectionScreen extends StatefulWidget {
  final List<Screenshot> availableScreenshots;

  const CreateCollectionScreen({super.key, required this.availableScreenshots});

  @override
  State<CreateCollectionScreen> createState() => _CreateCollectionScreenState();
}

class _CreateCollectionScreenState extends State<CreateCollectionScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final Set<String> _selectedScreenshotIds = {};
  final Uuid _uuid = const Uuid();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleScreenshotSelection(String screenshotId) {
    setState(() {
      if (_selectedScreenshotIds.contains(screenshotId)) {
        _selectedScreenshotIds.remove(screenshotId);
      } else {
        _selectedScreenshotIds.add(screenshotId);
      }
    });
  }

  void _saveCollection() {
    if (_titleController.text.trim().isEmpty) {
      // Show error or use a default name
      _titleController.text =
          'Collection ${DateTime.now().toString().substring(0, 10)}';
    }

    final Collection newCollection = Collection(
      id: _uuid.v4(),
      name: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      screenshotIds: _selectedScreenshotIds.toList(),
      lastModified: DateTime.now(),
      screenshotCount: _selectedScreenshotIds.length,
    );

    Navigator.of(context).pop(newCollection);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Create Collection'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveCollection),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            TextField(
              controller: _titleController,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              decoration: const InputDecoration(
                hintText: 'Collection Title',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),

            // Description field
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white70),
              decoration: InputDecoration(
                hintText: 'Add a description...',
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),
            const Text(
              'Select Screenshots',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Screenshots grid
            Expanded(
              child:
                  widget.availableScreenshots.isEmpty
                      ? const Center(
                        child: Text(
                          'No screenshots available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                      : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: widget.availableScreenshots.length,
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
                                // Screenshot card
                                ScreenshotCard(
                                  screenshot: screenshot,
                                  onTap:
                                      () => _toggleScreenshotSelection(
                                        screenshot.id,
                                      ),
                                ),

                                // Selection overlay
                                if (isSelected)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
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
