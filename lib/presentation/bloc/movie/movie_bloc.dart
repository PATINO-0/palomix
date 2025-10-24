import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/movie_repository.dart';
import '../../../data/services/supabase_service.dart';
import 'movie_event.dart';
import 'movie_state.dart';

// BLoC para manejar operaciones con películas
class MovieBloc extends Bloc<MovieEvent, MovieState> {
  final MovieRepository _movieRepository;
  
  MovieBloc({MovieRepository? movieRepository})
      : _movieRepository = movieRepository ?? MovieRepository(),
        super(MovieInitial()) {
    on<MovieSearchRequested>(_onSearchRequested);
    on<MovieDetailsRequested>(_onDetailsRequested);
    on<PersonalizedRecommendationsRequested>(_onPersonalizedRecommendationsRequested);
    on<AddToFavoritesRequested>(_onAddToFavoritesRequested);
    on<RemoveFromFavoritesRequested>(_onRemoveFromFavoritesRequested);
    on<LoadFavoritesRequested>(_onLoadFavoritesRequested);
  }
  
  Future<void> _onSearchRequested(
    MovieSearchRequested event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieLoading());
    try {
      final movies = await _movieRepository.searchMovies(event.query);
      emit(MovieSearchSuccess(movies));
    } catch (e) {
      emit(MovieError('Error al buscar películas: ${e.toString()}'));
    }
  }
  
  Future<void> _onDetailsRequested(
    MovieDetailsRequested event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieLoading());
    try {
      final result = await _movieRepository.getMovieDetailsWithAiSummary(event.movieId);
      emit(MovieDetailsSuccess(
        movie: result['movie'],
        aiSummary: result['aiSummary'],
        similarMovies: result['similar'],
        recommendations: result['recommendations'],
      ));
    } catch (e) {
      emit(MovieError('Error al cargar detalles: ${e.toString()}'));
    }
  }
  
  Future<void> _onPersonalizedRecommendationsRequested(
    PersonalizedRecommendationsRequested event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieLoading());
    try {
      // Obtener favoritos del usuario
      final favorites = await SupabaseService.getFavorites();
      final favoriteMovies = favorites.map((f) => f.movieTitle).toList();
      
      final result = await _movieRepository.getPersonalizedRecommendations(favoriteMovies);
      emit(PersonalizedRecommendationsSuccess(
        movies: result['movies'],
        aiRecommendations: result['aiRecommendations'],
      ));
    } catch (e) {
      emit(MovieError('Error al cargar recomendaciones: ${e.toString()}'));
    }
  }
  
  Future<void> _onAddToFavoritesRequested(
    AddToFavoritesRequested event,
    Emitter<MovieState> emit,
  ) async {
    try {
      await SupabaseService.addToFavorites(
        movieId: event.movieId,
        movieTitle: event.movieTitle,
        posterPath: event.posterPath,
      );
      emit(AddedToFavoritesSuccess());
    } catch (e) {
      emit(MovieError('Error al agregar a favoritos: ${e.toString()}'));
    }
  }
  
  Future<void> _onRemoveFromFavoritesRequested(
    RemoveFromFavoritesRequested event,
    Emitter<MovieState> emit,
  ) async {
    try {
      await SupabaseService.removeFromFavorites(event.movieId);
      emit(RemovedFromFavoritesSuccess());
    } catch (e) {
      emit(MovieError('Error al eliminar de favoritos: ${e.toString()}'));
    }
  }
  
  Future<void> _onLoadFavoritesRequested(
    LoadFavoritesRequested event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieLoading());
    try {
      final favorites = await SupabaseService.getFavorites();
      emit(FavoritesLoadedSuccess(favorites));
    } catch (e) {
      emit(MovieError('Error al cargar favoritos: ${e.toString()}'));
    }
  }
}
