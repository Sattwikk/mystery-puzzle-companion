import 'package:equatable/equatable.dart';

/// Achievement/badge unlocked by the user (stored per team or global).
class Achievement extends Equatable {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.unlockedAt,
    this.teamId,
  });

  final String id;
  final String title;
  final String description;
  final DateTime? unlockedAt;
  final String? teamId;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'unlocked_at': unlockedAt?.toIso8601String(),
      'team_id': teamId,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      unlockedAt: map['unlocked_at'] != null
          ? DateTime.tryParse(map['unlocked_at'] as String)
          : null,
      teamId: map['team_id'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, title, description, unlockedAt, teamId];
}
