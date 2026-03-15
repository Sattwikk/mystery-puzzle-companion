import 'package:project_1/data/models/team.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Team', () {
    test('fromMap builds Team correctly', () {
      final map = {
        'id': 't1',
        'name': 'Team Alpha',
        'created_at': '2025-03-01T12:00:00.000Z',
      };
      final team = Team.fromMap(map);
      expect(team.id, 't1');
      expect(team.name, 'Team Alpha');
      expect(team.createdAt, DateTime.utc(2025, 3, 1, 12, 0, 0));
    });

    test('fromMap handles null createdAt', () {
      final map = <String, dynamic>{'id': 't2', 'name': 'No Date'};
      final team = Team.fromMap(map);
      expect(team.createdAt, isNull);
    });

    test('toMap round-trip', () {
      final team = Team(
        id: 't3',
        name: 'Round',
        createdAt: DateTime.utc(2025, 1, 15),
      );
      final restored = Team.fromMap(team.toMap());
      expect(restored.id, team.id);
      expect(restored.name, team.name);
    });

    test('copyWith updates name', () {
      const team = Team(id: 'id', name: 'Old');
      final updated = team.copyWith(name: 'New');
      expect(updated.id, 'id');
      expect(updated.name, 'New');
    });
  });
}
