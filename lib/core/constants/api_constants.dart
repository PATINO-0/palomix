// API Keys y URLs - IMPORTANTE: Usar variables de entorno en producción
class ApiConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  // OpenAI Configuration
  static const String openAiApiKey = 'YOUR_OPENAI_API_KEY';
  static const String openAiModel = 'gpt-4-turbo-preview';
  
  // Groq Configuration (Respaldo)
  static const String groqApiKey = 'YOUR_GROQ_API_KEY';
  static const String groqModel = 'llama-3.3-70b-versatile';
  
  // TMDB Configuration
  static const String tmdbApiKey = 'YOUR_TMDB_API_KEY';
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';
  
  // AI Provider Selection (manual switch)
  static const AIProvider currentProvider = AIProvider.openAi;
}

enum AIProvider {
  openAi,
  groq,
}
