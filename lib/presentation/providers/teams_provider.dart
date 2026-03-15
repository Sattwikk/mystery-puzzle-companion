import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../data/models/team.dart';

final teamsListProvider = FutureProvider<List<Team>>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getAllTeams();
});

final teamDetailProvider =
    FutureProvider.family<Team?, String>((ref, teamId) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getTeamById(teamId);
});
