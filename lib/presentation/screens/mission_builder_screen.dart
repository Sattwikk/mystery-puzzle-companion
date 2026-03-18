import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/di/providers.dart';
import '../../data/models/mission.dart';
import '../../data/models/mission_step.dart';
import '../providers/missions_provider.dart';

/// Create or edit a mission: title, description, and ordered steps.
class MissionBuilderScreen extends ConsumerStatefulWidget {
  const MissionBuilderScreen({super.key, this.missionId, this.mission});

  final String? missionId;
  final Mission? mission;

  @override
  ConsumerState<MissionBuilderScreen> createState() =>
      _MissionBuilderScreenState();
}

class _MissionBuilderScreenState extends ConsumerState<MissionBuilderScreen> {
  static const _uuid = Uuid();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final List<_StepEdit> _steps = [];

  bool get _isEdit => widget.missionId != null && widget.mission != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.mission?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.mission?.description ?? '');
    if (_isEdit) {
      ref.read(missionStepsProvider(widget.missionId!).future).then((steps) {
        if (mounted) {
          setState(() {
            _steps.addAll(
              steps.map((s) => _StepEdit(
                    id: s.id,
                    titleController: TextEditingController(text: s.title),
                    descriptionController:
                        TextEditingController(text: s.description ?? ''),
                    clueController:
                        TextEditingController(text: s.clueText ?? ''),
                    timeLimitSeconds: s.timeLimitSeconds,
                  )),
            );
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final s in _steps) {
      s.titleController.dispose();
      s.descriptionController.dispose();
      s.clueController.dispose();
    }
    super.dispose();
  }

  void _addStep() {
    setState(() {
      _steps.add(_StepEdit(
        id: _uuid.v4(),
        titleController: TextEditingController(),
        descriptionController: TextEditingController(),
        clueController: TextEditingController(),
        timeLimitSeconds: null,
      ));
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps[index].titleController.dispose();
      _steps[index].descriptionController.dispose();
      _steps[index].clueController.dispose();
      _steps.removeAt(index);
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a mission title')));
      return;
    }
    final repo = ref.read(missionRepositoryProvider);
    final now = DateTime.now();

    if (_isEdit) {
      final mission = widget.mission!.copyWith(
        title: title,
        description: _descriptionController.text.trim(),
        updatedAt: now,
      );
      await repo.updateMission(mission);
      await repo.deleteStepsByMissionId(widget.missionId!);
      for (var i = 0; i < _steps.length; i++) {
        final s = _steps[i];
        final step = MissionStep(
          id: s.id,
          missionId: widget.missionId!,
          title: s.titleController.text.trim().isEmpty ? 'Step ${i + 1}' : s.titleController.text.trim(),
          orderIndex: i,
          timeLimitSeconds: s.timeLimitSeconds,
          description: s.descriptionController.text.trim(),
          clueText: s.clueController.text.trim().isEmpty
              ? null
              : s.clueController.text.trim(),
        );
        await repo.addStep(step);
      }
      if (mounted) {
        ref.invalidate(missionsListProvider);
        ref.invalidate(missionDetailProvider(widget.missionId!));
        ref.invalidate(missionStepsProvider(widget.missionId!));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mission updated')));
        Navigator.of(context).pop();
      }
    } else {
      final missionId = _uuid.v4();
      final mission = Mission(
        id: missionId,
        title: title,
        description: _descriptionController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      await repo.createMission(mission);
      for (var i = 0; i < _steps.length; i++) {
        final s = _steps[i];
        final step = MissionStep(
          id: _uuid.v4(),
          missionId: missionId,
          title: s.titleController.text.trim().isEmpty ? 'Step ${i + 1}' : s.titleController.text.trim(),
          orderIndex: i,
          timeLimitSeconds: s.timeLimitSeconds,
          description: s.descriptionController.text.trim(),
          clueText: s.clueController.text.trim().isEmpty
              ? null
              : s.clueController.text.trim(),
        );
        await repo.addStep(step);
      }
      if (mounted) {
        ref.invalidate(missionsListProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mission created')));
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Mission' : 'New Mission'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Steps',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                FilledButton.icon(
                  onPressed: _addStep,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Step'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_steps.length, (i) {
              return _StepTile(
                index: i + 1,
                step: _steps[i],
                onRemove: () => _removeStep(i),
                onTimeLimitChanged: (v) {
                  setState(() => _steps[i].timeLimitSeconds = v);
                },
              );
            }),
            if (_steps.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No steps. Tap "Add Step" to add puzzle steps.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StepEdit {
  _StepEdit({
    required this.id,
    required this.titleController,
    required this.descriptionController,
    required this.clueController,
    this.timeLimitSeconds,
  });
  final String id;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController clueController;
  int? timeLimitSeconds;
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.index,
    required this.step,
    required this.onRemove,
    required this.onTimeLimitChanged,
  });

  final int index;
  final _StepEdit step;
  final VoidCallback onRemove;
  final void Function(int?) onTimeLimitChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text('$index'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: step.titleController,
                    decoration: InputDecoration(
                      labelText: 'Step $index title',
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: step.timeLimitSeconds,
              decoration: const InputDecoration(
                labelText: 'Time limit (seconds)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('No limit')),
                DropdownMenuItem(value: 60, child: Text('60 s')),
                DropdownMenuItem(value: 120, child: Text('2 min')),
                DropdownMenuItem(value: 300, child: Text('5 min')),
              ],
              onChanged: onTimeLimitChanged,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: step.descriptionController,
              decoration: const InputDecoration(
                labelText: 'Task / Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: step.clueController,
              decoration: const InputDecoration(
                labelText: 'Clue / Hint (optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }
}
