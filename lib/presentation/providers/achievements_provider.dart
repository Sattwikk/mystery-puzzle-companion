import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../data/models/achievement.dart';

final achievementsListProvider = FutureProvider<List<Achievement>>((ref) async {
  final repo = ref.watch(achievementRepositoryProvider);
  return repo.getAllAchievements();
});

final achievementsByTeamProvider =
    FutureProvider.family<List<Achievement>, String?>((ref, teamId) async {
  final repo = ref.watch(achievementRepositoryProvider);
  return repo.getAchievementsByTeamId(teamId);
});
