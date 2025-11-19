import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import '../models/movie.dart';
import '../models/favorite_movie.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  // Auth

  Future<AuthResponse> signUp(String email, String password) async {
    final res = await client.auth.signUp(
      email: email,
      password: password,
    );

    if (res.user != null) {
      await client.from('profiles').insert({
        'id': res.user!.id,
        'username': email.split('@').first,
      });
    }

    return res;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  User? get currentUser => client.auth.currentUser;

  // Favorites

  Future<void> addFavorite(Movie movie) async {
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');

    // Insert into table
    await client.from('favorite_movies').upsert({
      'user_id': user.id,
      'tmdb_id': movie.id,
      'title': movie.title,
      'poster_path': movie.posterPath,
      'overview': movie.overview,
      'metadata': movie.toJson(),
    });

    // Save JSON into storage bucket to allow re-generation later
    final jsonBytes = utf8.encode(jsonEncode(movie.toJson()));

    final path = '${user.id}/${movie.id}.json';

    await client.storage
        .from(AppConfig.favoritesBucket)
        .uploadBinary(path, jsonBytes, fileOptions: const FileOptions(
          contentType: 'application/json',
          upsert: true,
        ));
  }

  Future<List<FavoriteMovie>> getFavorites() async {
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');

    final data = await client
        .from('favorite_movies')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((e) => FavoriteMovie.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> removeFavorite(int tmdbId) async {
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');

    await client
        .from('favorite_movies')
        .delete()
        .match({'user_id': user.id, 'tmdb_id': tmdbId});

    final path = '${user.id}/$tmdbId.json';
    await client.storage
        .from(AppConfig.favoritesBucket)
        .remove([path]);
  }

  Future<Map<String, dynamic>?> getFavoriteMovieJson(
      String userId, int tmdbId) async {
    final path = '$userId/$tmdbId.json';
    final response = await client.storage
        .from(AppConfig.favoritesBucket)
        .download(path);

    if (response == null) return null;
    final text = utf8.decode(response);
    return jsonDecode(text) as Map<String, dynamic>;
  }
}
