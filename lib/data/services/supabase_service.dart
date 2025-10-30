import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/api_constants.dart';
import '../models/favorite_model.dart';
import '../models/playlist_model.dart';
import 'package:uuid/uuid.dart';


class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const _uuid = Uuid();

 
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {'full_name': fullName.trim()},
      );
      return response;
    } on AuthApiException catch (e) {
      
      throw Exception(e.message);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error al registrar usuario: $e');
    }
  }

  
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

  
  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  
  static User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  
  static Stream<AuthState> get authStateChanges {
    return _client.auth.onAuthStateChange;
  }

  
  static Future<void> addToFavorites({
    required int movieId,
    required String movieTitle,
    String? posterPath,
  }) async {
    try {
      final user = getCurrentUser();
      if (user == null) throw Exception('Usuario no autenticado');

      
      final alreadyFavorite = await isInFavorites(movieId);
      if (alreadyFavorite) {
        debugPrint(
            'addToFavorites: ya existe movieId=$movieId para user=${user.id}');
        return;
      }

      final favorite = FavoriteModel(
        id: _uuid.v4(),
        userId: user.id,
        movieId: movieId,
        movieTitle: movieTitle,
        posterPath: posterPath,
        createdAt: DateTime.now(),
      );

      final inserted = await _client
          .from('favorites')
          .insert(favorite.toJson())
          .select()
          .maybeSingle();
      debugPrint('addToFavorites: insert response => ' + inserted.toString());
    } on PostgrestException catch (e) {
      
      if (e.code == '23505') {
        debugPrint('addToFavorites: duplicado detectado 23505, ignorado.');
        return;
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error al agregar a favoritos: $e');
    }
  }

  
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

  
  static Future<List<FavoriteModel>> getFavorites() async {
    try {
      final user = getCurrentUser();
      if (user == null) throw Exception('Usuario no autenticado');

      final response = await _client
          .from('favorites')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      debugPrint('getFavorites: response length => ' +
          ((response as List).length).toString());

      return (response as List)
          .map((json) => FavoriteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener favoritos: $e');
    }
  }

  
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

  
  static Future<void> addMovieToPlaylist(String playlistId, int movieId) async {
    try {
      final user = getCurrentUser();
      if (user == null) throw Exception('Usuario no autenticado');

      
      final response = await _client
          .from('playlists')
          .select()
          .eq('id', playlistId)
          .single();

      final playlist = PlaylistModel.fromJson(response);

      
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

  
  static Future<void> removeMovieFromPlaylist(
      String playlistId, int movieId) async {
    try {
      final response = await _client
          .from('playlists')
          .select()
          .eq('id', playlistId)
          .single();

      final playlist = PlaylistModel.fromJson(response);
      final updatedMovieIds =
          playlist.movieIds.where((id) => id != movieId).toList();

      await _client.from('playlists').update({
        'movie_ids': updatedMovieIds,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', playlistId);
    } catch (e) {
      throw Exception('Error al eliminar película de playlist: $e');
    }
  }

  
  static Future<void> deletePlaylist(String playlistId) async {
    try {
      await _client.from('playlists').delete().eq('id', playlistId);
    } catch (e) {
      throw Exception('Error al eliminar playlist: $e');
    }
  }
}
