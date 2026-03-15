import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../data/models/mission.dart';
import '../providers/missions_provider.dart';
import 'mission_builder_screen.dart';
import 'mission_detail_screen.dart';

/// Missions list: create, edit, delete missions; navigate to details and builder.
class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(missionsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openCreateMission(context, ref),
          ),
        ],
      ),
      body: missionsAsync.when(
        data: (missions) {
          if (missions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.explore_off, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  const Text('No missions yet'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _openCreateMission(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Mission'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: missions.length,
            itemBuilder: (context, index) {
              final mission = missions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.flag),
                  ),
                  title: Text(
                    mission.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    mission.description.isEmpty
                        ? 'No description'
                        : mission.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MissionBuilderScreen(
                              missionId: mission.id,
                              mission: mission,
                            ),
                          ),
                        );
                      } else if (value == 'delete') {
                        _confirmDelete(context, ref, mission);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MissionDetailScreen(missionId: mission.id),
                    ),
                  ),
                  onLongPress: () => _confirmDelete(context, ref, mission),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateMission(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openCreateMission(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MissionBuilderScreen(),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Mission mission) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Mission?'),
        content: Text(
          'Delete "${mission.title}"? This will also remove all steps and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((ok) async {
      if (ok == true && context.mounted) {
        await ref.read(missionRepositoryProvider).deleteMission(mission.id);
        ref.invalidate(missionsListProvider);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mission deleted')));
      }
    });
  }
}
