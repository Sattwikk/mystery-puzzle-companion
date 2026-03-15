import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../data/models/game_session.dart';

final sessionsListProvider = FutureProvider<List<GameSession>>((ref) async {
  final repo = ref.watch(sessionRepositoryProvider);
  return repo.getAllSessions();
});

final sessionsByTeamProvider =
    FutureProvider.family<List<GameSession>, String>((ref, teamId) async {
  final repo = ref.watch(sessionRepositoryProvider);
  return repo.getSessionsByTeamId(teamId);
});

final sessionDetailProvider =
    FutureProvider.family<GameSession?, String>((ref, sessionId) async {
  final repo = ref.watch(sessionRepositoryProvider);
  return repo.getSessionById(sessionId);
});

final leaderboardProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(sessionRepositoryProvider);
  return repo.getLeaderboard(limit: 20);
});
