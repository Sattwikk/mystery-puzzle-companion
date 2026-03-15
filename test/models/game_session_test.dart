import 'package:project_1/data/models/game_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final started = DateTime.utc(2025, 3, 1, 10, 0, 0);
  final completed = DateTime.utc(2025, 3, 1, 10, 5, 0);

  group('GameSession', () {
    test('fromMap builds session with required fields', () {
      final map = {
        'id': 's1',
        'mission_id': 'm1',
        'team_id': 't1',
        'started_at': started.toIso8601String(),
        'completed_at': completed.toIso8601String(),
        'success': 1,
        'hints_used': 2,
        'current_step_index': 1,
      };
      final session = GameSession.fromMap(map);
      expect(session.id, 's1');
      expect(session.missionId, 'm1');
      expect(session.teamId, 't1');
      expect(session.startedAt, started);
      expect(session.completedAt, completed);
      expect(session.success, true);
      expect(session.hintsUsed, 2);
      expect(session.currentStepIndex, 1);
    });

    test('fromMap defaults success and hints when null', () {
      final map = <String, dynamic>{
        'id': 's2',
        'mission_id': 'm2',
        'team_id': 't2',
        'started_at': started.toIso8601String(),
      };
      final session = GameSession.fromMap(map);
      expect(session.success, false);
      expect(session.hintsUsed, 0);
      expect(session.currentStepIndex, 0);
    });

    test('elapsedSeconds returns difference when completed', () {
      final session = GameSession(
        id: 's3',
        missionId: 'm3',
        teamId: 't3',
        startedAt: started,
        completedAt: completed,
        success: true,
      );
      expect(session.elapsedSeconds, 300);
    });

    test('toMap round-trip', () {
      final session = GameSession(
        id: 's4',
        missionId: 'm4',
        teamId: 't4',
        startedAt: started,
        completedAt: completed,
        success: true,
        hintsUsed: 1,
      );
      final restored = GameSession.fromMap(session.toMap());
      expect(restored.id, session.id);
      expect(restored.success, true);
      expect(restored.hintsUsed, 1);
    });
  });
}
