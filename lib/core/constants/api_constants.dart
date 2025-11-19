// lib/core/constants/api_constants.dart

enum AIProvider {
  openAi,
  groq,
}

class ApiConstants {
  static const String supabaseUrl = 'https://YOUR_SUPABASE_URL.supabase.co';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  static const String openAiApiKey = 'YOUR_OPENAI_API_KEY';
  static const String openAiModel = 'gpt-4-turbo-preview';

  static const String groqApiKey = 'YOUR_GROQ_API_KEY';
  static const String groqModel = 'llama-3.3-70b-versatile';

  static const String tmdbApiKey = '';
  static const String tmdbBearerToken = '';

  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  static const AIProvider currentProvider = AIProvider.groq;
}
