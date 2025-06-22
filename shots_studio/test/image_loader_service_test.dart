import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shots_studio/services/image_loader_service.dart';

void main() {
  group('ImageLoaderService', () {
    late ImageLoaderService imageLoaderService;

    setUp(() {
      imageLoaderService = ImageLoaderService();
    });

    test('should validate supported image file formats', () {
      expect(imageLoaderService.isValidImageFile('test.png'), isTrue);
      expect(imageLoaderService.isValidImageFile('test.jpg'), isTrue);
      expect(imageLoaderService.isValidImageFile('test.jpeg'), isTrue);
      expect(imageLoaderService.isValidImageFile('TEST.PNG'), isTrue);
      expect(imageLoaderService.isValidImageFile('test.gif'), isFalse);
      expect(imageLoaderService.isValidImageFile('test.txt'), isFalse);
    });

    test('should format file sizes correctly', () {
      expect(imageLoaderService.getFileSizeString(512), equals('512 B'));
      expect(imageLoaderService.getFileSizeString(1024), equals('1.0 KB'));
      expect(imageLoaderService.getFileSizeString(1536), equals('1.5 KB'));
      expect(imageLoaderService.getFileSizeString(1048576), equals('1.0 MB'));
      expect(imageLoaderService.getFileSizeString(1572864), equals('1.5 MB'));
    });

    test('should create screenshot from bytes', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final fileName = 'test.png';
      final path = '/test/path/test.png';

      final screenshot = imageLoaderService.createScreenshotFromBytes(
        bytes: bytes,
        fileName: fileName,
        path: path,
      );

      expect(screenshot.bytes, equals(bytes));
      expect(screenshot.title, equals(fileName));
      expect(screenshot.path, equals(path));
      expect(screenshot.fileSize, equals(bytes.length));
      expect(screenshot.aiProcessed, isFalse);
      expect(screenshot.tags, isEmpty);
      expect(screenshot.id, isNotEmpty);
    });

    test('should create screenshot from bytes without path', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final fileName = 'test.png';

      final screenshot = imageLoaderService.createScreenshotFromBytes(
        bytes: bytes,
        fileName: fileName,
      );

      expect(screenshot.bytes, equals(bytes));
      expect(screenshot.title, equals(fileName));
      expect(screenshot.path, isNull);
      expect(screenshot.fileSize, equals(bytes.length));
    });
  });
}
