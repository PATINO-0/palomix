import '../../data/models/movie_model.dart';
import '../../data/services/tmdb_service.dart';
import '../../data/services/ai_service.dart';

// Repositorio que combina servicios TMDB y AI
class MovieRepository {
  final TmdbService _tmdbService;
  final AiService _aiService;
  
  MovieRepository({
    TmdbService? tmdbService,
    AiService? aiService,
  })  : _tmdbService = tmdbService ?? TmdbService(),
        _aiService = aiService ?? AiService();
  
  // Buscar películas con análisis de IA
  Future<List<MovieModel>> searchMovies(String query) async {
    try {
      return await _tmdbService.searchMovies(query);
    } catch (e) {
      rethrow;
    }
  }
  
  // Obtener detalles completos con resumen generado por IA
  Future<Map<String, dynamic>> getMovieDetailsWithAiSummary(int movieId) async {
    try {
      final movie = await _tmdbService.getMovieDetails(movieId);
      final similar = await _tmdbService.getSimilarMovies(movieId);
      final recommendations = await _tmdbService.getRecommendations(movieId);
      
      // Generar resumen con IA
      String aiSummary = '';
      try {
        aiSummary = await _aiService.generateMovieSummary(
          movie.title,
          movie.overview,
        );
      } catch (e) {
        // Si falla la IA, usar el overview original
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
  
  // Obtener recomendaciones personalizadas
  Future<Map<String, dynamic>> getPersonalizedRecommendations(
    List<String> favoriteMovies,
  ) async {
    try {
      // Obtener películas populares como base
      final popularMovies = await _tmdbService.getPopularMovies();
      
      // Generar recomendaciones con IA si hay favoritos
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
}
