import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/achievement.dart';
import '../models/game_session.dart';
import '../models/mission.dart';
import '../models/mission_step.dart';
import '../models/team.dart';

/// SQLite database helper. Manages schema and CRUD for missions, steps, teams, sessions, achievements.
/// Always close or use single instance to avoid connection leaks.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;
  static const String _dbName = 'mystery_puzzle.db';
  static const int _dbVersion = 1;

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE missions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE mission_steps (
        id TEXT PRIMARY KEY,
        mission_id TEXT NOT NULL,
        title TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        description TEXT,
        time_limit_seconds INTEGER,
        clue_text TEXT,
        FOREIGN KEY (mission_id) REFERENCES missions(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE teams (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE game_sessions (
        id TEXT PRIMARY KEY,
        mission_id TEXT NOT NULL,
        team_id TEXT NOT NULL,
        started_at TEXT NOT NULL,
        completed_at TEXT,
        success INTEGER DEFAULT 0,
        hints_used INTEGER DEFAULT 0,
        current_step_index INTEGER DEFAULT 0,
        FOREIGN KEY (mission_id) REFERENCES missions(id),
        FOREIGN KEY (team_id) REFERENCES teams(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        unlocked_at TEXT,
        team_id TEXT,
        FOREIGN KEY (team_id) REFERENCES teams(id)
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_steps_mission ON mission_steps(mission_id)');
    await db.execute('CREATE INDEX idx_sessions_mission ON game_sessions(mission_id)');
    await db.execute('CREATE INDEX idx_sessions_team ON game_sessions(team_id)');
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }

  // --- Missions ---
  Future<String> insertMission(Mission mission) async {
    final db = await database;
    await db.insert('missions', mission.toMap());
    return mission.id;
  }

  Future<List<Mission>> getAllMissions() async {
    final db = await database;
    final maps = await db.query('missions', orderBy: 'created_at DESC');
    return maps.map((m) => Mission.fromMap(m)).toList();
  }

  Future<Mission?> getMissionById(String id) async {
    final db = await database;
    final maps = await db.query('missions', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Mission.fromMap(maps.first);
  }

  Future<int> updateMission(Mission mission) async {
    final db = await database;
    return db.update(
      'missions',
      mission.toMap(),
      where: 'id = ?',
      whereArgs: [mission.id],
    );
  }

  Future<int> deleteMission(String id) async {
    final db = await database;
    await db.delete('mission_steps', where: 'mission_id = ?', whereArgs: [id]);
    return db.delete('missions', where: 'id = ?', whereArgs: [id]);
  }

  // --- Mission steps ---
  Future<String> insertStep(MissionStep step) async {
    final db = await database;
    await db.insert('mission_steps', step.toMap());
    return step.id;
  }

  Future<List<MissionStep>> getStepsByMissionId(String missionId) async {
    final db = await database;
    final maps = await db.query(
      'mission_steps',
      where: 'mission_id = ?',
      whereArgs: [missionId],
      orderBy: 'order_index ASC',
    );
    return maps.map((m) => MissionStep.fromMap(m)).toList();
  }

  Future<int> updateStep(MissionStep step) async {
    final db = await database;
    return db.update(
      'mission_steps',
      step.toMap(),
      where: 'id = ?',
      whereArgs: [step.id],
    );
  }

  Future<int> deleteStep(String id) async {
    final db = await database;
    return db.delete('mission_steps', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteStepsByMissionId(String missionId) async {
    final db = await database;
    return db.delete('mission_steps', where: 'mission_id = ?', whereArgs: [missionId]);
  }

  // --- Teams ---
  Future<String> insertTeam(Team team) async {
    final db = await database;
    await db.insert('teams', team.toMap());
    return team.id;
  }

  Future<List<Team>> getAllTeams() async {
    final db = await database;
    final maps = await db.query('teams', orderBy: 'name ASC');
    return maps.map((m) => Team.fromMap(m)).toList();
  }

  Future<Team?> getTeamById(String id) async {
    final db = await database;
    final maps = await db.query('teams', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Team.fromMap(maps.first);
  }

  Future<int> updateTeam(Team team) async {
    final db = await database;
    return db.update(
      'teams',
      team.toMap(),
      where: 'id = ?',
      whereArgs: [team.id],
    );
  }

  Future<int> deleteTeam(String id) async {
    final db = await database;
    return db.delete('teams', where: 'id = ?', whereArgs: [id]);
  }

  // --- Game sessions ---
  Future<String> insertSession(GameSession session) async {
    final db = await database;
    await db.insert('game_sessions', session.toMap());
    return session.id;
  }

  Future<List<GameSession>> getAllSessions() async {
    final db = await database;
    final maps = await db.query('game_sessions', orderBy: 'started_at DESC');
    return maps.map((m) => GameSession.fromMap(m)).toList();
  }

  Future<List<GameSession>> getSessionsByTeamId(String teamId) async {
    final db = await database;
    final maps = await db.query(
      'game_sessions',
      where: 'team_id = ?',
      whereArgs: [teamId],
      orderBy: 'started_at DESC',
    );
    return maps.map((m) => GameSession.fromMap(m)).toList();
  }

  Future<GameSession?> getSessionById(String id) async {
    final db = await database;
    final maps = await db.query('game_sessions', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return GameSession.fromMap(maps.first);
  }

  Future<int> updateSession(GameSession session) async {
    final db = await database;
    return db.update(
      'game_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  /// Leaderboard: completed sessions with best times (success = 1), ordered by elapsed time then hints.
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 20}) async {
    final db = await database;
    final sessions = await db.query(
      'game_sessions',
      where: 'success = 1 AND completed_at IS NOT NULL',
      orderBy: 'completed_at ASC',
    );
    final List<Map<String, dynamic>> withElapsed = [];
    for (final s in sessions) {
      final started = DateTime.parse(s['started_at'] as String);
      final completed = DateTime.parse(s['completed_at'] as String);
      withElapsed.add({
        ...s,
        'elapsed_seconds': completed.difference(started).inSeconds,
      });
    }
    withElapsed.sort((a, b) {
      final t = (a['elapsed_seconds'] as int).compareTo(b['elapsed_seconds'] as int);
      if (t != 0) return t;
      return (a['hints_used'] as int).compareTo(b['hints_used'] as int);
    });
    return withElapsed.take(limit).toList();
  }

  // --- Achievements ---
  Future<String> insertAchievement(Achievement achievement) async {
    final db = await database;
    await db.insert('achievements', achievement.toMap());
    return achievement.id;
  }

  Future<List<Achievement>> getAllAchievements() async {
    final db = await database;
    final maps = await db.query('achievements', orderBy: 'unlocked_at DESC');
    return maps.map((m) => Achievement.fromMap(m)).toList();
  }

  Future<List<Achievement>> getAchievementsByTeamId(String? teamId) async {
    final db = await database;
    if (teamId == null) {
      final maps = await db.query(
        'achievements',
        where: 'team_id IS NULL',
        orderBy: 'unlocked_at DESC',
      );
      return maps.map((m) => Achievement.fromMap(m)).toList();
    }
    final maps = await db.query(
      'achievements',
      where: 'team_id = ? OR team_id IS NULL',
      whereArgs: [teamId],
      orderBy: 'unlocked_at DESC',
    );
    return maps.map((m) => Achievement.fromMap(m)).toList();
  }
}
