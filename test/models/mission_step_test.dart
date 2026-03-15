import 'package:project_1/data/models/mission_step.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MissionStep', () {
    test('fromMap builds step with all fields', () {
      final map = {
        'id': 's1',
        'mission_id': 'm1',
        'title': 'Step One',
        'order_index': 0,
        'description': 'Desc',
        'time_limit_seconds': 60,
        'clue_text': 'Clue',
      };
      final step = MissionStep.fromMap(map);
      expect(step.id, 's1');
      expect(step.missionId, 'm1');
      expect(step.title, 'Step One');
      expect(step.orderIndex, 0);
      expect(step.description, 'Desc');
      expect(step.timeLimitSeconds, 60);
      expect(step.clueText, 'Clue');
    });

    test('fromMap handles null optionals', () {
      final map = {
        'id': 's2',
        'mission_id': 'm2',
        'title': 'Step',
        'order_index': 1,
      };
      final step = MissionStep.fromMap(map);
      expect(step.description, isNull);
      expect(step.timeLimitSeconds, isNull);
      expect(step.clueText, isNull);
    });

    test('toMap round-trip', () {
      const step = MissionStep(
        id: 's3',
        missionId: 'm3',
        title: 'T',
        orderIndex: 2,
        timeLimitSeconds: 120,
      );
      final restored = MissionStep.fromMap(step.toMap());
      expect(restored.id, step.id);
      expect(restored.orderIndex, step.orderIndex);
      expect(restored.timeLimitSeconds, 120);
    });

    test('copyWith preserves unspecified fields', () {
      const step = MissionStep(
        id: 's4',
        missionId: 'm4',
        title: 'Original',
        orderIndex: 0,
      );
      final updated = step.copyWith(title: 'Updated');
      expect(updated.id, 's4');
      expect(updated.title, 'Updated');
      expect(updated.orderIndex, 0);
    });
  });
}
