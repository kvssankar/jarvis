import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:animations/animations.dart';

class ScreenshotCard extends StatelessWidget {
  final Screenshot screenshot;
  final VoidCallback? onTap;
  final Widget Function(BuildContext)? destinationBuilder;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectionToggle;
  final VoidCallback? onCorruptionDetected;

  const ScreenshotCard({
    super.key,
    required this.screenshot,
    this.onTap,
    this.destinationBuilder,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onSelectionToggle,
    this.onCorruptionDetected,
  });

  void _handleCorruption() {
    // Mark as AI processed if not already and notify parent
    if (!screenshot.aiProcessed) {
      screenshot.aiProcessed = true;
      // Defer the callback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onCorruptionDetected?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const double borderRadius = 12.0;

    Widget imageWidget;
    if (screenshot.path != null) {
      final file = File(screenshot.path!);
      if (file.existsSync()) {
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(
            borderRadius - 3.0,
          ), // Adjust for border width
          child: Image.file(
            file,
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
              _handleCorruption();
              return Container(
                color: Theme.of(context).colorScheme.surface,
                child: Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 24,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        );
      } else {
        _handleCorruption();
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - 3.0),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported_outlined,
                    size: 24,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'File not found',
                    style: TextStyle(
                      fontSize: 8,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } else if (screenshot.bytes != null) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(
          borderRadius - 3.0,
        ), // Adjust for border width
        child: Image.memory(
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
            _handleCorruption();
            return Container(
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 24,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          },
        ),
      );
    } else {
      _handleCorruption();
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 3.0),
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 24,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    Widget cardContent = Container(
      decoration: BoxDecoration(
        border: Border.all(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondaryContainer,
          width: isSelected ? 4.0 : 3.0,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Stack(
        children: [
          // Using a plain container instead of Card to avoid double clipping
          Container(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                borderRadius - (isSelected ? 4.0 : 3.0),
              ),
              color: Theme.of(context).cardColor,
            ),
            child: SizedBox.expand(child: imageWidget),
          ),

          // Selection overlay
          if (isSelectionMode)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  borderRadius - (isSelected ? 4.0 : 3.0),
                ),
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
              ),
            ),

          // Selection indicator
          if (isSelectionMode)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.8),
                  border: Border.all(
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                    width: 2,
                  ),
                ),
                child:
                    isSelected
                        ? Icon(
                          Icons.check,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimary,
                        )
                        : null,
              ),
            ),

          // AI processed indicator (only show when not in selection mode)
          if (screenshot.aiProcessed && !isSelectionMode)
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
    );

    // If a destination builder is provided and not in selection mode, use OpenContainer for transitions
    return RepaintBoundary(
      child:
          destinationBuilder != null && !isSelectionMode
              ? OpenContainer(
                transitionType: ContainerTransitionType.fade,
                transitionDuration: const Duration(milliseconds: 250),
                closedElevation: 0,
                openElevation: 0,
                closedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                closedColor: Colors.transparent,
                openColor: Theme.of(context).colorScheme.surface,
                closedBuilder:
                    (context, action) => _buildGestureDetector(cardContent),
                openBuilder: (context, action) => destinationBuilder!(context),
              )
              : _buildGestureDetector(cardContent),
    );
  }

  Widget _buildGestureDetector(Widget child) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: isSelectionMode ? null : onLongPress,
      child: child,
    );
  }
}
