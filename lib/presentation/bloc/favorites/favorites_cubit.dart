import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/favorite_model.dart';
import '../../../data/services/supabase_service.dart';

abstract class FavoritesState {}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesLoaded extends FavoritesState {
  final List<FavoriteModel> favorites;
  FavoritesLoaded(this.favorites);
}

class FavoritesError extends FavoritesState {
  final String message;
  FavoritesError(this.message);
}


class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit() : super(FavoritesInitial());

  Future<void> loadFavorites() async {
    emit(FavoritesLoading());
    try {
      final favorites = await SupabaseService.getFavorites();
      emit(FavoritesLoaded(favorites));
    } catch (e) {
      emit(FavoritesError('Error al cargar favoritos: ${e.toString()}'));
    }
  }

  
  Future<void> addToFavorites({
    required int movieId,
    required String movieTitle,
    String? posterPath,
  }) async {
    try {
      await SupabaseService.addToFavorites(
        movieId: movieId,
        movieTitle: movieTitle,
        posterPath: posterPath,
      );
      
    } catch (e) {
      emit(FavoritesError('Error al agregar a favoritos: ${e.toString()}'));
      rethrow; 
    }
  }

  Future<void> removeFavorite(int movieId) async {
    try {
      await SupabaseService.removeFromFavorites(movieId);
      await loadFavorites();
    } catch (e) {
      emit(FavoritesError('Error al eliminar de favoritos: ${e.toString()}'));
    }
  }
}
