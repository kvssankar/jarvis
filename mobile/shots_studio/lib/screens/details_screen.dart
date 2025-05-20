import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/widgets/tag_input_field.dart';
import 'package:shots_studio/widgets/tag_chip.dart';

class ScreenshotDetailScreen extends StatefulWidget {
  final Screenshot screenshot;

  const ScreenshotDetailScreen({super.key, required this.screenshot});

  @override
  State<ScreenshotDetailScreen> createState() => _ScreenshotDetailScreenState();
}

class _ScreenshotDetailScreenState extends State<ScreenshotDetailScreen> {
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.screenshot.tags);
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: TextEditingController(
                      text: widget.screenshot.description,
                    ),
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
