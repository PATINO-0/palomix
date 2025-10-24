import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

// Servicio de IA que maneja OpenAI y Groq
class AiService {
  final http.Client _client;
  
  AiService({http.Client? client}) : _client = client ?? http.Client();
  
  // Generar respuesta usando el proveedor configurado
  Future<String> generateResponse(String prompt, {List<Map<String, String>>? conversationHistory}) async {
    switch (ApiConstants.currentProvider) {
      case AIProvider.openAi:
        return await _generateOpenAiResponse(prompt, conversationHistory);
      case AIProvider.groq:
        return await _generateGroqResponse(prompt, conversationHistory);
    }
  }
  
  // Implementación para OpenAI (ChatGPT)
  Future<String> _generateOpenAiResponse(String prompt, List<Map<String, String>>? history) async {
    try {
      final messages = <Map<String, String>>[];
      
      // System prompt para guiar el comportamiento de la IA
      messages.add({
        'role': 'system',
        'content': '''Eres un asistente experto en películas y series. Tu función es:
1. Ayudar a buscar películas y series
2. Proporcionar información detallada y entretenida
3. Generar resúmenes concisos de tramas
4. Recomendar contenido similar basado en géneros y tramas
5. Responder en español de manera amigable y conversacional
Siempre mantén un tono entusiasta sobre el cine.'''
      });
      
      // Agregar historial de conversación si existe
      if (history != null) {
        messages.addAll(history);
      }
      
      // Agregar mensaje actual
      messages.add({'role': 'user', 'content': prompt});
      
      final response = await _client.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.openAiApiKey}',
        },
        body: json.encode({
          'model': ApiConstants.openAiModel,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 800,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Error en OpenAI: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al generar respuesta con OpenAI: $e');
    }
  }
  
  // Implementación para Groq (respaldo)
  Future<String> _generateGroqResponse(String prompt, List<Map<String, String>>? history) async {
    try {
      final messages = <Map<String, String>>[];
      
      messages.add({
        'role': 'system',
        'content': '''Eres un asistente experto en películas y series. Tu función es:
1. Ayudar a buscar películas y series
2. Proporcionar información detallada y entretenida
3. Generar resúmenes concisos de tramas
4. Recomendar contenido similar basado en géneros y tramas
5. Responder en español de manera amigable y conversacional
Siempre mantén un tono entusiasta sobre el cine.'''
      });
      
      if (history != null) {
        messages.addAll(history);
      }
      
      messages.add({'role': 'user', 'content': prompt});
      
      final response = await _client.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.groqApiKey}',
        },
        body: json.encode({
          'model': ApiConstants.groqModel,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 800,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Error en Groq: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al generar respuesta con Groq: $e');
    }
  }
  
  // Generar resumen de película con contexto
  Future<String> generateMovieSummary(String movieTitle, String overview) async {
    final prompt = '''Genera un resumen conciso y atractivo de la película "$movieTitle".
    
Información disponible: $overview

Por favor, crea un resumen de 2-3 oraciones que capture la esencia de la trama de manera entretenida.''';
    
    return await generateResponse(prompt);
  }
  
  // Generar recomendaciones personalizadas basadas en favoritos
  Future<String> generatePersonalizedRecommendations(List<String> favoriteMovies) async {
    final prompt = '''Basándote en las siguientes películas favoritas del usuario:
${favoriteMovies.join(', ')}

Genera una lista de 5 recomendaciones de películas similares que probablemente le gusten. 
Explica brevemente por qué cada recomendación es buena basándote en los géneros y temas de sus favoritas.''';
    
    return await generateResponse(prompt);
  }
}
