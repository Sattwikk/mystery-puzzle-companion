import '../database/database_helper.dart';
import '../models/mission.dart';
import '../models/mission_step.dart';

/// Repository for missions and steps. Encapsulates data access (clean architecture).
class MissionRepository {
  MissionRepository(this._db);

  final DatabaseHelper _db;

  Future<List<Mission>> getAllMissions() => _db.getAllMissions();
  Future<Mission?> getMissionById(String id) => _db.getMissionById(id);
  Future<String> createMission(Mission mission) => _db.insertMission(mission);
  Future<int> updateMission(Mission mission) => _db.updateMission(mission);
  Future<int> deleteMission(String id) => _db.deleteMission(id);

  Future<List<MissionStep>> getStepsByMissionId(String missionId) =>
      _db.getStepsByMissionId(missionId);
  Future<String> addStep(MissionStep step) => _db.insertStep(step);
  Future<int> updateStep(MissionStep step) => _db.updateStep(step);
  Future<int> deleteStep(String id) => _db.deleteStep(id);
  Future<int> deleteStepsByMissionId(String missionId) =>
      _db.deleteStepsByMissionId(missionId);
}
