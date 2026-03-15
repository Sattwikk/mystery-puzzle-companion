import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/di/providers.dart';
import '../../core/services/notification_service.dart';
import '../../data/models/game_session.dart';
import '../providers/missions_provider.dart';
import '../providers/sessions_provider.dart';
import '../providers/teams_provider.dart';

/// Play a mission: select mission (if not provided), select team, run steps.
class MissionPlayerScreen extends ConsumerStatefulWidget {
  const MissionPlayerScreen({super.key, this.missionId});

  final String? missionId;

  @override
  ConsumerState<MissionPlayerScreen> createState() => _MissionPlayerScreenState();
}

class _MissionPlayerScreenState extends ConsumerState<MissionPlayerScreen> {
  String? _selectedMissionId;
  GameSession? _session;

  String? get _missionId => widget.missionId ?? _selectedMissionId;

  Future<void> _startSession(String teamId) async {
    final missionId = _missionId!;
    final repo = ref.read(sessionRepositoryProvider);
    final session = GameSession(
      id: const Uuid().v4(),
      missionId: missionId,
      teamId: teamId,
      startedAt: DateTime.now(),
      currentStepIndex: 0,
    );
    await repo.createSession(session);
    if (mounted) {
      setState(() => _session = session);
      ref.invalidate(sessionsListProvider);
    }
  }

  Future<void> _completeSession() async {
    if (_session == null) return;
    final repo = ref.read(sessionRepositoryProvider);
    final updated = _session!.copyWith(
      completedAt: DateTime.now(),
      success: true,
    );
    await repo.updateSession(updated);
    final mission = await ref.read(missionDetailProvider(_session!.missionId).future);
    if (mission != null) {
      await NotificationService.instance.showMissionCompleted(mission.title);
    }
    if (mounted) {
      ref.invalidate(sessionsListProvider);
      ref.invalidate(leaderboardProvider);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mission completed!')));
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _goToNextStep() async {
    if (_session == null) return;
    final steps = await ref.read(missionStepsProvider(_session!.missionId).future);
    final nextIndex = _session!.currentStepIndex + 1;
    if (nextIndex >= steps.length) {
      await _completeSession();
      return;
    }
    final repo = ref.read(sessionRepositoryProvider);
    final updated = _session!.copyWith(currentStepIndex: nextIndex);
    await repo.updateSession(updated);
    if (mounted) {
      setState(() => _session = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session != null) {
      return _PlayView(
        session: _session!,
        onNextStep: _goToNextStep,
        onComplete: _completeSession,
      );
    }

    if (_missionId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Play a Mission')),
        body: ref.watch(missionsListProvider).when(
              data: (missions) {
                if (missions.isEmpty) {
                  return const Center(
                      child: Text('No missions. Create one first.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: missions.length,
                  itemBuilder: (_, i) {
                    final m = missions[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                            child: Icon(Icons.play_arrow)),
                        title: Text(m.title),
                        onTap: () => setState(
                            () => _selectedMissionId = m.id),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Select Team')),
      body: ref.watch(teamsListProvider).when(
            data: (teams) {
              if (teams.isEmpty) {
                return const Center(
                    child: Text('No teams. Create a team first from Teams.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: teams.length,
                itemBuilder: (_, i) {
                  final t = teams[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                          child: Icon(Icons.groups)),
                      title: Text(t.name),
                      onTap: () => _startSession(t.id),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
    );
  }
}

class _PlayView extends ConsumerWidget {
  const _PlayView({
    required this.session,
    required this.onNextStep,
    required this.onComplete,
  });

  final GameSession session;
  final VoidCallback onNextStep;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepsAsync = ref.watch(missionStepsProvider(session.missionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Mission')),
      body: stepsAsync.when(
        data: (steps) {
          if (steps.isEmpty) {
            return const Center(child: Text('No steps in this mission.'));
          }
          final index = session.currentStepIndex.clamp(0, steps.length - 1);
          final step = steps[index];
          final isLast = index >= steps.length - 1;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Step ${index + 1} of ${steps.length}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _StepCardWithAnimation(
                    key: ValueKey(index),
                    stepTitle: step.title,
                    timeLimitSeconds: step.timeLimitSeconds,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: isLast ? onComplete : onNextStep,
                  icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
                  label: Text(isLast ? 'Complete Mission' : 'Next Step'),
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

/// Step card with explicit fade-in animation (graduate: custom animations).
class _StepCardWithAnimation extends StatefulWidget {
  const _StepCardWithAnimation({
    super.key,
    required this.stepTitle,
    this.timeLimitSeconds,
  });

  final String stepTitle;
  final int? timeLimitSeconds;

  @override
  State<_StepCardWithAnimation> createState() => _StepCardWithAnimationState();
}

class _StepCardWithAnimationState extends State<_StepCardWithAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.stepTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (widget.timeLimitSeconds != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Time limit: ${widget.timeLimitSeconds}s',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
