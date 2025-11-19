import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/config.dart';
import '../../core/models/movie.dart';
import '../../core/services/groq_service.dart';
import '../../core/services/supabase_service.dart';
import '../../data/models/movie_model.dart';
import '../../data/services/tmdb_service.dart';

class MovieDetailScreen extends StatefulWidget {
  final int tmdbId;
  final String initialTitle;
  final String? initialPosterUrl;
  final Movie? baseMovie; // película simple para Groq si algo falla

  const MovieDetailScreen({
    super.key,
    required this.tmdbId,
    required this.initialTitle,
    this.initialPosterUrl,
    this.baseMovie,
  });

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final _tmdb = TmdbService();
  final _groq = GroqService.instance;

  MovieModel? _details;
  String? _summary;
  bool _loading = true;
  bool _loadingSummary = true;
  bool _savingFavorite = false;
  List<MovieModel> _similar = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _loadingSummary = true;
      _error = null;
    });

    try {
      final details = await _tmdb.getMovieDetails(widget.tmdbId);
      final similar = await _tmdb.getRecommendations(widget.tmdbId);

      _details = details;
      _similar = similar;

      await _generateSummary(details);
    } catch (e) {
      // si TMDb falla, intentamos al menos generar resumen con baseMovie
      _error = e.toString();
      if (widget.baseMovie != null) {
        try {
          final summary = await _groq.summarizeMovie(widget.baseMovie!);
          _summary = summary;
        } catch (_) {
          _summary = 'No pude generar el resumen en este momento.';
        }
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingSummary = false;
      });
    }
  }

  Future<void> _generateSummary(MovieModel details) async {
    setState(() {
      _loadingSummary = true;
    });

    try {
      final coreMovie = Movie(
        id: details.id,
        title: details.title,
        overview: details.overview,
        posterPath: details.posterPath,
        releaseDate: details.releaseDate,
      );

      final summary = await _groq.summarizeMovie(coreMovie);

      if (!mounted) return;
      setState(() {
        _summary = summary;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _summary =
            'No pude generar el resumen en este momento. Intenta de nuevo más tarde.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingSummary = false;
      });
    }
  }

  Future<void> _saveAsFavorite() async {
    if (_details == null) return;

    setState(() {
      _savingFavorite = true;
    });

    try {
      final coreMovie = Movie(
        id: _details!.id,
        title: _details!.title,
        overview: _details!.overview,
        posterPath: _details!.posterPath,
        releaseDate: _details!.releaseDate,
      );

      await SupabaseService.instance.addFavorite(coreMovie);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Película añadida a favoritos 🍿'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar la película en favoritos.'),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _savingFavorite = false;
      });
    }
  }

  String? get _posterUrl {
    if (_details != null && _details!.posterPath != null) {
      return '${AppConfig.tmdbImageBaseUrl}${_details!.posterPath}';
    }
    return widget.initialPosterUrl;
  }

  Widget _buildHeader(BuildContext context) {
    final posterUrl = _posterUrl;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Hero(
          tag: 'poster-${widget.tmdbId}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: posterUrl != null
                  ? Image.network(
                      posterUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey.shade900,
                      child: const Center(
                        child: Icon(
                          Icons.movie_outlined,
                          color: Colors.white54,
                          size: 40,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _details?.title ?? widget.initialTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              if (_details?.releaseDate != null)
                Text(
                  'Estreno: ${_details!.releaseDate}',
                  style: const TextStyle(color: Colors.white70),
                ),
              const SizedBox(height: 4),
              if (_details != null)
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${_details!.voteAverage.toStringAsFixed(1)} (${_details!.voteCount} votos)',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (_details?.genres != null)
                    ..._details!.genres!.map(
                      (g) => Chip(
                        label: Text(
                          g,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: Colors.white.withOpacity(0.06),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _savingFavorite ? null : _saveAsFavorite,
                    icon: _savingFavorite
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.favorite_border),
                    label: const Text('Guardar favorito'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed:
                        _details == null ? null : () => _generateSummary(_details!),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Regenerar resumen'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection() {
    if (_loadingSummary) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Generando resumen con IA...',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(minHeight: 2),
        ],
      );
    }

    if (_summary == null) {
      return const Text(
        'No pude generar un resumen por ahora.',
        style: TextStyle(color: Colors.white70),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen generado por IA:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _summary!,
          style: const TextStyle(color: Colors.white70, height: 1.3),
        ),
      ],
    );
  }

  Widget _buildSimilarSection() {
    if (_similar.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sugerencias similares:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _similar.length,
            itemBuilder: (ctx, i) {
              final movie = _similar[i];
              final posterUrl = movie.fullPosterUrl;

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () {
                    // Navegar a otra ficha de detalle
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 350),
                        pageBuilder: (_, animation, __) => FadeTransition(
                          opacity: animation,
                          child: MovieDetailScreen(
                            tmdbId: movie.id,
                            initialTitle: movie.title,
                            initialPosterUrl: posterUrl,
                            baseMovie: Movie(
                              id: movie.id,
                              title: movie.title,
                              overview: movie.overview,
                              posterPath: movie.posterPath,
                              releaseDate: movie.releaseDate,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AspectRatio(
                          aspectRatio: 2 / 3,
                          child: posterUrl != null
                              ? Image.network(
                                  posterUrl,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey.shade900,
                                  child: const Center(
                                    child: Icon(
                                      Icons.movie_creation_outlined,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 120,
                        child: Text(
                          movie.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      appBar: AppBar(
        title: Text(_details?.title ?? widget.initialTitle),
      ),
      body: AnimatedSwitcher(
        duration: 300.ms,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _details == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Ocurrió un error al cargar los datos de la película:\n$_error',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final content = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context)
                              .animate()
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: 0.05, curve: Curves.easeOut),
                          const SizedBox(height: 24),
                          _buildSummarySection()
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 100.ms)
                              .slideY(begin: 0.05),
                          const SizedBox(height: 24),
                          _buildSimilarSection()
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 150.ms),
                          const SizedBox(height: 24),
                        ],
                      );

                      if (!isWide) {
                        // Layout vertical (móvil)
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: content,
                        );
                      } else {
                        // Layout más ancho (tablet / web)
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 24,
                          ),
                          child: content,
                        );
                      }
                    },
                  ),
      ),
    );
  }
}
