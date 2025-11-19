// lib/core/constants/api_constants.dart

enum AIProvider {
  openAi,
  groq,
}

class ApiConstants {
  // Supabase Configuration (solo de ejemplo, realmente usas AppConfig + .env)
  static const String supabaseUrl = 'https://YOUR_SUPABASE_URL.supabase.co';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // OpenAI Configuration (si la usas en otro lado)
  static const String openAiApiKey = 'YOUR_OPENAI_API_KEY';
  static const String openAiModel = 'gpt-4-turbo-preview';

  // Groq Configuration (ejemplo; en tu app real usas AppConfig.groqApiKey)
  static const String groqApiKey = 'YOUR_GROQ_API_KEY';
  static const String groqModel = 'llama-3.3-70b-versatile';

  // TMDB Configuration
  // En este proyecto cargamos la API key / bearer token desde assets/config/tmdb.json
  // así que aquí dejamos valores vacíos como fallback.
  static const String tmdbApiKey = '';
  static const String tmdbBearerToken = '';

  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  // AI Provider Selection
  static const AIProvider currentProvider = AIProvider.groq;
}
