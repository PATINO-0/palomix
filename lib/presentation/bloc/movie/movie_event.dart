import 'package:equatable/equatable.dart';

// Eventos relacionados con películas
abstract class MovieEvent extends Equatable {
  const MovieEvent();
  
  @override
  List<Object?> get props => [];
}

class MovieSearchRequested extends MovieEvent {
  final String query;
  
  const MovieSearchRequested(this.query);
  
  @override
  List<Object?> get props => [query];
}

// Obtener detalles de película
class MovieDetailsRequested extends MovieEvent {
  final int movieId;
  
  const MovieDetailsRequested(this.movieId);
  
  @override
  List<Object?> get props => [movieId];
}

// Obtener recomendaciones personalizadas peliculas
class PersonalizedRecommendationsRequested extends MovieEvent {}

// Agregar a favoritos
class AddToFavoritesRequested extends MovieEvent {
  final int movieId;
  final String movieTitle;
  final String? posterPath;
  
  const AddToFavoritesRequested({
    required this.movieId,
    required this.movieTitle,
    this.posterPath,
  });
  
  @override
  List<Object?> get props => [movieId, movieTitle, posterPath];
}

// Eliminar de favoritos
class RemoveFromFavoritesRequested extends MovieEvent {
  final int movieId;
  
  const RemoveFromFavoritesRequested(this.movieId);
  
  @override
  List<Object?> get props => [movieId];
}

// Cargar favoritos
class LoadFavoritesRequested extends MovieEvent {}

// Cargar películas trending/tendencias
class TrendingMoviesRequested extends MovieEvent {}

// Cargar películas mejor valoradas
class TopRatedMoviesRequested extends MovieEvent {}

// Cargar películas por género
class MoviesByGenreRequested extends MovieEvent {
  final int genreId;
  final String genreName;
  const MoviesByGenreRequested({
    required this.genreId,
    required this.genreName,
  });
  @override
  List<Object?> get props => [genreId, genreName];
}

class MoviesByGenreLoadMore extends MovieEvent {
  final int genreId;
  final String genreName;
  final int nextPage;
  const MoviesByGenreLoadMore({
    required this.genreId,
    required this.genreName,
    required this.nextPage,
  });
  @override
  List<Object?> get props => [genreId, genreName, nextPage];
}
// Cargar contenido completo de explorar
class ExploreContentRequested extends MovieEvent {}
