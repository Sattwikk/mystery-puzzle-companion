import 'package:equatable/equatable.dart';

/// Team entity: a group that can play missions and appear on the leaderboard.
class Team extends Equatable {
  const Team({
    required this.id,
    required this.name,
    this.createdAt,
  });

  final String id;
  final String name;
  final DateTime? createdAt;

  Team copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, name, createdAt];
}
