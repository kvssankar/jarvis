import 'package:flutter_test/flutter_test.dart';
import 'package:shots_studio/services/ocr_service.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';

void main() {
  group('OCR Service Tests', () {
    late OCRService ocrService;

    setUpAll(() {
      // Initialize Flutter binding for tests
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      ocrService = OCRService();
    });

    test('should be singleton', () {
      final instance1 = OCRService();
      final instance2 = OCRService();
      expect(instance1, same(instance2));
    });

    test('should check OCR availability', () {
      final isAvailable = ocrService.isOCRAvailable();
      expect(isAvailable, isA<bool>());
    });

    test('should return supported languages', () {
      final languages = ocrService.getSupportedLanguages();
      expect(languages, isNotEmpty);
      expect(languages, contains('eng'));
    });

    test('should handle screenshot with no image data', () async {
      final screenshot = Screenshot(
        id: 'test-id',
        addedOn: DateTime.now(),
        tags: [],
        collectionIds: [],
        aiProcessed: false,
        path: null,
        bytes: null,
      );

      final result = await ocrService.extractTextFromScreenshot(screenshot);
      expect(result, isNull);
    });

    test('should handle screenshot with invalid file path', () async {
      final screenshot = Screenshot(
        id: 'test-id',
        addedOn: DateTime.now(),
        tags: [],
        collectionIds: [],
        aiProcessed: false,
        path: '/invalid/path/to/file.png',
        bytes: null,
      );

      final result = await ocrService.extractTextFromScreenshot(screenshot);
      expect(result, isNull);
    });

    test('should handle screenshot with empty bytes', () async {
      final screenshot = Screenshot(
        id: 'test-id',
        addedOn: DateTime.now(),
        tags: [],
        collectionIds: [],
        aiProcessed: false,
        path: null,
        bytes: Uint8List(0),
      );

      final result = await ocrService.extractTextFromScreenshot(screenshot);
      expect(result, isNull);
    });

    test('should copy text to clipboard', () async {
      const testText = 'Hello, World!';

      // Test that the method can be called without throwing
      await expectLater(ocrService.copyToClipboard(testText), completes);
    });

    test(
      'extractTextAndCopyToClipboard should return null for invalid screenshot',
      () async {
        final screenshot = Screenshot(
          id: 'test-id',
          addedOn: DateTime.now(),
          tags: [],
          collectionIds: [],
          aiProcessed: false,
          path: null,
          bytes: null,
        );

        final result = await ocrService.extractTextAndCopyToClipboard(
          screenshot,
        );
        expect(result, isNull);
      },
    );
  });
}
