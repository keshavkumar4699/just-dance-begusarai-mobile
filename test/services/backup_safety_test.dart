import 'package:flutter_test/flutter_test.dart';
import 'package:studio_crow/models/studio_info.dart';

void main() {
  group('Backup & Safety Mechanics Tests', () {
    test('Default StudioInfo serializes correctly', () {
      final info = StudioInfo.defaultInfo;
      final map = info.toMap();
      final restored = StudioInfo.fromMap(map);

      expect(restored.studioName, equals('Studio Crow'));
      expect(restored.directorName, equals('Rahul Raja Sir'));
      expect(restored.ownerFooter, contains('Rahul Raja Sir'));
    });
  });
}
