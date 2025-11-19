import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config.dart';
import '../../core/models/favorite_movie.dart';
import '../../core/services/groq_service.dart';
import '../../core/services/supabase_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _loading = true;
  List<FavoriteMovie> _favorites = [];
  String? _summary;
  bool _loadingSummary = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _loading = true;
      _summary = null;
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

  Future<void> _regenerateSummary(FavoriteMovie fav) async {
    setState(() {
      _loadingSummary = true;
      _summary = null;
    });

    try {
      final user = SupabaseService.instance.currentUser!;
      final json = await SupabaseService.instance
          .getFavoriteMovieJson(user.id, fav.movie.id);

      if (json == null) {
        setState(() {
          _summary =
              'No encontré la información completa en el bucket. Intenta desde el chat.';
        });
      } else {
        // Reconstruimos movie simple
        final movie = fav.movie;
        final summary = await GroqService.instance.summarizeMovie(movie);
        setState(() {
          _summary = summary;
        });
      }
    } catch (_) {
      setState(() {
        _summary = 'No pude regenerar el resumen en este momento.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingSummary = false;
        });
      }
    }
  }

  Future<void> _deleteFavorite(FavoriteMovie fav) async {
    await SupabaseService.instance.removeFavorite(fav.movie.id);
    _loadFavorites();
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

    return Column(
      children: [
        Expanded(
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
                  leading: ClipRRect(
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
                  onTap: () => _regenerateSummary(fav),
                ),
              );
            },
          ),
        ),
        if (_loadingSummary)
          const LinearProgressIndicator(minHeight: 2),
        if (_summary != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _summary!,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
      ],
    );
  }
}
