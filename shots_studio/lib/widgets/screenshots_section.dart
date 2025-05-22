import 'package:flutter/material.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/widgets/screenshot_card.dart';

class ScreenshotsSection extends StatelessWidget {
  final List<Screenshot> screenshots;
  final Function(Screenshot) onScreenshotTap;

  const ScreenshotsSection({
    super.key,
    required this.screenshots,
    required this.onScreenshotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Screenshots',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: screenshots.length,
          itemBuilder: (context, index) {
            return ScreenshotCard(
              screenshot: screenshots[index],
              onTap: () => onScreenshotTap(screenshots[index]),
            );
          },
        ),
      ],
    );
  }
}
