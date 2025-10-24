import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/movie_model.dart';

// Servicio para interactuar con la API de TMDB
class TmdbService {
  final http.Client _client;
  
  TmdbService({http.Client? client}) : _client = client ?? http.Client();
  
  // Buscar películas por título
  Future<List<MovieModel>> searchMovies(String query) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.tmdbBaseUrl}/search/movie?api_key=${ApiConstants.tmdbApiKey}&query=$query&language=es-MX',
        ),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((movie) => MovieModel.fromJson(movie)).toList();
      } else {
        throw Exception('Error al buscar películas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
  
  // Obtener detalles completos de una película
  Future<MovieModel> getMovieDetails(int movieId) async {
    try {
      // Obtener detalles básicos
      final detailsResponse = await _client.get(
        Uri.parse(
          '${ApiConstants.tmdbBaseUrl}/movie/$movieId?api_key=${ApiConstants.tmdbApiKey}&language=es-MX',
        ),
      );
      
      // Obtener reparto
      final creditsResponse = await _client.get(
        Uri.parse(
          '${ApiConstants.tmdbBaseUrl}/movie/$movieId/credits?api_key=${ApiConstants.tmdbApiKey}',
        ),
      );
      
      if (detailsResponse.statusCode == 200 && creditsResponse.statusCode == 200) {
        final movieData = json.decode(detailsResponse.body);
        final creditsData = json.decode(creditsResponse.body);
        
        // Combinar datos
        movieData['cast'] = (creditsData['cast'] as List).take(10).toList();
        
        return MovieModel.fromJson(movieData);
      } else {
        throw Exception('Error al obtener detalles de la película');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
  
  // Obtener películas similares
  Future<List<MovieModel>> getSimilarMovies(int movieId) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.tmdbBaseUrl}/movie/$movieId/similar?api_key=${ApiConstants.tmdbApiKey}&language=es-MX',
        ),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.take(6).map((movie) => MovieModel.fromJson(movie)).toList();
      } else {
        throw Exception('Error al obtener películas similares');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
  
  // Obtener recomendaciones basadas en una película
  Future<List<MovieModel>> getRecommendations(int movieId) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.tmdbBaseUrl}/movie/$movieId/recommendations?api_key=${ApiConstants.tmdbApiKey}&language=es-MX',
        ),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.take(6).map((movie) => MovieModel.fromJson(movie)).toList();
      } else {
        throw Exception('Error al obtener recomendaciones');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
  
  // Obtener películas populares
  Future<List<MovieModel>> getPopularMovies() async {
    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.tmdbBaseUrl}/movie/popular?api_key=${ApiConstants.tmdbApiKey}&language=es-MX',
        ),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.take(10).map((movie) => MovieModel.fromJson(movie)).toList();
      } else {
        throw Exception('Error al obtener películas populares');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
