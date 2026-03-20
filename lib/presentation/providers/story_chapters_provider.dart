import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../data/models/story_chapter.dart';

final storyChaptersByTeamProvider =
    FutureProvider.family<List<StoryChapter>, String>((ref, teamId) async {
  final repo = ref.watch(storyChapterRepositoryProvider);
  return repo.getStoryChaptersByTeamId(teamId);
});

