import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sessions_provider.dart';

/// Leaderboard: completed missions ranked by time, then hints used.
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(leaderboardProvider),
        child: leaderboardAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: const Center(
                      child: Text(
                        'No completed missions yet.\nComplete a mission to appear here.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final row = list[index];
                final rank = index + 1;
                final teamId = row['team_id']?.toString() ?? '?';
                final teamShort = teamId.length > 8 ? '${teamId.substring(0, 8)}...' : teamId;
                final elapsed = row['elapsed_seconds'] as int? ?? 0;
                final hints = row['hints_used'] as int? ?? 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('$rank'),
                    ),
                    title: Text('Team $teamShort'),
                    subtitle: Text(
                      '${elapsed}s • $hints hints used',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
