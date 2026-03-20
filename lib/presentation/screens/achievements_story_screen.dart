import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/story_chapter.dart';
import '../providers/achievements_provider.dart';
import '../providers/story_chapters_provider.dart';
import '../providers/teams_provider.dart';
import '../widgets/section_card.dart';
import '../screens/teams_screen.dart';

/// Shows unlocked achievements and story chapters for a selected team.
class AchievementsStoryScreen extends ConsumerStatefulWidget {
  const AchievementsStoryScreen({super.key});

  @override
  ConsumerState<AchievementsStoryScreen> createState() =>
      _AchievementsStoryScreenState();
}

class _AchievementsStoryScreenState
    extends ConsumerState<AchievementsStoryScreen> {
  String? _selectedTeamId;

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements & Story'),
      ),
      body: teamsAsync.when(
        data: (teams) {
          if (teams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_outline, size: 64),
                  const SizedBox(height: 12),
                  const Text('Create a team to unlock achievements.'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TeamsScreen()),
                    ),
                    icon: const Icon(Icons.groups),
                    label: const Text('Go to Teams'),
                  ),
                ],
              ),
            );
          }

          if (_selectedTeamId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _selectedTeamId = teams.first.id);
            });
          }

          if (_selectedTeamId == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final achievementsAsync =
              ref.watch(achievementsByTeamProvider(_selectedTeamId!));
          final storyAsync =
              ref.watch(storyChaptersByTeamProvider(_selectedTeamId!));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                title: 'Achievements',
                child: achievementsAsync.when(
                  data: (achievements) {
                    if (achievements.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('No achievements unlocked yet.'),
                      );
                    }
                    return Column(
                      children: achievements
                          .map(
                            (a) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.emoji_events),
                              title: Text(a.title),
                              subtitle: a.description.isNotEmpty
                                  ? Text(a.description)
                                  : null,
                            ),
                          )
                          .toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Error: $e'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Story Chapters',
                child: storyAsync.when(
                  data: (chapters) {
                    if (chapters.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Complete missions to unlock chapters.'),
                      );
                    }
                    return Column(
                      children: chapters
                          .map(
                            (c) => _StoryChapterTile(chapter: c),
                          )
                          .toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Error: $e'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StoryChapterTile extends StatelessWidget {
  const _StoryChapterTile({required this.chapter});

  final StoryChapter chapter;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Text('${chapter.chapterIndex}'),
      ),
      title: Text(chapter.title),
      subtitle: chapter.description.isNotEmpty ? Text(chapter.description) : null,
    );
  }
}

