import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/export_service.dart';
import '../providers/missions_provider.dart';
import '../providers/sessions_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/section_card.dart';
import 'mission_player_screen.dart';
import 'missions_screen.dart';
import 'teams_screen.dart';
import 'leaderboard_screen.dart';

/// Home / Dashboard: recent sessions, quick start, leaderboard summary.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsListProvider);
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mystery Puzzle Companion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
            ),
          ),
          IconButton(
            icon: Icon(ref.watch(themeModeProvider)
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(sessionsListProvider);
          ref.invalidate(leaderboardProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: 'Quick Start',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MissionsScreen()),
                    ),
                    icon: const Icon(Icons.list),
                    label: const Text('Browse Missions'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TeamsScreen()),
                    ),
                    icon: const Icon(Icons.groups),
                    label: const Text('Teams & Sessions'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MissionPlayerScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play a Mission'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _exportData(context, ref),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Export data (JSON)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Recent Sessions',
              child: sessionsAsync.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No sessions yet. Start by creating a team and playing a mission.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  final recent = sessions.take(5).toList();
                  return Column(
                    children: recent
                        .map((s) => ListTile(
                              leading: Icon(
                                s.success ? Icons.check_circle : Icons.schedule,
                                color: s.success ? Colors.green : null,
                              ),
                              title: Text('Session ${s.id.substring(0, 8)}...'),
                              subtitle: Text(
                                DateFormat.yMd().add_Hm().format(s.startedAt),
                              ),
                              trailing: s.completedAt != null
                                  ? Text(
                                      '${s.elapsedSeconds ?? 0}s',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    )
                                  : const Text('In progress'),
                            ))
                        .toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Leaderboard (Top 3)',
              child: leaderboardAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Complete a mission to appear here.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  final top = list.take(3).toList();
                  return Column(
                    children: top.asMap().entries.map((e) {
                      final i = e.key + 1;
                      final row = e.value;
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text('$i'),
                        ),
                        title: Text('Team ${row['team_id']?.toString().substring(0, 8) ?? '?'}'),
                        trailing: Text(
                          '${row['elapsed_seconds']}s, ${row['hints_used']} hints',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final missions = await ref.read(missionsListProvider.future);
    final sessions = await ref.read(sessionsListProvider.future);
    final path = await ExportService.exportToJson(
      missions: missions.map((m) => m.toMap()).toList(),
      sessions: sessions.map((s) => s.toMap()).toList(),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path != null
                ? 'Exported to $path'
                : 'Export failed',
          ),
        ),
      );
    }
  }
}
