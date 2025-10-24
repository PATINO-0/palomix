import 'package:equatable/equatable.dart';

// Modelo para películas favoritas del usuario
class FavoriteModel extends Equatable {
  final String id;
  final String userId;
  final int movieId;
  final String movieTitle;
  final String? posterPath;
  final DateTime createdAt;
  
  const FavoriteModel({
    required this.id,
    required this.userId,
    required this.movieId,
    required this.movieTitle,
    this.posterPath,
    required this.createdAt,
  });
  
  // Conversión desde JSON de Supabase
  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      movieId: json['movie_id'] ?? 0,
      movieTitle: json['movie_title'] ?? '',
      posterPath: json['poster_path'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  // Conversión a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'movie_id': movieId,
      'movie_title': movieTitle,
      'poster_path': posterPath,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  @override
  List<Object?> get props => [
        id,
        userId,
        movieId,
        movieTitle,
        posterPath,
        createdAt,
      ];
}
