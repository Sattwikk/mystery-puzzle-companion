import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/achievement.dart';
import '../models/game_session.dart';
import '../models/mission.dart';
import '../models/mission_step.dart';
import '../models/story_chapter.dart';
import '../models/team.dart';

/// SQLite database helper. Manages schema and CRUD for missions, steps, teams, sessions, achievements.
/// Always close or use single instance to avoid connection leaks.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;
  static const String _dbName = 'mystery_puzzle.db';
  static const int _dbVersion = 3;

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    final database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    // Ensure seed content is present even if the DB exists but is empty.
    await _seedStarterData(database);
    return database;
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
      CREATE TABLE session_clues (
        session_id TEXT NOT NULL,
        step_id TEXT NOT NULL,
        clue_text TEXT,
        discovered_at TEXT NOT NULL,
        PRIMARY KEY (session_id, step_id)
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
    await db.execute('''
      CREATE TABLE story_chapters (
        id TEXT PRIMARY KEY,
        chapter_index INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        unlocked_at TEXT,
        team_id TEXT NOT NULL,
        FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_steps_mission ON mission_steps(mission_id)');
    await db.execute('CREATE INDEX idx_sessions_mission ON game_sessions(mission_id)');
    await db.execute('CREATE INDEX idx_sessions_team ON game_sessions(team_id)');
    await db.execute('CREATE INDEX idx_session_clues_session ON session_clues(session_id)');
    await db.execute('CREATE INDEX idx_story_chapters_team ON story_chapters(team_id)');
  }

  Future<void> _seedStarterData(Database db) async {
    // Seed starter content so the app isn't empty after a fresh install.
    // This is deterministic and safe: we insert only missing rows by ID.

    const teamId = 'seed_team_1';
    const mission1Id = 'seed_mission_1';
    const mission2Id = 'seed_mission_2';
    const mission3Id = 'seed_mission_3';

    Future<bool> _exists(String table, String idColumn, String id) async {
      final rows = await db.rawQuery(
        'SELECT 1 FROM $table WHERE $idColumn = ? LIMIT 1',
        [id],
      );
      return rows.isNotEmpty;
    }

    Future<void> _insertTeamIfMissing(DateTime now) async {
      if (await _exists('teams', 'id', teamId)) return;
      await db.insert('teams', {
        'id': teamId,
        'name': 'Team Alpha',
        'created_at': now.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    Future<void> _insertMissionIfMissing({
      required String missionId,
      required String title,
      required String description,
      required DateTime now,
    }) async {
      if (await _exists('missions', 'id', missionId)) return;
      await db.insert('missions', {
        'id': missionId,
        'title': title,
        'description': description,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    Future<bool> _stepExists(String stepId) async {
      final rows = await db.rawQuery(
        'SELECT 1 FROM mission_steps WHERE id = ? LIMIT 1',
        [stepId],
      );
      return rows.isNotEmpty;
    }

    Future<void> insertStepIfMissing({
      required String id,
      required String missionId,
      required int orderIndex,
      required String title,
      required String description,
      required int? timeLimitSeconds,
      required String? clueText,
    }) async {
      if (await _stepExists(id)) return;
      await db.insert('mission_steps', {
        'id': id,
        'mission_id': missionId,
        'title': title,
        'order_index': orderIndex,
        'description': description,
        'time_limit_seconds': timeLimitSeconds,
        'clue_text': clueText,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    final now = DateTime.now();
    await _insertTeamIfMissing(now);

    await _insertMissionIfMissing(
      missionId: mission1Id,
      title: 'The Locked Study Room',
      description:
          'A famous detective has disappeared inside his study room. Solve the puzzles and unlock the clues to escape before time runs out.',
      now: now,
    );
    await _insertMissionIfMissing(
      missionId: mission2Id,
      title: 'The Missing Artifact',
      description:
          'A priceless artifact has been stolen from the museum. Follow the clues left behind by the thief to discover the truth.',
      now: now,
    );
    await _insertMissionIfMissing(
      missionId: mission3Id,
      title: 'Escape the Secret Lab',
      description:
          'You wake up inside a mysterious laboratory. Solve the puzzles quickly before the system locks down.',
      now: now,
    );

    // Mission 1 steps
    await insertStepIfMissing(
      id: 'seed_m1_s1',
      missionId: mission1Id,
      orderIndex: 0,
      title: 'Find the Hidden Key',
      description:
          'Search the room description and identify where the hidden key might be located.',
      timeLimitSeconds: 60,
      clueText:
          'Hint: scan corners first—keys often hide under or behind something noticeable (rug, frame, book).',
    );
    await insertStepIfMissing(
      id: 'seed_m1_s2',
      missionId: mission1Id,
      orderIndex: 1,
      title: 'Decode the Secret Message',
      description:
          'Decode the message: “KHOOR” (Hint: Caesar cipher).',
      timeLimitSeconds: 120,
      clueText:
          'Hint: Caesar cipher shifted +3; shift each letter back 3 to get “HELLO”.',
    );
    await insertStepIfMissing(
      id: 'seed_m1_s3',
      missionId: mission1Id,
      orderIndex: 2,
      title: 'Unlock the Drawer',
      description:
          'Enter the correct 3-digit code based on the previous clue.',
      timeLimitSeconds: 120,
      clueText:
          'Hint idea: map letters to positions (A=1…Z=26). Use HELLO to form a 3-digit code your team agrees on.',
    );
    await insertStepIfMissing(
      id: 'seed_m1_s4',
      missionId: mission1Id,
      orderIndex: 3,
      title: 'Escape the Study Room',
      description:
          'Use the discovered key and code to unlock the door.',
      timeLimitSeconds: 300,
      clueText:
          'Hint: role-play the final action. Recite the switch/panel steps and the chosen door code out loud together.',
    );

    // Mission 2 steps
    await insertStepIfMissing(
      id: 'seed_m2_s1',
      missionId: mission2Id,
      orderIndex: 0,
      title: 'Examine the Security Camera Log',
      description:
          'Identify the suspicious timestamp in the log.',
      timeLimitSeconds: 60,
      clueText:
          'Hint: look for an interruption, glitch, or unusually long gap between entries.',
    );
    await insertStepIfMissing(
      id: 'seed_m2_s2',
      missionId: mission2Id,
      orderIndex: 1,
      title: 'Solve the Number Puzzle',
      description:
          'Find the missing number in the sequence: 2, 6, 12, 20, ?',
      timeLimitSeconds: 120,
      clueText:
          'Hint: differences are +4, +6, +8, +10 → next difference is +12 → 20 + 10 = 30.',
    );
    await insertStepIfMissing(
      id: 'seed_m2_s3',
      missionId: mission2Id,
      orderIndex: 2,
      title: 'Identify the Suspect',
      description:
          'Match the clue with the correct suspect from the list.',
      timeLimitSeconds: 120,
      clueText:
          'Hint: the suspect whose actions align with the suspicious timestamp is the likely culprit.',
    );
    await insertStepIfMissing(
      id: 'seed_m2_s4',
      missionId: mission2Id,
      orderIndex: 3,
      title: 'Recover the Artifact',
      description:
          'Enter the final passcode to recover the stolen artifact.',
      timeLimitSeconds: 300,
      clueText:
          'Hint: your final passcode should combine the suspicious time + the number puzzle result.',
    );

    // Mission 3 steps
    await insertStepIfMissing(
      id: 'seed_m3_s1',
      missionId: mission3Id,
      orderIndex: 0,
      title: 'Restore Power',
      description:
          'Arrange the switches in the correct order.',
      timeLimitSeconds: 60,
      clueText:
          'Hint: try a safe sequence—aux/smaller controls first, then main power, then backup.',
    );
    await insertStepIfMissing(
      id: 'seed_m3_s2',
      missionId: mission3Id,
      orderIndex: 1,
      title: 'Crack the Password',
      description:
          'Solve the riddle: “I speak without a mouth and hear without ears. What am I?”',
      timeLimitSeconds: 120,
      clueText:
          'Hint: the answer to the riddle is “Echo”.',
    );
    await insertStepIfMissing(
      id: 'seed_m3_s3',
      missionId: mission3Id,
      orderIndex: 2,
      title: 'Find the Hidden Formula',
      description:
          'Identify the correct chemical formula from the clues.',
      timeLimitSeconds: 120,
      clueText:
          'Hint: look for a formula that matches the story context (example: glucose is C6H12O6).',
    );
    await insertStepIfMissing(
      id: 'seed_m3_s4',
      missionId: mission3Id,
      orderIndex: 3,
      title: 'Open the Exit Door',
      description:
          'Enter the password discovered earlier to escape.',
      timeLimitSeconds: 300,
      clueText:
          'Hint: recite the password (and any key info from prior steps) exactly as your team agreed.',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS session_clues (
          session_id TEXT NOT NULL,
          step_id TEXT NOT NULL,
          clue_text TEXT,
          discovered_at TEXT NOT NULL,
          PRIMARY KEY (session_id, step_id)
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_session_clues_session ON session_clues(session_id)');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS story_chapters (
          id TEXT PRIMARY KEY,
          chapter_index INTEGER NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          unlocked_at TEXT,
          team_id TEXT NOT NULL,
          FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_story_chapters_team ON story_chapters(team_id)');
    }

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

  // --- Session clues / hint tracking ---
  Future<List<String>> getDiscoveredStepIds(String sessionId) async {
    final db = await database;
    final maps = await db.query(
      'session_clues',
      columns: ['step_id'],
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    return maps.map((m) => m['step_id'] as String).toList();
  }

  /// Records that a clue was used/unlocked for a given mission step.
  /// Returns true if this is the first time for this step (and hints_used was incremented).
  Future<bool> recordClueUsage({
    required String sessionId,
    required String stepId,
    required String clueText,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final existing = await txn.query(
        'session_clues',
        columns: ['step_id'],
        where: 'session_id = ? AND step_id = ?',
        whereArgs: [sessionId, stepId],
        limit: 1,
      );
      if (existing.isNotEmpty) return false;

      await txn.insert('session_clues', {
        'session_id': sessionId,
        'step_id': stepId,
        'clue_text': clueText,
        'discovered_at': DateTime.now().toIso8601String(),
      });
      await txn.rawUpdate(
        'UPDATE game_sessions SET hints_used = hints_used + 1 WHERE id = ?',
        [sessionId],
      );
      return true;
    });
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

  Future<Achievement?> getAchievementById(String id) async {
    final db = await database;
    final maps =
        await db.query('achievements', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Achievement.fromMap(maps.first);
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

  // --- Story chapters ---
  Future<String> insertStoryChapter(StoryChapter chapter) async {
    final db = await database;
    await db.insert('story_chapters', chapter.toMap());
    return chapter.id;
  }

  Future<StoryChapter?> getStoryChapterById(String id) async {
    final db = await database;
    final maps =
        await db.query('story_chapters', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return StoryChapter.fromMap(maps.first);
  }

  Future<List<StoryChapter>> getStoryChaptersByTeamId(String teamId) async {
    final db = await database;
    final maps = await db.query(
      'story_chapters',
      where: 'team_id = ?',
      whereArgs: [teamId],
      orderBy: 'chapter_index ASC',
    );
    return maps.map((m) => StoryChapter.fromMap(m)).toList();
  }
}
