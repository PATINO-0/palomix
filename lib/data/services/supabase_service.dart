import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/favorite_model.dart';
import '../models/playlist_model.dart';
import 'auth_service.dart';
import 'favorites_service.dart';
import 'playlists_service.dart';

// Fachada estática que delega en servicios especializados.
// Mantiene compatibilidad con el código existente mientras reduce líneas y responsabilidades.
class SupabaseService {
  static final AuthService _auth = AuthService();
  static final FavoritesService _favorites = FavoritesService();
  static final PlaylistsService _playlists = PlaylistsService();

  // ===== Autenticación =====
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) => _auth.signUp(email: email, password: password, fullName: fullName);

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) => _auth.signIn(email: email, password: password);

  static Future<void> signOut() => _auth.signOut();

  static User? getCurrentUser() => _auth.getCurrentUser();

  static Stream<AuthState> get authStateChanges => _auth.authStateChanges;

  // ===== Favoritos =====
  static Future<void> addToFavorites({
    required int movieId,
    required String movieTitle,
    String? posterPath,
  }) => _favorites.addToFavorites(
        movieId: movieId,
        movieTitle: movieTitle,
        posterPath: posterPath,
      );

  static Future<void> removeFromFavorites(int movieId) =>
      _favorites.removeFromFavorites(movieId);

  static Future<List<FavoriteModel>> getFavorites() => _favorites.getFavorites();

  static Future<bool> isInFavorites(int movieId) =>
      _favorites.isInFavorites(movieId);

  // ===== Playlists =====
  static Future<PlaylistModel> createPlaylist({
    required String name,
    String? description,
  }) => _playlists.createPlaylist(name: name, description: description);

  static Future<List<PlaylistModel>> getPlaylists() => _playlists.getPlaylists();

  static Future<void> addMovieToPlaylist(String playlistId, int movieId) =>
      _playlists.addMovieToPlaylist(playlistId, movieId);

  static Future<void> removeMovieFromPlaylist(
          String playlistId, int movieId) =>
      _playlists.removeMovieFromPlaylist(playlistId, movieId);

  static Future<void> deletePlaylist(String playlistId) =>
      _playlists.deletePlaylist(playlistId);
}
