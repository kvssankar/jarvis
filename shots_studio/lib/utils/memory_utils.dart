import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

class MemoryUtils {
  static void clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
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
    imageCache.maximumSize = 50; // Reduced from default 1000
    imageCache.maximumSizeBytes = 50 << 20; // 50MB instead of 100MB
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
