import 'movie.dart';

class FavoriteMovie {
  final String id;
  final String userId;
  final Movie movie;
  final DateTime createdAt;

  FavoriteMovie({
    required this.id,
    required this.userId,
    required this.movie,
    required this.createdAt,
  });

  factory FavoriteMovie.fromJson(Map<String, dynamic> json) {
    return FavoriteMovie(
      id: json['id'],
      userId: json['user_id'],
      movie: Movie(
        id: json['tmdb_id'],
        title: json['title'],
        overview: json['overview'],
        posterPath: json['poster_path'],
      ),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
