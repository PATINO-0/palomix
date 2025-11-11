import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/playlist_model.dart';

// Servicio de playlists separado para mantener responsabilidades claras
class PlaylistsService {
  final SupabaseClient _client = Supabase.instance.client;
  static const _uuid = Uuid();

  Future<PlaylistModel> createPlaylist({
    required String name,
    String? description,
  }) async {
    try {
      final user = _client.auth.currentUser;
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

  Future<List<PlaylistModel>> getPlaylists() async {
    try {
      final user = _client.auth.currentUser;
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

  Future<void> addMovieToPlaylist(String playlistId, int movieId) async {
    try {
      final user = _client.auth.currentUser;
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

  Future<void> removeMovieFromPlaylist(String playlistId, int movieId) async {
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

  Future<void> deletePlaylist(String playlistId) async {
    try {
      await _client.from('playlists').delete().eq('id', playlistId);
    } catch (e) {
      throw Exception('Error al eliminar playlist: $e');
    }
  }
}