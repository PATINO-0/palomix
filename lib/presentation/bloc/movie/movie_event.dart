import 'package:equatable/equatable.dart';

// Eventos relacionados con películas
abstract class MovieEvent extends Equatable {
  const MovieEvent();
  
  @override
  List<Object?> get props => [];
}

// Buscar películas
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

// Obtener recomendaciones personalizadas
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
