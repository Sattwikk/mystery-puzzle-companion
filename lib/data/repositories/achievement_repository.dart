import '../database/database_helper.dart';
import '../models/achievement.dart';

/// Repository for achievements.
class AchievementRepository {
  AchievementRepository(this._db);

  final DatabaseHelper _db;

  Future<String> addAchievement(Achievement achievement) =>
      _db.insertAchievement(achievement);
  Future<List<Achievement>> getAllAchievements() => _db.getAllAchievements();
  Future<List<Achievement>> getAchievementsByTeamId(String? teamId) =>
      _db.getAchievementsByTeamId(teamId);
}
