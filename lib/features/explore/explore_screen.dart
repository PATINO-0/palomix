import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/config.dart';
import '../../core/models/movie.dart';
import '../../data/models/movie_model.dart';
import '../../data/services/tmdb_service.dart';
import '../movie_detail/movie_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final _tmdb = TmdbService();
  List<MovieModel> _trendingMovies = [];
  List<MovieModel> _topRatedMovies = [];
  List<MovieModel> _searchResults = [];
  bool _loading = true;
  bool _searching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String? _error;
  late AnimationController _headerAnimationController;
  Timer? _debounceTimer;
  bool _isSearchMode = false;

  // Géneros populares con emojis
  final List<Map<String, dynamic>> genres = [
    {'name': 'Acción', 'id': 28, 'emoji': '💥', 'color': const Color(0xFFDC2626)},
    {'name': 'Comedia', 'id': 35, 'emoji': '😂', 'color': const Color(0xFFF59E0B)},
    {'name': 'Drama', 'id': 18, 'emoji': '🎭', 'color': const Color(0xFF8B5CF6)},
    {'name': 'Terror', 'id': 27, 'emoji': '👻', 'color': const Color(0xFF1F2937)},
    {'name': 'Romance', 'id': 10749, 'emoji': '💕', 'color': const Color(0xFFEC4899)},
    {'name': 'Sci-Fi', 'id': 878, 'emoji': '🚀', 'color': const Color(0xFF3B82F6)},
    {'name': 'Aventura', 'id': 12, 'emoji': '🗺️', 'color': const Color(0xFF10B981)},
    {'name': 'Animación', 'id': 16, 'emoji': '🎨', 'color': const Color(0xFFFF6B6B)},
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    
    _searchCtrl.addListener(_onSearchChanged);
    _loadContent();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();

    if (_searchCtrl.text.trim().isEmpty) {
      setState(() {
        _isSearchMode = false;
        _searchResults = [];
        _searching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  Future<void> _loadContent() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trending = await _tmdb.getTrendingMovies();
      final topRated = await _tmdb.getTopRatedMovies();
      if (mounted) {
        setState(() {
          _trendingMovies = trending;
          _topRatedMovies = topRated;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar contenido. Verifica tu conexión.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _performSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _searching = true;
      _isSearchMode = true;
      _error = null;
    });

    try {
      final list = await _tmdb.searchMovies(query);
      if (mounted) {
        setState(() {
          _searchResults = list;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error en la búsqueda. Intenta de nuevo.';
          _searchResults = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _searching = false;
        });
      }
    }
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _isSearchMode = false;
      _searchResults = [];
      _searching = false;
      _error = null;
    });
  }

  void _openDetails(MovieModel movie) {
    final posterUrl = movie.fullPosterUrl;
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

  void _showGenreMovies(String genreName, int genreId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildGenreBottomSheet(genreName, genreId),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0000),
            Color(0xFF000000),
            Color(0xFF2D0A0A),
          ],
        ),
      ),
      child: Stack(
        children: [
          _buildBackgroundDecorations(),
          SafeArea(
            child: Column(
              children: [
                _buildModernHeader(),
                _buildSearchBar(),
                _buildGenreChips(), // ⭐ Chips de género en la parte superior
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFDC2626).withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                duration: 4000.ms,
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
              ),
        ),
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.orange.withOpacity(0.1), Colors.transparent],
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                duration: 5000.ms,
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.3, 1.3),
              ),
        ),
      ],
    );
  }

  Widget _buildModernHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Colors.orange],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.explore_rounded,
                    color: Colors.white, size: 28),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                      duration: 2000.ms, color: Colors.white.withOpacity(0.3)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFDC2626), Colors.orange],
                      ).createShader(bounds),
                      child: const Text(
                        'Explorar',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isSearchMode
                          ? 'Resultados de búsqueda'
                          : 'Descubre películas increíbles',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isSearchMode && _searchResults.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFDC2626).withOpacity(0.3),
                        Colors.orange.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFDC2626).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_searchResults.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0, 0), curve: Curves.elasticOut),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.3, end: 0, curve: Curves.easeOut);
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.08),
          ],
        ),
        border: Border.all(
          color: _isSearchMode
              ? const Color(0xFFDC2626).withOpacity(0.5)
              : Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _isSearchMode
                ? const Color(0xFFDC2626).withOpacity(0.2)
                : Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                if (_searching)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .rotate(duration: 1000.ms)
                else
                  Icon(
                    _isSearchMode ? Icons.search : Icons.search_rounded,
                    color: _isSearchMode
                        ? const Color(0xFFDC2626)
                        : const Color(0xFFDC2626).withOpacity(0.7),
                    size: 24,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Buscar películas en tiempo real...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear,
                        color: Colors.white.withOpacity(0.7), size: 20),
                    onPressed: _clearSearch,
                  )
                      .animate()
                      .fadeIn(duration: 200.ms)
                      .scale(begin: const Offset(0.5, 0.5)),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 600.ms)
        .slideY(begin: -0.3, end: 0);
  }

  // ⭐ Nuevo widget de chips de género en la parte superior
  Widget _buildGenreChips() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: genres.length,
        itemBuilder: (context, index) {
          final genre = genres[index];
          return GestureDetector(
            onTap: () => _showGenreMovies(genre['name'], genre['id']),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (genre['color'] as Color).withOpacity(0.8),
                    (genre['color'] as Color).withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (genre['color'] as Color).withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    genre['emoji'],
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    genre['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate(delay: (80 * index).ms)
              .fadeIn(duration: 600.ms)
              .slideX(begin: 0.3, end: 0, curve: Curves.easeOut);
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_loading && !_isSearchMode) {
      return _buildLoadingState();
    }

    if (_error != null && !_isSearchMode) {
      return _buildErrorState();
    }

    if (_isSearchMode) {
      if (_searching && _searchResults.isEmpty) {
        return _buildSearchingState();
      }
      
      if (_searchResults.isEmpty && !_searching) {
        return _buildNoResultsState();
      }

      return _buildSearchResults();
    }

    return RefreshIndicator(
      onRefresh: _loadContent,
      color: const Color(0xFFDC2626),
      backgroundColor: const Color(0xFF1A0000),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_trendingMovies.isNotEmpty) ...[
              _buildSectionHeader('🔥 Tendencias'),
              _buildHorizontalMovieList(_trendingMovies),
              const SizedBox(height: 24),
            ],
            if (_topRatedMovies.isNotEmpty) ...[
              _buildSectionHeader('⭐ Mejor Valoradas'),
              _buildHorizontalMovieList(_topRatedMovies),
              const SizedBox(height: 24),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMoviePoster({
    required String? posterUrl,
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: posterUrl != null
          ? Image.network(
              posterUrl,
              fit: BoxFit.cover,
              width: width,
              height: height,
              errorBuilder: (context, error, stackTrace) {
                return _buildPalomixPlaceholder(width, height);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: width,
                  height: height,
                  color: Colors.grey.shade900,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFDC2626),
                      ),
                    ),
                  ),
                );
              },
            )
          : _buildPalomixPlaceholder(width, height),
    );
  }

  Widget _buildPalomixPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0000),
            Color(0xFF000000),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/palomix.png',
              width: width * 0.6,
              height: height * 0.4,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.movie_filter_rounded,
                  size: width * 0.4,
                  color: const Color(0xFFDC2626).withOpacity(0.5),
                );
              },
            )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                  duration: 2000.ms,
                  color: Colors.white.withOpacity(0.1),
                ),
            const SizedBox(height: 8),
            Text(
              'PALOMIX',
              style: TextStyle(
                color: const Color(0xFFDC2626).withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildHorizontalMovieList(List<MovieModel> movies) {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          return _buildMovieCard(movies[index], index);
        },
      ),
    );
  }

  Widget _buildMovieCard(MovieModel movie, int index) {
    final posterUrl = movie.fullPosterUrl;

    return GestureDetector(
      onTap: () => _openDetails(movie),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  _buildMoviePoster(
                    posterUrl: posterUrl,
                    width: 150,
                    height: 200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  if (movie.voteAverage > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.amber.withOpacity(0.5), width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              movie.voteAverage.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              movie.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (80 * index).ms)
        .fadeIn(duration: 600.ms)
        .slideX(begin: 0.3, end: 0, curve: Curves.easeOut);
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.search_rounded,
                  color: Color(0xFFDC2626), size: 24),
              const SizedBox(width: 12),
              Text(
                '${_searchResults.length} resultados',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 3,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final movie = _searchResults[index];
              final posterUrl = movie.fullPosterUrl;

              return GestureDetector(
                onTap: () => _openDetails(movie),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: _buildMoviePoster(
                    posterUrl: posterUrl,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
                  .animate(delay: (50 * index).ms)
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.8, 0.8));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFDC2626).withOpacity(0.2),
                  Colors.orange.withOpacity(0.2),
                ],
              ),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
              strokeWidth: 3,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 2000.ms),
          const SizedBox(height: 20),
          Text(
            'Buscando "${_searchCtrl.text}"...',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(duration: 1000.ms)
              .then()
              .fadeOut(duration: 1000.ms),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFDC2626).withOpacity(0.2),
                  Colors.orange.withOpacity(0.2),
                ],
              ),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
              strokeWidth: 3,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 2000.ms),
          const SizedBox(height: 20),
          const Text(
            'Cargando películas...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(duration: 1000.ms)
              .then()
              .fadeOut(duration: 1000.ms),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFDC2626).withOpacity(0.2),
                  Colors.orange.withOpacity(0.2),
                ],
              ),
            ),
            child: const Icon(Icons.error_outline,
                color: Color(0xFFDC2626), size: 60),
          ),
          const SizedBox(height: 20),
          Text(
            _error ?? 'Error desconocido',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _loadContent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDC2626), Colors.orange],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFDC2626).withOpacity(0.2),
                  Colors.orange.withOpacity(0.2),
                ],
              ),
            ),
            child: const Icon(Icons.search_off_rounded,
                size: 80, color: Color(0xFFDC2626)),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),
          const SizedBox(height: 24),
          const Text(
            'No encontramos resultados',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Intenta con: "${_searchCtrl.text}"',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreBottomSheet(String genreName, int genreId) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0000), Color(0xFF000000)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFDC2626), Colors.orange],
                        ).createShader(bounds),
                        child: Text(
                          'Películas de $genreName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white.withOpacity(0.2)),
              Expanded(
                child: FutureBuilder<List<MovieModel>>(
                  future: _tmdb.getMoviesByGenre(genreId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error al cargar películas',
                          style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        ),
                      );
                    }

                    final movies = snapshot.data ?? [];
                    if (movies.isEmpty) {
                      return Center(
                        child: Text(
                          'No hay películas disponibles',
                          style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        ),
                      );
                    }

                    return GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: movies.length,
                      itemBuilder: (context, index) {
                        final movie = movies[index];
                        final posterUrl = movie.fullPosterUrl;

                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _openDetails(movie);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFDC2626).withOpacity(0.2),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: _buildMoviePoster(
                              posterUrl: posterUrl,
                              width: double.infinity,
                              height: double.infinity,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                            .animate(delay: (50 * index).ms)
                            .fadeIn(duration: 400.ms)
                            .scale(begin: const Offset(0.8, 0.8));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
