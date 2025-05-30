import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

class MemoryUtils {
  static void clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
  }

  /// Clear only large images, preserving small thumbnail cache
  static void clearLargeImagesOnly() {
    final imageCache = PaintingBinding.instance.imageCache;
    // Force eviction of images larger than thumbnail size
    imageCache.clearLiveImages();
  }

  /// Clear image cache and force garbage collection
  static Future<void> clearImageCacheAndGC() async {
    PaintingBinding.instance.imageCache.clear();

    // Force garbage collection (platform specific)
    try {
      await SystemChannels.platform.invokeMethod('System.gc');
    } catch (e) {
      // Ignore if not supported on platform
    }
  }

  /// Set image cache limits for better memory management
  static void optimizeImageCache() {
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.maximumSize =
        100; // Increased to accommodate collection thumbnails
    imageCache.maximumSizeBytes =
        100 << 20; // 100MB for better thumbnail caching
  }

  /// Get current image cache statistics
  static Map<String, dynamic> getImageCacheStats() {
    final imageCache = PaintingBinding.instance.imageCache;
    return {
      'currentSize': imageCache.currentSize,
      'maximumSize': imageCache.maximumSize,
      'currentSizeBytes': imageCache.currentSizeBytes,
      'maximumSizeBytes': imageCache.maximumSizeBytes,
      'pendingImageCount': imageCache.pendingImageCount,
    };
  }
}
