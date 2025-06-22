import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/custom_path_service.dart';

void main() {
  group('CustomPathService', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('should return empty list when no custom paths exist', () async {
      final paths = await CustomPathService.getCustomPaths();
      expect(paths, isEmpty);
    });

    test('should add a new custom path successfully', () async {
      const testPath = '/storage/emulated/0/Pictures/TestFolder';

      final success = await CustomPathService.addCustomPath(testPath);
      expect(success, isTrue);

      final paths = await CustomPathService.getCustomPaths();
      expect(paths, contains(testPath));
      expect(paths.length, equals(1));
    });

    test('should not add duplicate paths', () async {
      const testPath = '/storage/emulated/0/Pictures/TestFolder';

      // Add path first time
      final success1 = await CustomPathService.addCustomPath(testPath);
      expect(success1, isTrue);

      // Try to add same path again
      final success2 = await CustomPathService.addCustomPath(testPath);
      expect(success2, isFalse);

      final paths = await CustomPathService.getCustomPaths();
      expect(paths.length, equals(1));
    });

    test('should not add empty or whitespace-only paths', () async {
      final success1 = await CustomPathService.addCustomPath('');
      final success2 = await CustomPathService.addCustomPath('   ');

      expect(success1, isFalse);
      expect(success2, isFalse);

      final paths = await CustomPathService.getCustomPaths();
      expect(paths, isEmpty);
    });

    test('should remove existing custom path', () async {
      const testPath1 = '/storage/emulated/0/Pictures/TestFolder1';
      const testPath2 = '/storage/emulated/0/Pictures/TestFolder2';

      // Add two paths
      await CustomPathService.addCustomPath(testPath1);
      await CustomPathService.addCustomPath(testPath2);

      // Remove one path
      final success = await CustomPathService.removeCustomPath(testPath1);
      expect(success, isTrue);

      final paths = await CustomPathService.getCustomPaths();
      expect(paths, isNot(contains(testPath1)));
      expect(paths, contains(testPath2));
      expect(paths.length, equals(1));
    });

    test(
      'should return false when trying to remove non-existent path',
      () async {
        const testPath = '/storage/emulated/0/Pictures/TestFolder';

        final success = await CustomPathService.removeCustomPath(testPath);
        expect(success, isFalse);
      },
    );

    test('should add multiple custom paths', () async {
      const testPaths = [
        '/storage/emulated/0/Pictures/Screenshots',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/DCIM/Camera',
      ];

      for (final path in testPaths) {
        final success = await CustomPathService.addCustomPath(path);
        expect(success, isTrue);
      }

      final paths = await CustomPathService.getCustomPaths();
      expect(paths.length, equals(testPaths.length));

      for (final path in testPaths) {
        expect(paths, contains(path));
      }
    });

    test('should clear all custom paths', () async {
      const testPaths = [
        '/storage/emulated/0/Pictures/Screenshots',
        '/storage/emulated/0/Download',
      ];

      // Add some paths
      for (final path in testPaths) {
        await CustomPathService.addCustomPath(path);
      }

      // Verify paths were added
      final pathsBeforeClear = await CustomPathService.getCustomPaths();
      expect(pathsBeforeClear.length, equals(testPaths.length));

      // Clear all paths
      final success = await CustomPathService.clearAllCustomPaths();
      expect(success, isTrue);

      // Verify all paths are cleared
      final pathsAfterClear = await CustomPathService.getCustomPaths();
      expect(pathsAfterClear, isEmpty);
    });

    test('should persist custom paths across service calls', () async {
      const testPath = '/storage/emulated/0/Pictures/TestFolder';

      // Add path
      await CustomPathService.addCustomPath(testPath);

      // Get paths multiple times to simulate different service instances
      final paths1 = await CustomPathService.getCustomPaths();
      final paths2 = await CustomPathService.getCustomPaths();

      expect(paths1, contains(testPath));
      expect(paths2, contains(testPath));
      expect(paths1, equals(paths2));
    });
  });
}
