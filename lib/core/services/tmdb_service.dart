import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/movie.dart';

class TmdbService {
  TmdbService._();
  static final TmdbService instance = TmdbService._();

  Future<List<Movie>> searchMovies(String query) async {
    final url = Uri.parse(
      '${AppConfig.tmdbBaseUrl}/search/movie?api_key=${AppConfig.tmdbApiKey}&language=es-ES&query=$query',
    );

    final resp = await http.get(url);
    if (resp.statusCode != 200) {
      throw Exception('TMDb search failed');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>;
    return results.map((e) => Movie.fromTmdbJson(e)).toList();
  }

  Future<List<Movie>> getTrendingMovies() async {
    final url = Uri.parse(
      '${AppConfig.tmdbBaseUrl}/trending/movie/week?api_key=${AppConfig.tmdbApiKey}&language=es-ES',
    );

    final resp = await http.get(url);
    if (resp.statusCode != 200) {
      throw Exception('TMDb trending failed');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>;
    return results.map((e) => Movie.fromTmdbJson(e)).toList();
  }

  Future<List<Movie>> getRecommendations(int tmdbId) async {
    final url = Uri.parse(
      '${AppConfig.tmdbBaseUrl}/movie/$tmdbId/recommendations?api_key=${AppConfig.tmdbApiKey}&language=es-ES',
    );

    final resp = await http.get(url);
    if (resp.statusCode != 200) {
      return [];
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>;
    return results.map((e) => Movie.fromTmdbJson(e)).toList();
  }
}
