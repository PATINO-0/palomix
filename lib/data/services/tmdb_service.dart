import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/config/tmdb_config.dart';
import '../models/movie_model.dart';

class TmdbService {
  final http.Client _client;

  TmdbService({http.Client? client}) : _client = client ?? http.Client();

  Uri _buildUri(String path, Map<String, String> query) {
    final params = Map<String, String>.from(query);
    if (TmdbConfig.bearerToken.isEmpty) {
      params['api_key'] = TmdbConfig.apiKey;
    }
    return Uri.parse('${ApiConstants.tmdbBaseUrl}$path').replace(queryParameters: params);
  }

  Future<http.Response> _get(String path, Map<String, String> query) {
    final headers = TmdbConfig.bearerToken.isNotEmpty
        ? {'Authorization': 'Bearer ${TmdbConfig.bearerToken}'}
        : {};
    return _client.get(_buildUri(path, query), headers: headers.cast<String, String>());
  }

  void _ensureAuthConfigured() {
    if (!TmdbConfig.isConfigured) {
      throw Exception('TMDB API key/token no configurado. Define TMDB_API_KEY o TMDB_BEARER_TOKEN.');
    }
  }

  Future<List<MovieModel>> searchMovies(String query) async {
    try {
      _ensureAuthConfigured();
      final response = await _get('/search/movie', {
        'query': query,
        'language': 'es-MX',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((movie) => MovieModel.fromJson(movie)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('TMDB: API key/token inválido (401)');
      } else {
        throw Exception('Error al buscar películas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<MovieModel> getMovieDetails(int movieId) async {
    try {
      _ensureAuthConfigured();
      final detailsResponse = await _get('/movie/$movieId', {
        'language': 'es-MX',
      });
      final creditsResponse = await _get('/movie/$movieId/credits', {});

      if (detailsResponse.statusCode == 200 && creditsResponse.statusCode == 200) {
        final movieData = json.decode(detailsResponse.body);
        final creditsData = json.decode(creditsResponse.body);
        movieData['cast'] = (creditsData['cast'] as List).take(10).toList();
        return MovieModel.fromJson(movieData);
      } else if (detailsResponse.statusCode == 401 || creditsResponse.statusCode == 401) {
        throw Exception('TMDB: API key/token inválido (401)');
      } else {
        throw Exception('Error al obtener detalles de la película');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<MovieModel>> getSimilarMovies(int movieId) async {
    try {
      _ensureAuthConfigured();
      final response = await _get('/movie/$movieId/similar', {
        'language': 'es-MX',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.take(6).map((movie) => MovieModel.fromJson(movie)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('TMDB: API key/token inválido (401)');
      } else {
        throw Exception('Error al obtener películas similares');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<MovieModel>> getRecommendations(int movieId) async {
    try {
      _ensureAuthConfigured();
      final response = await _get('/movie/$movieId/recommendations', {
        'language': 'es-MX',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.take(6).map((movie) => MovieModel.fromJson(movie)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('TMDB: API key/token inválido (401)');
      } else {
        throw Exception('Error al obtener recomendaciones');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<MovieModel>> getPopularMovies() async {
    try {
      _ensureAuthConfigured();
      final response = await _get('/movie/popular', {
        'language': 'es-MX',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.take(10).map((movie) => MovieModel.fromJson(movie)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('TMDB: API key/token inválido (401)');
      } else {
        throw Exception('Error al obtener películas populares');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<MovieModel>> getTrendingMovies() async {
    try {
      _ensureAuthConfigured();
      final response = await _get('/trending/movie/week', {
        'language': 'es-MX',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.take(20).map((movie) => MovieModel.fromJson(movie)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('TMDB: API key/token inválido (401)');
      } else {
        throw Exception('Error al obtener películas trending');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<MovieModel>> getTopRatedMovies() async {
    try {
      _ensureAuthConfigured();
      final response = await _get('/movie/top_rated', {
        'language': 'es-MX',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.take(20).map((movie) => MovieModel.fromJson(movie)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('TMDB: API key/token inválido (401)');
      } else {
        throw Exception('Error al obtener películas mejor valoradas');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<MovieModel>> getMoviesByGenre(int genreId, {int page = 1}) async {
    try {
      _ensureAuthConfigured();
      final response = await _get('/discover/movie', {
        'language': 'es-MX',
        'with_genres': genreId.toString(),
        'sort_by': 'popularity.desc',
        'page': page.toString(),
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.take(20).map((movie) => MovieModel.fromJson(movie)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('TMDB: API key/token inválido (401)');
      } else {
        throw Exception('Error al obtener películas por género');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
