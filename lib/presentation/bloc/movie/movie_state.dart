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

// Error
class MovieError extends MovieState {
  final String message;
  
  const MovieError(this.message);
  
  @override
  List<Object?> get props => [message];
}
