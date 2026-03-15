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
}
