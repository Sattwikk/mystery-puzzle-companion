import '../database/database_helper.dart';
import '../models/team.dart';

/// Repository for teams. Encapsulates data access.
class TeamRepository {
  TeamRepository(this._db);

  final DatabaseHelper _db;

  Future<List<Team>> getAllTeams() => _db.getAllTeams();
  Future<Team?> getTeamById(String id) => _db.getTeamById(id);
  Future<String> createTeam(Team team) => _db.insertTeam(team);
  Future<int> updateTeam(Team team) => _db.updateTeam(team);
  Future<int> deleteTeam(String id) => _db.deleteTeam(id);
}
