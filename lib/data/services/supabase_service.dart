import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/api_constants.dart';
import '../models/favorite_model.dart';
import '../models/playlist_model.dart';
import 'package:uuid/uuid.dart';

// Servicio para manejar todas las operaciones de Supabase
class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const _uuid = Uuid();
  
  // ========== AUTENTICACIÓN ==========
  
  // Registro de nuevo usuario
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      return response;
    } catch (e) {
      throw Exception('Error al registrar usuario: $e');
    }
  }
  
  // Inicio de sesión
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }
  
  // Cerrar sesión
  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }
  
  // Obtener usuario actual
  static User? getCurrentUser() {
    return _client.auth.currentUser;
  }
  
  // Stream de cambios de autenticación
  static Stream<AuthState> get authStateChanges {
    return _client.auth.onAuthStateChange;
  }
  
  // ========== FAVORITOS ==========
  
  // Agregar película a favoritos
  static Future<void> addToFavorites({
    required int movieId,
    required String movieTitle,
    String? posterPath,
  }) async {
    try {
      final user = getCurrentUser();
      if (user == null) throw Exception('Usuario no autenticado');
      
      final favorite = FavoriteModel(
        id: _uuid.v4(),
        userId: user.id,
        movieId: movieId,
        movieTitle: movieTitle,
        posterPath: posterPath,
        createdAt: DateTime.now(),
      );
      
      await _client.from('favorites').insert(favorite.toJson());
    } catch (e) {
      throw Exception('Error al agregar a favoritos: $e');
    }
  }
  
  // Eliminar película de favoritos
  static Future<void> removeFromFavorites(int movieId) async {
    try {
      final user = getCurrentUser();
      if (user == null) throw Exception('Usuario no autenticado');
      
      await _client
          .from('favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('movie_id', movieId);
    } catch (e) {
      throw Exception('Error al eliminar de favoritos: $e');
    }
  }
  
  // Obtener todos los favoritos del usuario
  static Future<List<FavoriteModel>> getFavorites() async {
    try {
      final user = getCurrentUser();
      if (user == null) throw Exception('Usuario no autenticado');
      
      final response = await _client
          .from('favorites')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => FavoriteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener favoritos: $e');
    }
  }
  
  // Verificar si una película está en favoritos
  static Future<bool> isInFavorites(int movieId) async {
    try {
      final user = getCurrentUser();
      if (user == null) return false;
      
      final response = await _client
          .from('favorites')
          .select()
          .eq('user_id', user.id)
          .eq('movie_id', movieId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      return false;
    }
  }
  
  // ========== PLAYLISTS ==========
  
  // Crear nueva playlist
  static Future<PlaylistModel> createPlaylist({
    required String name,
    String? description,
  }) async {
    try {
      final user = getCurrentUser();
      if (user == null) throw Exception('Usuario no autenticado');
      
      final playlist = PlaylistModel(
        id: _uuid.v4(),
        userId: user.id,
        name: name,
        description: description,
        movieIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _client.from('playlists').insert(playlist.toJson());
      return playlist;
    } catch (e) {
      throw Exception('Error al crear playlist: $e');
    }
  }
  
  // Obtener todas las playlists del usuario
  static Future<List<PlaylistModel>> getPlaylists() async {
    try {
      final user = getCurrentUser();
      if (user == null) throw Exception('Usuario no autenticado');
      
      final response = await _client
          .from('playlists')
          .select()
          .eq('user_id', user.id)
          .order('updated_at', ascending: false);
      
      return (response as List)
          .map((json) => PlaylistModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener playlists: $e');
    }
  }
  
  // Agregar película a playlist
  static Future<void> addMovieToPlaylist(String playlistId, int movieId) async {
    try {
      final user = getCurrentUser();
      if (user == null) throw Exception('Usuario no autenticado');
      
      // Obtener playlist actual
      final response = await _client
          .from('playlists')
          .select()
          .eq('id', playlistId)
          .single();
      
      final playlist = PlaylistModel.fromJson(response);
      
      // Agregar película si no existe
      if (!playlist.movieIds.contains(movieId)) {
        final updatedMovieIds = [...playlist.movieIds, movieId];
        await _client.from('playlists').update({
          'movie_ids': updatedMovieIds,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', playlistId);
      }
    } catch (e) {
      throw Exception('Error al agregar película a playlist: $e');
    }
  }
  
  // Eliminar película de playlist
  static Future<void> removeMovieFromPlaylist(String playlistId, int movieId) async {
    try {
      final response = await _client
          .from('playlists')
          .select()
          .eq('id', playlistId)
          .single();
      
      final playlist = PlaylistModel.fromJson(response);
      final updatedMovieIds = playlist.movieIds.where((id) => id != movieId).toList();
      
      await _client.from('playlists').update({
        'movie_ids': updatedMovieIds,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', playlistId);
    } catch (e) {
      throw Exception('Error al eliminar película de playlist: $e');
    }
  }
  
  // Eliminar playlist
  static Future<void> deletePlaylist(String playlistId) async {
    try {
      await _client.from('playlists').delete().eq('id', playlistId);
    } catch (e) {
      throw Exception('Error al eliminar playlist: $e');
    }
  }
}
