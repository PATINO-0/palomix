import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/movie_repository.dart';
import '../../../data/services/supabase_service.dart';
import 'movie_event.dart';
import 'movie_state.dart';
import '../../../data/models/movie_model.dart';

// BLoC para manejar operaciones con películas
class MovieBloc extends Bloc<MovieEvent, MovieState> {
  final MovieRepository _movieRepository;
  bool _isLoadingMoreGenre = false;
  
  MovieBloc({MovieRepository? movieRepository})
      : _movieRepository = movieRepository ?? MovieRepository(),
        super(MovieInitial()) {
    on<MovieSearchRequested>(_onSearchRequested);
    on<MovieDetailsRequested>(_onDetailsRequested);
    on<PersonalizedRecommendationsRequested>(_onPersonalizedRecommendationsRequested);
    on<AddToFavoritesRequested>(_onAddToFavoritesRequested);
    on<RemoveFromFavoritesRequested>(_onRemoveFromFavoritesRequested);
    on<LoadFavoritesRequested>(_onLoadFavoritesRequested);
    on<TrendingMoviesRequested>(_onTrendingMoviesRequested);
    on<TopRatedMoviesRequested>(_onTopRatedMoviesRequested);
    on<MoviesByGenreRequested>(_onMoviesByGenreRequested);
    on<MoviesByGenreLoadMore>(_onMoviesByGenreLoadMore);
    on<ExploreContentRequested>(_onExploreContentRequested);
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
      final msg = e.toString();
      if (msg.contains('TMDB: API key/token inválido')) {
        emit(MovieError('Configuración de TMDB inválida. Revisa tu API key o token.'));
      } else if (msg.contains('TMDB API key/token no configurado')) {
        emit(MovieError('TMDB no configurado. Ejecuta la app con --dart-define para la clave/token.'));
      } else {
        emit(MovieError('Error al buscar películas: $msg'));
      }
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
      final msg = e.toString();
      if (msg.contains('TMDB: API key/token inválido')) {
        emit(MovieError('Configuración de TMDB inválida. Revisa tu API key o token.'));
      } else if (msg.contains('TMDB API key/token no configurado')) {
        emit(MovieError('TMDB no configurado. Ejecuta la app con --dart-define para la clave/token.'));
      } else {
        emit(MovieError('Error al cargar detalles: $msg'));
      }
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
      final msg = e.toString();
      if (msg.contains('TMDB: API key/token inválido')) {
        emit(MovieError('Configuración de TMDB inválida. Revisa tu API key o token.'));
      } else if (msg.contains('TMDB API key/token no configurado')) {
        emit(MovieError('TMDB no configurado. Ejecuta la app con --dart-define para la clave/token.'));
      } else {
        emit(MovieError('Error al cargar recomendaciones: $msg'));
      }
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

  Future<void> _onTrendingMoviesRequested(
    TrendingMoviesRequested event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieLoading());
    try {
      final movies = await _movieRepository.getTrendingMovies();
      emit(TrendingMoviesSuccess(movies));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('TMDB: API key/token inválido')) {
        emit(MovieError('Configuración de TMDB inválida. Revisa tu API key o token.'));
      } else if (msg.contains('TMDB API key/token no configurado')) {
        emit(MovieError('TMDB no configurado. Ejecuta la app con --dart-define para la clave/token.'));
      } else {
        emit(MovieError('Error al cargar películas trending: $msg'));
      }
    }
  }

  Future<void> _onTopRatedMoviesRequested(
    TopRatedMoviesRequested event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieLoading());
    try {
      final movies = await _movieRepository.getTopRatedMovies();
      emit(TopRatedMoviesSuccess(movies));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('TMDB: API key/token inválido')) {
        emit(MovieError('Configuración de TMDB inválida. Revisa tu API key o token.'));
      } else if (msg.contains('TMDB API key/token no configurado')) {
        emit(MovieError('TMDB no configurado. Ejecuta la app con --dart-define para la clave/token.'));
      } else {
        emit(MovieError('Error al cargar películas mejor valoradas: $msg'));
      }
    }
  }

  Future<void> _onMoviesByGenreRequested(
    MoviesByGenreRequested event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieLoading());
    try {
      final movies = await _movieRepository.getMoviesByGenre(event.genreId, page: 1);
      final hasMore = movies.length == 20;
      emit(MoviesByGenreSuccess(
        movies: movies,
        genreName: event.genreName,
        genreId: event.genreId,
        currentPage: 1,
        isLoadingMore: false,
        hasMore: hasMore,
      ));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('TMDB: API key/token inválido')) {
        emit(MovieError('Configuración de TMDB inválida. Revisa tu API key o token.'));
      } else if (msg.contains('TMDB API key/token no configurado')) {
        emit(MovieError('TMDB no configurado. Ejecuta la app con --dart-define para la clave/token.'));
      } else {
        emit(MovieError('Error al cargar películas de ${event.genreName}: $msg'));
      }
    }
  }

  Future<void> _onMoviesByGenreLoadMore(
    MoviesByGenreLoadMore event,
    Emitter<MovieState> emit,
  ) async {
    if (_isLoadingMoreGenre) return;
    final currentState = state;
    if (currentState is! MoviesByGenreSuccess) return;
    if (!currentState.hasMore) return;
    _isLoadingMoreGenre = true;
    emit(MoviesByGenreSuccess(
      movies: currentState.movies,
      genreName: currentState.genreName,
      genreId: currentState.genreId,
      currentPage: currentState.currentPage,
      isLoadingMore: true,
      hasMore: currentState.hasMore,
    ));
    try {
      final more = await _movieRepository.getMoviesByGenre(event.genreId, page: event.nextPage);
      final existingIds = currentState.movies.map((m) => m.id).toSet();
      final filtered = more.where((m) => !existingIds.contains(m.id)).toList();
      final combined = List<MovieModel>.from(currentState.movies)..addAll(filtered);
      final hasMoreNext = more.length == 20;
      emit(MoviesByGenreSuccess(
        movies: combined,
        genreName: event.genreName,
        genreId: event.genreId,
        currentPage: event.nextPage,
        isLoadingMore: false,
        hasMore: hasMoreNext,
      ));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('TMDB: API key/token inválido')) {
        emit(MovieError('Configuración de TMDB inválida. Revisa tu API key o token.'));
      } else if (msg.contains('TMDB API key/token no configurado')) {
        emit(MovieError('TMDB no configurado. Ejecuta la app con --dart-define para la clave/token.'));
      } else {
        emit(MovieError('Error al cargar más películas de ${event.genreName}: $msg'));
      }
    } finally {
      _isLoadingMoreGenre = false;
    }
  }

  Future<void> _onExploreContentRequested(
    ExploreContentRequested event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieLoading());
    try {
      // Cargar contenido en paralelo para mejor rendimiento
      final futures = await Future.wait([
        _movieRepository.getTrendingMovies(),
        _movieRepository.getTopRatedMovies(),
        _getPersonalizedMoviesForExplore(),
      ]);

      final trendingMovies = futures[0] as List;
      final topRatedMovies = futures[1] as List;
      final personalizedResult = futures[2] as Map<String, dynamic>;

      // Cargar algunas películas por género popular
      final genreMovies = <String, List>{}; 
      final popularGenres = [
        {'id': 28, 'name': 'Acción'},
        {'id': 35, 'name': 'Comedia'},
        {'id': 18, 'name': 'Drama'},
        {'id': 27, 'name': 'Terror'},
      ];

      for (final genre in popularGenres) {
        try {
          final movies = await _movieRepository.getMoviesByGenre(genre['id'] as int);
          genreMovies[genre['name'] as String] = movies.take(10).toList();
        } catch (e) {
          // Si falla un género, continúa con los otros
          genreMovies[genre['name'] as String] = [];
        }
      }

      emit(ExploreContentSuccess(
        trendingMovies: trendingMovies.cast(),
        topRatedMovies: topRatedMovies.cast(),
        personalizedMovies: personalizedResult['movies'] ?? [],
        aiRecommendations: personalizedResult['aiRecommendations'],
        genreMovies: genreMovies.cast(),
      ));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('TMDB: API key/token inválido')) {
        emit(MovieError('Configuración de TMDB inválida. Revisa tu API key o token.'));
      } else if (msg.contains('TMDB API key/token no configurado')) {
        emit(MovieError('TMDB no configurado. Ejecuta la app con --dart-define para la clave/token.'));
      } else {
        emit(MovieError('Error al cargar contenido de explorar: $msg'));
      }
    }
  }

  Future<Map<String, dynamic>> _getPersonalizedMoviesForExplore() async {
    try {
      final favorites = await SupabaseService.getFavorites();
      final favoriteMovies = favorites.map((f) => f.movieTitle).toList();
      return await _movieRepository.getPersonalizedRecommendations(favoriteMovies);
    } catch (e) {
      // Si no hay favoritos o falla, devolver vacío
      return {'movies': [], 'aiRecommendations': null};
    }
  }
}
