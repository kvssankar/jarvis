import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Responsive grid settings
  static const double minItemWidth = 100.0; // Default tile width
  static const double maxItemWidth =
      150.0; // Max tile width when there's extra space
  static const double defaultCrossAxisSpacing = 8.0;
  static const double defaultHorizontalPadding = 32.0; // 16 * 2

  /// Calculate responsive cross axis count based on screen width
  static int getResponsiveCrossAxisCount(
    double screenWidth, {
    double? crossAxisSpacing,
    double? horizontalPadding,
  }) {
    final double actualCrossAxisSpacing =
        crossAxisSpacing ?? defaultCrossAxisSpacing;
    final double actualHorizontalPadding =
        horizontalPadding ?? defaultHorizontalPadding;

    final availableWidth = screenWidth - actualHorizontalPadding;

    int crossAxisCount =
        ((availableWidth + actualCrossAxisSpacing) /
                (minItemWidth + actualCrossAxisSpacing))
            .floor();

    return crossAxisCount < 2 ? 2 : crossAxisCount;
  }

  /// Get responsive grid delegate that uses flexible sizing between 100-150px
  static SliverGridDelegateWithMaxCrossAxisExtent getResponsiveGridDelegate(
    BuildContext context, {
    double? crossAxisSpacing,
    double? mainAxisSpacing,
    double? childAspectRatio,
    double? horizontalPadding,
  }) {
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxItemWidth,
      childAspectRatio: childAspectRatio ?? 1,
      crossAxisSpacing: crossAxisSpacing ?? defaultCrossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing ?? 4,
    );
  }
}
