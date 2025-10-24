import 'package:equatable/equatable.dart';

// Modelo para listas de reproducción personalizadas
class PlaylistModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final List<int> movieIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const PlaylistModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.movieIds,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      movieIds: List<int>.from(json['movie_ids'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'movie_ids': movieIds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  // Crear copia con modificaciones
  PlaylistModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    List<int>? movieIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      movieIds: movieIds ?? this.movieIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        description,
        movieIds,
        createdAt,
        updatedAt,
      ];
}
