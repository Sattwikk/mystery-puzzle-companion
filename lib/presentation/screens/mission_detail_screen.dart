import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/missions_provider.dart';
import 'mission_builder_screen.dart';
import 'mission_player_screen.dart';

/// Mission detail: show mission and steps; actions to edit or play.
class MissionDetailScreen extends ConsumerWidget {
  const MissionDetailScreen({super.key, required this.missionId});

  final String missionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionAsync = ref.watch(missionDetailProvider(missionId));
    final stepsAsync = ref.watch(missionStepsProvider(missionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission Details'),
        actions: [
          missionAsync.when(
            data: (mission) => mission != null
                ? IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MissionBuilderScreen(
                          missionId: mission.id,
                          mission: mission,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: missionAsync.when(
        data: (mission) {
          if (mission == null) {
            return const Center(child: Text('Mission not found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (mission.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(mission.description),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Steps',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                stepsAsync.when(
                  data: (steps) {
                    if (steps.isEmpty) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: const Card(
                          key: ValueKey('empty'),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No steps. Edit mission to add steps.'),
                          ),
                        ),
                      );
                    }
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Column(
                        key: ValueKey(steps.length),
                        children: steps
                            .map(
                              (s) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text('${s.orderIndex + 1}'),
                                  ),
                                  title: Text(s.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.timeLimitSeconds != null
                                          ? '${s.timeLimitSeconds}s limit'
                                          : 'No time limit',
                                    ),
                                    if (s.description != null &&
                                        s.description!.trim().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          s.description!.trim(),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    if (s.clueText != null &&
                                        s.clueText!.trim().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Hint available',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MissionPlayerScreen(missionId: mission.id),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play Mission'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
