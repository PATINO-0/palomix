// lib/features/explore/explore_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/movie.dart';          // Movie simple
import '../../data/models/movie_model.dart';   // MovieModel de TMDb
import '../../data/services/tmdb_service.dart';
import '../movie_detail/movie_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _tmdb = TmdbService();
  List<MovieModel> _movies = [];
  bool _loading = true;
  final TextEditingController _searchCtrl = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  Future<void> _loadTrending() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _tmdb.getTrendingMovies();
      setState(() {
        _movies = list;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      _loadTrending();
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _tmdb.searchMovies(query);
      setState(() {
        _movies = list;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _openDetails(MovieModel movie) {
    final posterUrl = movie.fullPosterUrl;

    // Adaptamos al modelo simple Movie
    final coreMovie = Movie(
      id: movie.id,
      title: movie.title,
      overview: movie.overview,
      posterPath: movie.posterPath,
      releaseDate: movie.releaseDate,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(
          movie: coreMovie,
          fullPosterUrl: posterUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final posterHeight = 220.0;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Ocurrió un error al cargar películas:\n$_error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_movies.isEmpty) {
      return const Center(
        child: Text(
          'No encontré películas para mostrar.\nIntenta con otra búsqueda.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Buscar películas por título...',
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _search,
                icon: const Icon(Icons.search),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2 / 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _movies.length,
            itemBuilder: (ctx, i) {
              final movie = _movies[i];
              final posterUrl = movie.fullPosterUrl;

              return GestureDetector(
                onTap: () => _openDetails(movie),
                child: Column(
                  children: [
                    Hero(
                      tag: 'poster-${movie.id}',
                      child: SizedBox(
                        height: posterHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: posterUrl != null
                              ? Image.network(
                                  posterUrl,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey.shade900,
                                  child: const Center(
                                    child: Icon(
                                      Icons.movie_filter_outlined,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 250.ms).scaleXY(
                    begin: 0.9,
                    end: 1.0,
                    curve: Curves.easeOutBack,
                  );
            },
          ),
        ),
      ],
    );
  }
}
