import 'package:equatable/equatable.dart';
import '../../../data/models/movie_model.dart';
import '../../../data/models/favorite_model.dart';

// Estados relacionados con películas
abstract class MovieState extends Equatable {
  const MovieState();
  
  @override
  List<Object?> get props => [];
}

// Estado inicial
class MovieInitial extends MovieState {}

// Cargando
class MovieLoading extends MovieState {}

// Resultados de búsqueda
class MovieSearchSuccess extends MovieState {
  final List<MovieModel> movies;
  
  const MovieSearchSuccess(this.movies);
  
  @override
  List<Object?> get props => [movies];
}

// Detalles de película cargados
class MovieDetailsSuccess extends MovieState {
  final MovieModel movie;
  final String aiSummary;
  final List<MovieModel> similarMovies;
  final List<MovieModel> recommendations;
  
  const MovieDetailsSuccess({
    required this.movie,
    required this.aiSummary,
    required this.similarMovies,
    required this.recommendations,
  });
  
  @override
  List<Object?> get props => [movie, aiSummary, similarMovies, recommendations];
}

// Recomendaciones personalizadas
class PersonalizedRecommendationsSuccess extends MovieState {
  final List<MovieModel> movies;
  final String aiRecommendations;
  
  const PersonalizedRecommendationsSuccess({
    required this.movies,
    required this.aiRecommendations,
  });
  
  @override
  List<Object?> get props => [movies, aiRecommendations];
}

// Favoritos cargados
class FavoritesLoadedSuccess extends MovieState {
  final List<FavoriteModel> favorites;
  
  const FavoritesLoadedSuccess(this.favorites);
  
  @override
  List<Object?> get props => [favorites];
}

// Película agregada a favoritos
class AddedToFavoritesSuccess extends MovieState {}

// Película eliminada de favoritos
class RemovedFromFavoritesSuccess extends MovieState {}

// Películas trending cargadas
class TrendingMoviesSuccess extends MovieState {
  final List<MovieModel> movies;
  
  const TrendingMoviesSuccess(this.movies);
  
  @override
  List<Object?> get props => [movies];
}

// Películas mejor valoradas cargadas
class TopRatedMoviesSuccess extends MovieState {
  final List<MovieModel> movies;
  
  const TopRatedMoviesSuccess(this.movies);
  
  @override
  List<Object?> get props => [movies];
}

// Películas por género cargadas
class MoviesByGenreSuccess extends MovieState {
  final List<MovieModel> movies;
  final String genreName;
  final int genreId;
  final int currentPage;
  final bool isLoadingMore;
  final bool hasMore;

  const MoviesByGenreSuccess({
    required this.movies,
    required this.genreName,
    required this.genreId,
    required this.currentPage,
    this.isLoadingMore = false,
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [movies, genreName, genreId, currentPage, isLoadingMore, hasMore];
}

// Contenido completo de explorar cargado
class ExploreContentSuccess extends MovieState {
  final List<MovieModel> trendingMovies;
  final List<MovieModel> topRatedMovies;
  final List<MovieModel> personalizedMovies;
  final String? aiRecommendations;
  final Map<String, List<MovieModel>> genreMovies;
  
  const ExploreContentSuccess({
    required this.trendingMovies,
    required this.topRatedMovies,
    required this.personalizedMovies,
    this.aiRecommendations,
    required this.genreMovies,
  });
  
  @override
  List<Object?> get props => [
    trendingMovies,
    topRatedMovies,
    personalizedMovies,
    aiRecommendations,
    genreMovies,
  ];
}

// Error
class MovieError extends MovieState {
  final String message;
  
  const MovieError(this.message);
  
  @override
  List<Object?> get props => [message];
}
