// lib/core/config/tmdb_config.dart

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../constants/api_constants.dart';

class TmdbConfig {
  static String _apiKey = '';
  static String _bearerToken = '';
  static bool _loaded = false;

  static String get apiKey => _apiKey;
  static String get bearerToken => _bearerToken;

  static bool get isConfigured => _apiKey.isNotEmpty || _bearerToken.isNotEmpty;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    // 1) Valores base (ApiConstants) – en este proyecto están vacíos
    _apiKey = ApiConstants.tmdbApiKey;
    _bearerToken = ApiConstants.tmdbBearerToken;

    // 2) Sobrescribir con JSON si existe
    try {
      final jsonStr = await rootBundle.loadString('assets/config/tmdb.json');
      final data = json.decode(jsonStr) as Map<String, dynamic>;

      final fileKey = (data['apiKey'] as String?)?.trim();
      final fileBearer = (data['bearerToken'] as String?)?.trim();

      if (fileKey != null && fileKey.isNotEmpty) {
        _apiKey = fileKey;
      }
      if (fileBearer != null && fileBearer.isNotEmpty) {
        _bearerToken = fileBearer;
      }
    } catch (_) {
      // Si no existe o falla el JSON, seguimos con ApiConstants
    }

    // DEBUG: mira esto en consola al arrancar
    // ignore: avoid_print
    print(
      'TMDB CONFIG -> apiKey empty: ${_apiKey.isEmpty}, bearer empty: ${_bearerToken.isEmpty}',
    );
  }
}
