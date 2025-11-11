import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/favorite_model.dart';

// Servicio de favoritos separado para mantener código enfocado y pequeño
class FavoritesService {
  final SupabaseClient _client = Supabase.instance.client;
  static const _uuid = Uuid();

  Future<void> addToFavorites({
    required int movieId,
    required String movieTitle,
    String? posterPath,
  }) async {
    try {
      final user = _client.auth.currentUser;
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

  Future<void> removeFromFavorites(int movieId) async {
    try {
      final user = _client.auth.currentUser;
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

  Future<List<FavoriteModel>> getFavorites() async {
    try {
      final user = _client.auth.currentUser;
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

  Future<bool> isInFavorites(int movieId) async {
    try {
      final user = _client.auth.currentUser;
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
}