import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/di/providers.dart';
import '../../data/models/team.dart';
import '../providers/sessions_provider.dart';
import '../providers/teams_provider.dart';

/// Teams list: create teams, view sessions per team.
class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teams & Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateTeamDialog(context, ref),
          ),
        ],
      ),
      body: teamsAsync.when(
        data: (teams) {
          if (teams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  const Text('No teams yet'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _showCreateTeamDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Team'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  leading: const CircleAvatar(child: Icon(Icons.groups)),
                  title: Text(team.name),
                  subtitle: Text(
                    team.id.length > 8 ? '${team.id.substring(0, 8)}...' : team.id,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: ref.watch(sessionsByTeamProvider(team.id)).when(
                            data: (sessions) {
                              if (sessions.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'No sessions for this team.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: sessions
                                    .map(
                                      (s) => ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        leading: Icon(
                                          s.success ? Icons.check_circle : Icons.schedule,
                                          color: s.success ? Colors.green : null,
                                          size: 20,
                                        ),
                                        title: Text(
                                          'Session ${s.id.substring(0, 8)}...',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        subtitle: Text(
                                          DateFormat.yMd().add_Hm().format(s.startedAt),
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                        trailing: s.completedAt != null
                                            ? Text(
                                                '${s.elapsedSeconds ?? 0}s',
                                                style: Theme.of(context).textTheme.bodySmall,
                                              )
                                            : const Text('In progress'),
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            error: (e, _) => Text('Error: $e'),
                          ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTeamDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateTeamDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Team'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Team name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.of(ctx).pop();
              final repo = ref.read(teamRepositoryProvider);
              final team = Team(
                id: const Uuid().v4(),
                name: name,
                createdAt: DateTime.now(),
              );
              await repo.createTeam(team);
              ref.invalidate(teamsListProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Team created')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
