// Image Conversion Utilities
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class ImageConversionUtils {
  /// Converts an image file at the given path to base64 format
  /// Returns a map with 'mime_type' and 'data' keys
  static Future<Map<String, String>> convertImageToBase64(
    String imagePath,
  ) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception("Image file not found: $imagePath");
    }
    final bytes = await file.readAsBytes();
    final encoded = base64Encode(bytes);
    String mimeType = 'image/png';
    if (imagePath.toLowerCase().endsWith('.jpg') ||
        imagePath.toLowerCase().endsWith('.jpeg')) {
      mimeType = 'image/jpeg';
    }
    return {'mime_type': mimeType, 'data': encoded};
  }

  /// Converts bytes to base64 format
  /// Returns a map with 'mime_type' and 'data' keys
  static Map<String, String> bytesToBase64(
    Uint8List bytes, {
    String? fileName,
  }) {
    final encoded = base64Encode(bytes);
    String mimeType = 'image/png';
    if (fileName != null &&
        (fileName.toLowerCase().endsWith('.jpg') ||
            fileName.toLowerCase().endsWith('.jpeg'))) {
      mimeType = 'image/jpeg';
    }
    return {'mime_type': mimeType, 'data': encoded};
  }

  /// Determines the MIME type based on file extension
  static String getMimeTypeFromPath(String path) {
    if (path.toLowerCase().endsWith('.jpg') ||
        path.toLowerCase().endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    return 'image/png';
  }
}
