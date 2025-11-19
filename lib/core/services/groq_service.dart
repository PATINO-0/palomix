import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/movie.dart';

class GroqService {
  GroqService._();
  static final GroqService instance = GroqService._();

  String? _systemPrompt;
  String? _userTemplate;

  Future<void> loadPrompt() async {
    if (_systemPrompt != null) return;

    final jsonStr =
        await rootBundle.loadString('assets/groq/prompt_movie_summary.json');
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    _systemPrompt = data['system_prompt'] as String;
    _userTemplate = data['user_template'] as String;
  }

  Future<String> summarizeMovie(Movie movie) async {
    await loadPrompt();

    final template = _userTemplate!;
    final userContent = template
        .replaceAll('{{title}}', movie.title)
        .replaceAll('{{overview}}', movie.overview ?? 'Sin sinopsis disponible')
        .replaceAll('{{release_date}}', movie.releaseDate ?? 'Desconocida');

    final body = jsonEncode({
      'model': 'llama-3.1-8b-instant', // ajusta al modelo que uses en Groq
      'messages': [
        {
          'role': 'system',
          'content': _systemPrompt,
        },
        {
          'role': 'user',
          'content': userContent,
        }
      ],
      'temperature': 0.7,
      'max_tokens': 400,
    });

    final resp = await http.post(
      Uri.parse(AppConfig.groqChatUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConfig.groqApiKey}',
      },
      body: body,
    );

    if (resp.statusCode != 200) {
      throw Exception('Groq request failed: ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>;
    final content =
        choices.first['message']['content'] as String? ?? 'Sin resumen.';

    return content.trim();
  }
}
