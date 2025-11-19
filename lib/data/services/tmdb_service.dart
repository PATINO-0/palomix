// lib/data/services/tmdb_service.dart

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

    // Si no hay bearer pero sí apiKey, la mandamos como query param
    if (TmdbConfig.bearerToken.isEmpty && TmdbConfig.apiKey.isNotEmpty) {
      params['api_key'] = TmdbConfig.apiKey;
    }

    return Uri.parse('${ApiConstants.tmdbBaseUrl}$path')
        .replace(queryParameters: params);
  }

  Future<http.Response> _get(String path, Map<String, String> query) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (TmdbConfig.bearerToken.isNotEmpty)
        'Authorization': 'Bearer ${TmdbConfig.bearerToken}',
    };

    return _client.get(
      _buildUri(path, query),
      headers: headers,
    );
  }

  Future<void> _ensureAuthConfigured() async {
    await TmdbConfig.load();
    if (!TmdbConfig.isConfigured) {
      throw Exception(
        'TMDB API key/token no configurado. Define TMDB_API_KEY o TMDB_BEARER_TOKEN o usa assets/config/tmdb.json.',
      );
    }
  }

  Future<List<MovieModel>> searchMovies(String query) async {
    await _ensureAuthConfigured();

    final response = await _get('/search/movie', {
      'query': query,
      'language': 'es-MX',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>;
      return results.map((movie) => MovieModel.fromJson(movie)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('TMDB: API key/token inválido (401)');
    } else {
      throw Exception('Error al buscar películas: ${response.statusCode}');
    }
  }

  Future<MovieModel> getMovieDetails(int movieId) async {
    await _ensureAuthConfigured();

    final detailsResponse = await _get('/movie/$movieId', {
      'language': 'es-MX',
    });
    final creditsResponse = await _get('/movie/$movieId/credits', {});

    if (detailsResponse.statusCode == 200 &&
        creditsResponse.statusCode == 200) {
      final movieData = json.decode(detailsResponse.body);
      final creditsData = json.decode(creditsResponse.body);

      movieData['cast'] =
          (creditsData['cast'] as List<dynamic>).take(10).toList();

      return MovieModel.fromJson(movieData as Map<String, dynamic>);
    } else if (detailsResponse.statusCode == 401 ||
        creditsResponse.statusCode == 401) {
      throw Exception('TMDB: API key/token inválido (401)');
    } else {
      throw Exception('Error al obtener detalles de la película');
    }
  }

  Future<List<MovieModel>> getSimilarMovies(int movieId) async {
    await _ensureAuthConfigured();

    final response = await _get('/movie/$movieId/similar', {
      'language': 'es-MX',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>;
      return results
          .take(6)
          .map((movie) => MovieModel.fromJson(movie))
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('TMDB: API key/token inválido (401)');
    } else {
      throw Exception('Error al obtener películas similares');
    }
  }

  Future<List<MovieModel>> getRecommendations(int movieId) async {
    await _ensureAuthConfigured();

    final response = await _get('/movie/$movieId/recommendations', {
      'language': 'es-MX',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>;
      return results
          .take(6)
          .map((movie) => MovieModel.fromJson(movie))
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('TMDB: API key/token inválido (401)');
    } else {
      throw Exception('Error al obtener recomendaciones');
    }
  }

  Future<List<MovieModel>> getPopularMovies() async {
    await _ensureAuthConfigured();

    final response = await _get('/movie/popular', {
      'language': 'es-MX',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>;
      return results
          .take(10)
          .map((movie) => MovieModel.fromJson(movie))
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('TMDB: API key/token inválido (401)');
    } else {
      throw Exception('Error al obtener películas populares');
    }
  }

  Future<List<MovieModel>> getTrendingMovies() async {
    await _ensureAuthConfigured();

    final response = await _get('/trending/movie/week', {
      'language': 'es-MX',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>;
      return results
          .take(20)
          .map((movie) => MovieModel.fromJson(movie))
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('TMDB: API key/token inválido (401)');
    } else {
      throw Exception('Error al obtener películas trending');
    }
  }

  Future<List<MovieModel>> getTopRatedMovies() async {
    await _ensureAuthConfigured();

    final response = await _get('/movie/top_rated', {
      'language': 'es-MX',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>;
      return results
          .take(20)
          .map((movie) => MovieModel.fromJson(movie))
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('TMDB: API key/token inválido (401)');
    } else {
      throw Exception('Error al obtener películas mejor valoradas');
    }
  }

  Future<List<MovieModel>> getMoviesByGenre(
    int genreId, {
    int page = 1,
  }) async {
    await _ensureAuthConfigured();

    final response = await _get('/discover/movie', {
      'language': 'es-MX',
      'with_genres': genreId.toString(),
      'sort_by': 'popularity.desc',
      'page': page.toString(),
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>;
      return results
          .take(20)
          .map((movie) => MovieModel.fromJson(movie))
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('TMDB: API key/token inválido (401)');
    } else {
      throw Exception('Error al obtener películas por género');
    }
  }
}
