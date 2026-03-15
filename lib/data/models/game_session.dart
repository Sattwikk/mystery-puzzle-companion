import 'package:equatable/equatable.dart';

/// A play session: one team playing one mission. Tracks completion and hints.
class GameSession extends Equatable {
  const GameSession({
    required this.id,
    required this.missionId,
    required this.teamId,
    required this.startedAt,
    this.completedAt,
    this.success = false,
    this.hintsUsed = 0,
    this.currentStepIndex = 0,
  });

  final String id;
  final String missionId;
  final String teamId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final bool success;
  final int hintsUsed;
  final int currentStepIndex;

  GameSession copyWith({
    String? id,
    String? missionId,
    String? teamId,
    DateTime? startedAt,
    DateTime? completedAt,
    bool? success,
    int? hintsUsed,
    int? currentStepIndex,
  }) {
    return GameSession(
      id: id ?? this.id,
      missionId: missionId ?? this.missionId,
      teamId: teamId ?? this.teamId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      success: success ?? this.success,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
    );
  }

  /// Elapsed time in seconds (from start to completion or now).
  int? get elapsedSeconds {
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt).inSeconds;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mission_id': missionId,
      'team_id': teamId,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'success': success ? 1 : 0,
      'hints_used': hintsUsed,
      'current_step_index': currentStepIndex,
    };
  }

  factory GameSession.fromMap(Map<String, dynamic> map) {
    return GameSession(
      id: map['id'] as String,
      missionId: map['mission_id'] as String,
      teamId: map['team_id'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'] as String)
          : null,
      success: (map['success'] as int?) == 1,
      hintsUsed: map['hints_used'] as int? ?? 0,
      currentStepIndex: map['current_step_index'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        missionId,
        teamId,
        startedAt,
        completedAt,
        success,
        hintsUsed,
        currentStepIndex,
      ];
}
