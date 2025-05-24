import 'package:flutter/material.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/widgets/screenshot_card.dart';
import 'package:uuid/uuid.dart';

class CreateCollectionScreen extends StatefulWidget {
  final List<Screenshot> availableScreenshots;
  final Set<String>? initialSelectedIds;
  final bool isEditMode;

  const CreateCollectionScreen({
    super.key,
    required this.availableScreenshots,
    this.initialSelectedIds,
    this.isEditMode = false,
  });

  @override
  State<CreateCollectionScreen> createState() => _CreateCollectionScreenState();
}

class _CreateCollectionScreenState extends State<CreateCollectionScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late Set<String> _selectedScreenshotIds;
  final Uuid _uuid = const Uuid();
  bool _isAutoAddEnabled = false; // Added state for Auto-Add

  @override
  void initState() {
    super.initState();
    _selectedScreenshotIds =
        widget.initialSelectedIds != null
            ? Set.from(widget.initialSelectedIds!)
            : {};
    // Add listener to update button state based on title content
    _titleController.addListener(() {
      if (!widget.isEditMode) {
        setState(() {}); // Rebuild to enable/disable save button
      }
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(() {
      if (!widget.isEditMode) {
        setState(() {});
      }
    });
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

  void _save() {
    if (widget.isEditMode) {
      Navigator.of(context).pop(_selectedScreenshotIds.toList());
    } else {
      final String title = _titleController.text.trim();
      // Title empty check is now handled by button state, but good to keep for safety if called directly
      if (title.isEmpty) {
        // This part should ideally not be reached if button is properly disabled
        print(
          "Save called with empty title, button should have been disabled.",
        );
        return;
      }

      // Removed restriction for empty screenshots

      final Collection newCollection = Collection(
        id: _uuid.v4(),
        name: title,
        description: _descriptionController.text.trim(),
        screenshotIds: _selectedScreenshotIds.toList(),
        lastModified: DateTime.now(),
        screenshotCount: _selectedScreenshotIds.length,
        isAutoAddEnabled: _isAutoAddEnabled, // Pass the state here
      );
      Navigator.of(context).pop(newCollection);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if save button should be enabled
    final bool isSaveButtonEnabled =
        widget.isEditMode || _titleController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.isEditMode ? 'Manage Screenshots' : 'Create Collection',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            // Disable button if not in edit mode and title is empty
            onPressed: isSaveButtonEnabled ? _save : null,
            color:
                isSaveButtonEnabled
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Conditionally show Title and Description fields only if not in edit mode
            if (!widget.isEditMode) ...[
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Tooltip(
                    message:
                        'When enabled, AI will automatically add relevant screenshots to this collection',
                    child: Row(
                      children: [
                        const Text(
                          'Enable Auto-Add Screenshots (AI)',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.amber.shade200,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAutoAddEnabled,
                    activeColor: Colors.amber.shade200,
                    onChanged: (bool value) {
                      setState(() {
                        _isAutoAddEnabled = value;
                      });
                    },
                  ),
                ],
              ),
              if (_isAutoAddEnabled) // Conditional message based on switch state
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Colors.amber.shade200,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Gemini AI will automatically categorize new screenshots into this collection based on content analysis.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade100,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8), // Adjusted spacing
            ],
            Text(
              widget.isEditMode
                  ? 'Select screenshots to include'
                  : 'Select Screenshots',
              style: const TextStyle(
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
