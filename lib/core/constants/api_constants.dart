// API Keys y URLs - IMPORTANTE: Usar variables de entorno en producción
class ApiConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'https://ryhotdiwdbqkcngighzq.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ5aG90ZGl3ZGJxa2NuZ2lnaHpxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEzNjU2MzAsImV4cCI6MjA3Njk0MTYzMH0.03fUdXlqG-DqU1Ysg1YB8Jod0VOq3r-qiqlHkagbFs0';
  
  // OpenAI Configuration
  static const String openAiApiKey = 'YOUR_OPENAI_API_KEY';
  static const String openAiModel = 'gpt-4-turbo-preview';
  
  // Groq Configuration (Respaldo)
  static const String groqApiKey = 'YOUR_GROQ_API_KEY';
  static const String groqModel = 'llama-3.3-70b-versatile';
  
  // TMDB Configuration (via --dart-define)
  static const String tmdbApiKey = String.fromEnvironment('TMDB_API_KEY', defaultValue: '');
  static const String tmdbBearerToken = String.fromEnvironment('TMDB_BEARER_TOKEN', defaultValue: '');
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';
  
  // AI Provider Selection (manual switch)
  static const AIProvider currentProvider = AIProvider.openAi;
}

enum AIProvider {
  openAi,
  groq,
}
