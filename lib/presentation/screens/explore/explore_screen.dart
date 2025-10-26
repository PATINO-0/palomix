import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../bloc/movie/movie_bloc.dart';
import '../../bloc/movie/movie_event.dart';
import '../../bloc/movie/movie_state.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/app_network_image.dart';
import '../../../data/models/movie_model.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollDebounceTimer;

  // IDs de géneros populares
  final Map<String, int> genres = {
    'Acción': 28,
    'Comedia': 35,
    'Drama': 18,
    'Terror': 27,
    'Romance': 10749,
    'Ciencia Ficción': 878,
    'Aventura': 12,
    'Animación': 16,
  };

  @override
  void initState() {
    super.initState();
    // Cargar todo el contenido de explorar
    context.read<MovieBloc>().add(ExploreContentRequested());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollDebounceTimer?.cancel();
    super.dispose();
  }

  void _showMovieDetails(int movieId) {
    context.read<MovieBloc>().add(MovieDetailsRequested(movieId));
    _showDetailsBottomSheet();
  }

  void _showDetailsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BlocBuilder<MovieBloc, MovieState>(
          builder: (context, state) {
            if (state is MovieDetailsSuccess) {
              return _buildDetailsSheet(state);
            }
            return _buildLoadingSheet();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<MovieBloc>().add(ExploreContentRequested());
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Contenido principal
            BlocBuilder<MovieBloc, MovieState>(
              builder: (context, state) {
                if (state is MovieLoading) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                      ),
                    ),
                  );
                }

                if (state is MovieError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.primaryRed,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${state.message}',
                            style: TextStyle(color: AppColors.pureWhite),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<MovieBloc>().add(ExploreContentRequested());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                            ),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is ExploreContentSuccess) {
                  return SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 16),
                      
                      // Sección de Trending
                      if (state.trendingMovies.isNotEmpty) ...[
                        _buildSectionHeader('🔥 Tendencias'),
                        _buildHorizontalMovieList(state.trendingMovies),
                        const SizedBox(height: 24),
                      ],

                      // Sección de Top Rated
                      if (state.topRatedMovies.isNotEmpty) ...[
                        _buildSectionHeader('⭐ Mejor Valoradas'),
                        _buildHorizontalMovieList(state.topRatedMovies),
                        const SizedBox(height: 24),
                      ],

                      // Sección de Géneros
                      _buildSectionHeader('🎭 Explorar por Género'),
                      _buildGenreGrid(),
                      const SizedBox(height: 24),

                      // Sección de Recomendaciones Personalizadas
                      if (state.personalizedMovies.isNotEmpty) ...[
                        _buildSectionHeader('💡 Para Ti'),
                        if ((state.aiRecommendations?.isNotEmpty ?? false))
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryBlack,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primaryRed,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                state.aiRecommendations!,
                                style: TextStyle(
                                  color: AppColors.grayWhite,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        _buildHorizontalMovieList(state.personalizedMovies),
                        const SizedBox(height: 24),
                      ],

                      // Padding inferior
                      const SizedBox(height: 100),
                    ]),
                  );
                }

                return SliverFillRemaining(
                  child: _buildEmptyState(),
                );
              },
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
        style: TextStyle(
          color: AppColors.pureWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHorizontalMovieList(List<MovieModel> movies) {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            child: MovieCard(
              movie: movies[index],
              onTap: () => _showMovieDetails(movies[index].id),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 80 * index))
                .scale(delay: Duration(milliseconds: 80 * index)),
          );
        },
      ),
    );
  }

  Widget _buildGenreGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: genres.length,
        itemBuilder: (context, index) {
          final genreName = genres.keys.elementAt(index);
          final genreId = genres[genreName]!;
          
          return GestureDetector(
            onTap: () {
              _showGenreMovies(genreName, genreId);
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryRed,
                    AppColors.primaryRed.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryRed, width: 1),
              ),
              child: Center(
                child: Text(
                  genreName,
                  style: TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showGenreMovies(String genreName, int genreId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryBlack,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return BlocProvider.value(
            value: context.read<MovieBloc>()..add(MoviesByGenreRequested(genreId: genreId, genreName: genreName)),
            child: BlocBuilder<MovieBloc, MovieState>(
              builder: (context, state) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlack,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      // Handle
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.grayWhite,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Películas de $genreName',
                                style: TextStyle(
                                  color: AppColors.pureWhite,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.close, color: AppColors.pureWhite),
                            ),
                          ],
                        ),
                      ),
                      
                      Divider(color: AppColors.grayWhite),
                      
                      // Content
                      Expanded(
                        child: _buildGenreContent(state, scrollController),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildGenreContent(MovieState state, ScrollController scrollController) {
    if (state is MovieLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
        ),
      );
    }

    if (state is MovieError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.primaryRed, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.message}',
              style: TextStyle(color: AppColors.pureWhite),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (state is MoviesByGenreSuccess) {
       return NotificationListener<ScrollNotification>(
         onNotification: (notification) {
           if (notification.metrics.pixels >=
               notification.metrics.maxScrollExtent - 200 && 
               state.hasMore && 
               !state.isLoadingMore) {
             
             // Cancelar timer anterior si existe
             _scrollDebounceTimer?.cancel();
             
             // Crear nuevo timer con debounce de 300ms
             _scrollDebounceTimer = Timer(const Duration(milliseconds: 300), () {
               if (mounted) {
                 context.read<MovieBloc>().add(
                   MoviesByGenreLoadMore(
                     genreId: state.genreId,
                     genreName: state.genreName,
                     nextPage: state.currentPage + 1,
                   ),
                 );
               }
             });
           }
           return false;
         },
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return MovieCard(
                      movie: state.movies[index],
                      onTap: () => _showMovieDetails(state.movies[index].id),
                    );
                  },
                  childCount: state.movies.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: state.isLoadingMore
                    ? Center(
                        child: SizedBox(
                          height: 32,
                          width: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                          ),
                        ),
                      )
                    : !state.hasMore && state.movies.isNotEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'No hay más resultados',
                                style: TextStyle(
                                  color: AppColors.grayWhite,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
       );
    }

    return Center(
      child: Text(
        'No hay películas disponibles',
        style: TextStyle(color: AppColors.pureWhite),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_movies, size: 48, color: AppColors.grayWhite),
          const SizedBox(height: 12),
          Text(
            'No hay contenido para explorar todavía',
            style: TextStyle(color: AppColors.grayWhite),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSheet(MovieDetailsSuccess state) {
    final movie = state.movie;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.primaryBlack,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.grayWhite,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              if (movie.fullPosterUrl != null)
                AppNetworkImage(
                  imageUrl: movie.fullPosterUrl,
                  width: double.infinity,
                  height: 300,
                  borderRadius: BorderRadius.circular(12),
                  fit: BoxFit.contain,
                ),

              const SizedBox(height: 16),
              Text(
                movie.title,
                style: TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (movie.overview.isNotEmpty)
                Text(
                  movie.overview,
                  style: TextStyle(color: AppColors.grayWhite, fontSize: 14),
                ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.star, color: AppColors.primaryRed),
                  const SizedBox(width: 6),
                  Text(
                    '${movie.voteAverage.toStringAsFixed(1)} / 10',
                    style: TextStyle(color: AppColors.pureWhite),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              if (state.similarMovies.isNotEmpty) ...[
                Text(
                  'Similares',
                  style: TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.similarMovies.length,
                    itemBuilder: (context, index) {
                      final similar = state.similarMovies[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          _showMovieDetails(similar.id);
                        },
                        child: Container(
                          width: 130,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppNetworkImage(
                                imageUrl: similar.fullPosterUrl,
                                width: 130,
                                height: 160,
                                borderRadius: BorderRadius.circular(8),
                                fit: BoxFit.cover,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingSheet() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
        ),
      ),
    );
  }
}