// lib/features/favorites/favorites_screen.dart

import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/models/favorite_movie.dart';
import '../../core/services/supabase_service.dart';
import '../movie_detail/movie_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _loading = true;
  List<FavoriteMovie> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _loading = true;
    });
    try {
      final list = await SupabaseService.instance.getFavorites();
      setState(() {
        _favorites = list;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _deleteFavorite(FavoriteMovie fav) async {
    await SupabaseService.instance.removeFavorite(fav.movie.id);
    _loadFavorites();
  }

  void _openDetails(FavoriteMovie fav) {
    final posterUrl = fav.movie.posterPath != null
        ? '${AppConfig.tmdbImageBaseUrl}${fav.movie.posterPath}'
        : null;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(
          movie: fav.movie,
          fullPosterUrl: posterUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favorites.isEmpty) {
      return const Center(
        child: Text(
          'Aún no tienes películas favoritas.\nAñade algunas desde el chat 🍿',
          textAlign: TextAlign.center,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        itemCount: _favorites.length,
        itemBuilder: (ctx, i) {
          final fav = _favorites[i];
          final posterUrl = fav.movie.posterPath != null
              ? '${AppConfig.tmdbImageBaseUrl}${fav.movie.posterPath}'
              : null;

          return Card(
            color: Colors.white.withOpacity(0.03),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: Hero(
                tag: 'poster-${fav.movie.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: posterUrl != null
                      ? Image.network(
                          posterUrl,
                          width: 50,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 50,
                          color: Colors.grey.shade900,
                          child: const Icon(
                            Icons.movie_outlined,
                            color: Colors.white54,
                          ),
                        ),
                ),
              ),
              title: Text(fav.movie.title),
              subtitle: Text(
                fav.movie.overview ?? 'Sin sinopsis guardada',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteFavorite(fav),
              ),
              onTap: () => _openDetails(fav),
            ),
          );
        },
      ),
    );
  }
}
