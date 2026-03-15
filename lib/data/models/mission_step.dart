import 'package:equatable/equatable.dart';

/// A single step within a mission. Can have an optional time limit (seconds).
class MissionStep extends Equatable {
  const MissionStep({
    required this.id,
    required this.missionId,
    required this.title,
    required this.orderIndex,
    this.description,
    this.timeLimitSeconds,
    this.clueText,
  });

  final String id;
  final String missionId;
  final String title;
  final int orderIndex;
  final String? description;
  final int? timeLimitSeconds;
  final String? clueText;

  MissionStep copyWith({
    String? id,
    String? missionId,
    String? title,
    int? orderIndex,
    String? description,
    int? timeLimitSeconds,
    String? clueText,
  }) {
    return MissionStep(
      id: id ?? this.id,
      missionId: missionId ?? this.missionId,
      title: title ?? this.title,
      orderIndex: orderIndex ?? this.orderIndex,
      description: description ?? this.description,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      clueText: clueText ?? this.clueText,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mission_id': missionId,
      'title': title,
      'order_index': orderIndex,
      'description': description,
      'time_limit_seconds': timeLimitSeconds,
      'clue_text': clueText,
    };
  }

  factory MissionStep.fromMap(Map<String, dynamic> map) {
    return MissionStep(
      id: map['id'] as String,
      missionId: map['mission_id'] as String,
      title: map['title'] as String,
      orderIndex: map['order_index'] as int,
      description: map['description'] as String?,
      timeLimitSeconds: map['time_limit_seconds'] as int?,
      clueText: map['clue_text'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [id, missionId, title, orderIndex, description, timeLimitSeconds, clueText];
}
