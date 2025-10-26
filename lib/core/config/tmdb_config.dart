import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb; // added for web guard
import '../constants/api_constants.dart';

class TmdbConfig {
  static String _apiKey = '';
  static String _bearerToken = '';

  static String get apiKey => _apiKey;
  static String get bearerToken => _bearerToken;

  static Future<void> load() async {
    // 1) --dart-define
    _apiKey = ApiConstants.tmdbApiKey;
    _bearerToken = ApiConstants.tmdbBearerToken;

    // 2) Variables de entorno (solo desktop; evitar en web)
    final bool isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    if (isDesktop) {
      if (_apiKey.isEmpty) {
        _apiKey = Platform.environment['TMDB_API_KEY'] ?? Platform.environment['TMDB_KEY'] ?? '';
      }
      if (_bearerToken.isEmpty) {
        _bearerToken = Platform.environment['TMDB_BEARER_TOKEN'] ?? Platform.environment['TMDB_TOKEN'] ?? '';
      }
    }

    // 3) Archivo opcional de assets (si existe)
    try {
      final jsonStr = await rootBundle.loadString('assets/config/tmdb.json');
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      _apiKey = (data['apiKey'] as String?)?.trim() ?? _apiKey;
      _bearerToken = (data['bearerToken'] as String?)?.trim() ?? _bearerToken;
    } catch (_) {
      // Ignorar si no existe
    }
  }

  static bool get isConfigured => _apiKey.isNotEmpty || _bearerToken.isNotEmpty;
}
