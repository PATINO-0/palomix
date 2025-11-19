class Movie {
  final int id;
  final String title;
  final String? overview;
  final String? posterPath;
  final String? releaseDate;

  Movie({
    required this.id,
    required this.title,
    this.overview,
    this.posterPath,
    this.releaseDate,
  });

  factory Movie.fromTmdbJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'] ?? json['name'] ?? 'Sin título',
      overview: json['overview'],
      posterPath: json['poster_path'],
      releaseDate: json['release_date'] ?? json['first_air_date'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'overview': overview,
        'poster_path': posterPath,
        'release_date': releaseDate,
      };
}
