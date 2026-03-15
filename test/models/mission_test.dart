import 'package:project_1/data/models/mission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mission', () {
    test('fromMap builds Mission with required fields', () {
      final map = {
        'id': 'm1',
        'title': 'Test Mission',
        'description': 'Desc',
      };
      final mission = Mission.fromMap(map);
      expect(mission.id, 'm1');
      expect(mission.title, 'Test Mission');
      expect(mission.description, 'Desc');
      expect(mission.createdAt, isNull);
      expect(mission.updatedAt, isNull);
    });

    test('fromMap uses empty string when description is null', () {
      final map = <String, dynamic>{'id': 'm2', 'title': 'T', 'description': null};
      final mission = Mission.fromMap(map);
      expect(mission.description, '');
    });

    test('toMap round-trip equals original', () {
      final mission = Mission(
        id: 'm3',
        title: 'Round',
        description: 'Trip',
        createdAt: DateTime.utc(2025, 3, 1),
        updatedAt: DateTime.utc(2025, 3, 2),
      );
      final map = mission.toMap();
      final restored = Mission.fromMap(map);
      expect(restored.id, mission.id);
      expect(restored.title, mission.title);
      expect(restored.description, mission.description);
    });

    test('copyWith updates only given fields', () {
      const mission = Mission(id: 'id', title: 'A', description: 'B');
      final updated = mission.copyWith(title: 'New Title');
      expect(updated.id, 'id');
      expect(updated.title, 'New Title');
      expect(updated.description, 'B');
    });

    test('equality uses props', () {
      const a = Mission(id: 'x', title: 'T', description: 'D');
      const b = Mission(id: 'x', title: 'T', description: 'D');
      expect(a, equals(b));
      expect(a.copyWith(title: 'Other'), isNot(equals(a)));
    });
  });
}
