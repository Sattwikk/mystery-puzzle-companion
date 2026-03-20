import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/database_helper.dart';
import '../../data/preferences/preferences_service.dart';
import '../../data/repositories/achievement_repository.dart';
import '../../data/repositories/mission_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/team_repository.dart';
import '../../data/repositories/story_chapter_repository.dart';

/// Dependency injection via Riverpod. Single source of truth for DB, preferences, repositories.
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final preferencesServiceProvider = FutureProvider<PreferencesService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return PreferencesService(prefs);
});

final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  final db = ref.watch(databaseHelperProvider);
  return MissionRepository(db);
});

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  final db = ref.watch(databaseHelperProvider);
  return TeamRepository(db);
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final db = ref.watch(databaseHelperProvider);
  return SessionRepository(db);
});

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  final db = ref.watch(databaseHelperProvider);
  return AchievementRepository(db);
});

final storyChapterRepositoryProvider = Provider<StoryChapterRepository>((ref) {
  final db = ref.watch(databaseHelperProvider);
  return StoryChapterRepository(db);
});
