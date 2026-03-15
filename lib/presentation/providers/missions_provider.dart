import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../data/models/mission.dart';
import '../../data/models/mission_step.dart';

final missionsListProvider = FutureProvider<List<Mission>>((ref) async {
  final repo = ref.watch(missionRepositoryProvider);
  return repo.getAllMissions();
});

final missionDetailProvider =
    FutureProvider.family<Mission?, String>((ref, missionId) async {
  final repo = ref.watch(missionRepositoryProvider);
  return repo.getMissionById(missionId);
});

final missionStepsProvider =
    FutureProvider.family<List<MissionStep>, String>((ref, missionId) async {
  final repo = ref.watch(missionRepositoryProvider);
  return repo.getStepsByMissionId(missionId);
});
