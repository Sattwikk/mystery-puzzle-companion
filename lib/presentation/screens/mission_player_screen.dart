import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/di/providers.dart';
import '../../core/services/notification_service.dart';
import '../../data/models/game_session.dart';
import '../../data/models/mission_step.dart';
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
  final Set<String> _discoveredStepIds = {};

  String? get _missionId => widget.missionId ?? _selectedMissionId;

  Future<void> _hydrateDiscoveredClues(String sessionId) async {
    final repo = ref.read(sessionRepositoryProvider);
    final stepIds = await repo.getDiscoveredStepIds(sessionId);
    if (!mounted) return;
    setState(() {
      _discoveredStepIds
        ..clear()
        ..addAll(stepIds);
    });
  }

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
    await _hydrateDiscoveredClues(session.id);
  }

  Future<void> _useHintForStep(MissionStep step) async {
    if (_session == null) return;
    final clue = step.clueText?.trim();
    if (clue == null || clue.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No clue available for this step.')),
        );
      }
      return;
    }
    if (_discoveredStepIds.contains(step.id)) return;

    final repo = ref.read(sessionRepositoryProvider);
    final ok = await repo.recordClueUsage(
      sessionId: _session!.id,
      stepId: step.id,
      clueText: clue,
    );
    if (!ok) return;

    if (mounted) {
      setState(() {
        _discoveredStepIds.add(step.id);
        _session = _session!.copyWith(hintsUsed: _session!.hintsUsed + 1);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clue unlocked!')),
      );
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
        discoveredStepIds: _discoveredStepIds,
        hintsUsed: _session!.hintsUsed,
        onNextStep: _goToNextStep,
        onComplete: _completeSession,
        onUseHintForStep: _useHintForStep,
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
    required this.discoveredStepIds,
    required this.hintsUsed,
    required this.onUseHintForStep,
  });

  final GameSession session;
  final VoidCallback onNextStep;
  final VoidCallback onComplete;
  final Set<String> discoveredStepIds;
  final int hintsUsed;
  final Future<void> Function(MissionStep step) onUseHintForStep;

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
                    stepDescription: step.description,
                    timeLimitSeconds: step.timeLimitSeconds,
                    clueText: step.clueText,
                    isClueDiscovered: discoveredStepIds.contains(step.id),
                    hintsUsed: hintsUsed,
                    onUseHintForStep: () => onUseHintForStep(step),
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
    this.stepDescription,
    this.timeLimitSeconds,
    this.clueText,
    required this.isClueDiscovered,
    required this.hintsUsed,
    this.onUseHintForStep,
  });

  final String stepTitle;
  final String? stepDescription;
  final int? timeLimitSeconds;
  final String? clueText;
  final bool isClueDiscovered;
  final int hintsUsed;
  final Future<void> Function()? onUseHintForStep;

  @override
  State<_StepCardWithAnimation> createState() => _StepCardWithAnimationState();
}

class _StepCardWithAnimationState extends State<_StepCardWithAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  Timer? _timer;
  int? _remaining;
  bool _hintBusy = false;

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
    if (widget.timeLimitSeconds != null) {
      _remaining = widget.timeLimitSeconds;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_remaining != null && _remaining! > 0) {
            _remaining = _remaining! - 1;
          }
          if (_remaining != null && _remaining == 0) {
            timer.cancel();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clue = widget.clueText?.trim();
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
              if (widget.stepDescription != null &&
                  widget.stepDescription!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  widget.stepDescription!.trim(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (widget.timeLimitSeconds != null) ...[
                const SizedBox(height: 8),
                Text(
                  _remaining != null && _remaining! > 0
                      ? 'Time left: ${_remaining}s'
                      : 'Time is up',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _remaining == 0
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: (_remaining != null && widget.timeLimitSeconds != null)
                      ? _remaining!.clamp(0, widget.timeLimitSeconds!) /
                          widget.timeLimitSeconds!
                      : 0,
                ),
              ],
              if (clue != null && clue.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(
                      label: Text('Hints used: ${widget.hintsUsed}'),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    if (!widget.isClueDiscovered)
                      OutlinedButton.icon(
                        onPressed: _hintBusy || widget.onUseHintForStep == null
                            ? null
                            : () async {
                                setState(() => _hintBusy = true);
                                try {
                                  await widget.onUseHintForStep!();
                                } finally {
                                  if (mounted) setState(() => _hintBusy = false);
                                }
                              },
                        icon: const Icon(Icons.lightbulb_outline),
                        label: const Text('Use Hint'),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: widget.isClueDiscovered
                      ? Container(
                          key: const ValueKey('clue_on'),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).colorScheme.secondary
                                .withValues(alpha: 0.14),
                          ),
                          child: Text(
                            clue,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : const SizedBox.shrink(
                          key: ValueKey('clue_off'),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
