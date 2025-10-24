import 'package:equatable/equatable.dart';

// Modelo para películas obtenidas de TMDB
class MovieModel extends Equatable {
  final int id;
  final String title;
  final String? originalTitle;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final String? releaseDate;
  final List<int> genreIds;
  final List<String>? genres;
  final double popularity;
  final bool isReleased;
  final String? runtime;
  final List<CastMember>? cast;
  
  const MovieModel({
    required this.id,
    required this.title,
    this.originalTitle,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    this.releaseDate,
    required this.genreIds,
    this.genres,
    required this.popularity,
    required this.isReleased,
    this.runtime,
    this.cast,
  });
  
  // Conversión desde JSON de TMDB
  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      originalTitle: json['original_title'],
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      releaseDate: json['release_date'],
      genreIds: List<int>.from(json['genre_ids'] ?? []),
      genres: json['genres'] != null 
          ? List<String>.from(json['genres'].map((g) => g['name']))
          : null,
      popularity: (json['popularity'] ?? 0).toDouble(),
      isReleased: _checkIfReleased(json['release_date']),
      runtime: json['runtime']?.toString(),
      cast: json['cast'] != null
          ? List<CastMember>.from(
              json['cast'].map((c) => CastMember.fromJson(c)))
          : null,
    );
  }
  
  // Verificar si la película ya se estrenó
  static bool _checkIfReleased(String? releaseDate) {
    if (releaseDate == null || releaseDate.isEmpty) return false;
    try {
      final date = DateTime.parse(releaseDate);
      return date.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }
  
  // Obtener URL completa del poster
  String? get fullPosterUrl {
    if (posterPath == null) return null;
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }
  
  // Obtener URL completa del backdrop
  String? get fullBackdropUrl {
    if (backdropPath == null) return null;
    return 'https://image.tmdb.org/t/p/original$backdropPath';
  }
  
  @override
  List<Object?> get props => [
        id,
        title,
        originalTitle,
        overview,
        posterPath,
        backdropPath,
        voteAverage,
        voteCount,
        releaseDate,
        genreIds,
        genres,
        popularity,
        isReleased,
        runtime,
        cast,
      ];
}

// Modelo para miembros del reparto
class CastMember extends Equatable {
  final int id;
  final String name;
  final String character;
  final String? profilePath;
  
  const CastMember({
    required this.id,
    required this.name,
    required this.character,
    this.profilePath,
  });
  
  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      character: json['character'] ?? '',
      profilePath: json['profile_path'],
    );
  }
  
  String? get fullProfileUrl {
    if (profilePath == null) return null;
    return 'https://image.tmdb.org/t/p/w200$profilePath';
  }
  
  @override
  List<Object?> get props => [id, name, character, profilePath];
}
