import 'package:equatable/equatable.dart';

/// A story chapter unlocked per team as they complete missions.
class StoryChapter extends Equatable {
  const StoryChapter({
    required this.id,
    required this.chapterIndex,
    required this.title,
    required this.description,
    this.unlockedAt,
    required this.teamId,
  });

  final String id;
  final int chapterIndex;
  final String title;
  final String description;
  final DateTime? unlockedAt;
  final String teamId;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapter_index': chapterIndex,
      'title': title,
      'description': description,
      'unlocked_at': unlockedAt?.toIso8601String(),
      'team_id': teamId,
    };
  }

  factory StoryChapter.fromMap(Map<String, dynamic> map) {
    return StoryChapter(
      id: map['id'] as String,
      chapterIndex: map['chapter_index'] as int,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      unlockedAt: map['unlocked_at'] != null
          ? DateTime.tryParse(map['unlocked_at'] as String)
          : null,
      teamId: map['team_id'] as String,
    );
  }

  @override
  List<Object?> get props => [id, chapterIndex, title, description, unlockedAt, teamId];
}

