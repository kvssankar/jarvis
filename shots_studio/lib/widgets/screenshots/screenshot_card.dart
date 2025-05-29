import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:animations/animations.dart';

class ScreenshotCard extends StatelessWidget {
  final Screenshot screenshot;
  final VoidCallback? onTap;
  final Widget Function(BuildContext)? destinationBuilder;

  const ScreenshotCard({
    super.key,
    required this.screenshot,
    this.onTap,
    this.destinationBuilder,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (screenshot.path != null) {
      imageWidget = Image.file(
        File(screenshot.path!),
        fit: BoxFit.cover,
        cacheWidth: 300,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              Icons.broken_image,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        },
      );
    } else if (screenshot.bytes != null) {
      imageWidget = Image.memory(
        screenshot.bytes!,
        fit: BoxFit.cover,
        cacheWidth: 300,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              Icons.broken_image,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        },
      );
    } else {
      imageWidget = const Center(child: Icon(Icons.broken_image));
    }

    Widget cardContent = Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.secondaryContainer,
          width: 3.0,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: imageWidget),
            if (screenshot.aiProcessed)
              Positioned(
                bottom: 4,
                right: 4,
                child: Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );

    return RepaintBoundary(
      child:
          destinationBuilder != null
              ? OpenContainer(
                transitionType: ContainerTransitionType.fade,
                transitionDuration: const Duration(milliseconds: 300),
                closedElevation: 0,
                openElevation: 0,
                closedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                closedColor: Colors.transparent,
                openColor: Theme.of(context).colorScheme.surface,
                closedBuilder: (context, action) => cardContent,
                openBuilder: (context, action) => destinationBuilder!(context),
              )
              : InkWell(onTap: onTap, child: cardContent),
    );
  }
}
