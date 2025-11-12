import '../../data/models/movie_model.dart';
import '../../data/services/tmdb_service.dart';
import '../../data/services/ai_service.dart';


class MovieRepository {
  final TmdbService _tmdbService;
  final AiService _aiService;
  
  MovieRepository({
    TmdbService? tmdbService,
    AiService? aiService,
  })  : _tmdbService = tmdbService ?? TmdbService(),
        _aiService = aiService ?? AiService();
  
  
  Future<List<MovieModel>> searchMovies(String query) async {
    try {
      return await _tmdbService.searchMovies(query);
    } catch (e) {
      rethrow;
    }
  }
  
  
  Future<Map<String, dynamic>> getMovieDetailsWithAiSummary(int movieId) async {
    try {
      final movie = await _tmdbService.getMovieDetails(movieId);
      final similar = await _tmdbService.getSimilarMovies(movieId);
      final recommendations = await _tmdbService.getRecommendations(movieId);
      
      
      String aiSummary = '';
      try {
        aiSummary = await _aiService.generateMovieSummary(
          movie.title,
          movie.overview,
        );
      } catch (e) {
        
        aiSummary = movie.overview;
      }
      
      return {
        'movie': movie,
        'aiSummary': aiSummary,
        'similar': similar,
        'recommendations': recommendations,
      };
    } catch (e) {
      rethrow;
    }
  }
  
  
  Future<Map<String, dynamic>> getPersonalizedRecommendations(
    List<String> favoriteMovies,
  ) async {
    try {
      
      final popularMovies = await _tmdbService.getPopularMovies();
      
      
      String aiRecommendations = '';
      if (favoriteMovies.isNotEmpty) {
        try {
          aiRecommendations = await _aiService.generatePersonalizedRecommendations(
            favoriteMovies,
          );
        } catch (e) {
          aiRecommendations = 'Basándome en tus favoritos, estas películas podrían interesarte.';
        }
      }
      
      return {
        'movies': popularMovies,
        'aiRecommendations': aiRecommendations,
      };
    } catch (e) {
      rethrow;
    }
  }

  
  Future<List<MovieModel>> getTrendingMovies() async {
    try {
      return await _tmdbService.getTrendingMovies();
    } catch (e) {
      rethrow;
    }
  }

  
  Future<List<MovieModel>> getTopRatedMovies() async {
    try {
      return await _tmdbService.getTopRatedMovies();
    } catch (e) {
      rethrow;
    }
  }

  
  Future<List<MovieModel>> getMoviesByGenre(int genreId, {int page = 1}) async {
    try {
      return await _tmdbService.getMoviesByGenre(genreId, page: page);
    } catch (e) {
      rethrow;
    }
  }
}
