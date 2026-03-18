import '../database/database_helper.dart';
import '../models/game_session.dart';

/// Repository for game sessions and leaderboard.
class SessionRepository {
  SessionRepository(this._db);

  final DatabaseHelper _db;

  Future<String> createSession(GameSession session) => _db.insertSession(session);
  Future<GameSession?> getSessionById(String id) => _db.getSessionById(id);
  Future<int> updateSession(GameSession session) => _db.updateSession(session);
  Future<List<GameSession>> getAllSessions() => _db.getAllSessions();
  Future<List<GameSession>> getSessionsByTeamId(String teamId) =>
      _db.getSessionsByTeamId(teamId);
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 20}) =>
      _db.getLeaderboard(limit: limit);

  /// Returns step ids for which the session has already unlocked clues.
  Future<List<String>> getDiscoveredStepIds(String sessionId) =>
      _db.getDiscoveredStepIds(sessionId);

  /// Records usage of a clue for a step and increments `hints_used` once.
  /// Returns true if this step was newly unlocked.
  Future<bool> recordClueUsage({
    required String sessionId,
    required String stepId,
    required String clueText,
  }) =>
      _db.recordClueUsage(sessionId: sessionId, stepId: stepId, clueText: clueText);
}
