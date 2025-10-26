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

class TopScreen extends StatefulWidget {
  const TopScreen({Key? key}) : super(key: key);

  @override
  State<TopScreen> createState() => _TopScreenState();
  Widget _buildDetailsSheet(MovieDetailsSuccess state) {
    final movie = state.movie;

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.6,
        maxChildSize: 0.98,
        expand: false,
        builder: (context, scrollController) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primaryBlack,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.grayWhite.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppNetworkImage(
                          imageUrl: movie.fullPosterUrl,
                          width: 120,
                          height: 180,
                          borderRadius: BorderRadius.circular(12),
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movie.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.star, color: Colors.amber[400], size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    movie.voteAverage.toStringAsFixed(1),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    movie.releaseDate?.split('-').first ?? 'N/A',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: -8,
                                children: (movie.genres ?? []).map((g) {
                                  return Chip(
                                    label: Text(g, style: const TextStyle(color: Colors.white)),
                                    backgroundColor: AppColors.secondaryBlack,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.read<MovieBloc>().add(
                                    AddToFavoritesRequested(
                                      movieId: movie.id,
                                      movieTitle: movie.title,
                                      posterPath: movie.posterPath,
                                    ),
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Agregado a favoritos ✓'),
                                  backgroundColor: AppColors.primaryRed,
                                ),
                              );
                            },
                            icon: const Icon(Icons.favorite_border, size: 18),
                            label: const Text('Agregar a Favoritos'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              foregroundColor: AppColors.pureWhite,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.read<MovieBloc>().add(PersonalizedRecommendationsRequested());
                              _showRecommendationsBottomSheet(context);
                            },
                            icon: const Icon(Icons.lightbulb_outline, size: 18),
                            label: const Text('Ver recomendaciones'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.primaryRed),
                              foregroundColor: AppColors.pureWhite,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sinopsis',
                      style: TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie.overview.isNotEmpty ? movie.overview : 'Descripción no disponible.',
                      style: TextStyle(color: AppColors.grayWhite),
                    ),
                    const SizedBox(height: 16),
                    if (state.similarMovies.isNotEmpty) ...[
                      Text(
                        'Similares',
                        style: TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: state.similarMovies.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final similar = state.similarMovies[index];
                            return GestureDetector(
                              onTap: () {
                                context.read<MovieBloc>().add(MovieDetailsRequested(similar.id));
                              },
                              child: Column(
                                children: [
                                  AppNetworkImage(
                                    imageUrl: similar.fullPosterUrl,
                                    width: 110,
                                    height: 150,
                                    borderRadius: BorderRadius.circular(10),
                                    fit: BoxFit.cover,
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: 110,
                                    child: Text(
                                      similar.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: AppColors.grayWhite),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingSheet() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SizedBox(
        height: 280,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Cargando detalles...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  void _showRecommendationsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BlocBuilder<MovieBloc, MovieState>(
          builder: (context, state) {
            if (state is PersonalizedRecommendationsSuccess) {
              return _buildRecommendationsSheet(state);
            }
            return _buildLoadingSheet();
          },
        );
      },
    );
  }

  Widget _buildRecommendationsSheet(PersonalizedRecommendationsSuccess state) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.primaryBlack,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
              if (state.aiRecommendations.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBlack,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryRed, width: 1),
                  ),
                  child: Text(
                    state.aiRecommendations,
                    style: TextStyle(color: AppColors.softWhite, fontSize: 14, height: 1.5),
                  ),
                ),
              ],
              Text(
                'Recomendaciones para ti',
                style: TextStyle(color: AppColors.pureWhite, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.movies.length,
                  itemBuilder: (context, index) {
                    final rec = state.movies[index];
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      child: MovieCard(
                        movie: rec,
                        onTap: () {
                          Navigator.pop(context);
                          context.read<MovieBloc>().add(MovieDetailsRequested(rec.id));
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
                        },
                      )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 80 * index))
                          .scale(delay: Duration(milliseconds: 80 * index)),
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

class _TopScreenState extends State<TopScreen> {
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
              return widget._buildDetailsSheet(state);
            }
            return widget._buildLoadingSheet();
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Cargar contenido necesario (tendencias y mejor valoradas)
    context.read<MovieBloc>().add(ExploreContentRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.secondaryBlack,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
                ),
                child: const TabBar(
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: '🔥 Tendencias'),
                    Tab(text: '⭐ Mejor Valoradas'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<MovieBloc, MovieState>(
                builder: (context, state) {
                  if (state is MovieLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                      ),
                    );
                  }

                  if (state is MovieError) {
                    return _buildErrorState(state.message);
                  }

                  if (state is ExploreContentSuccess) {
                    final trending = state.trendingMovies;
                    final topRated = state.topRatedMovies;

                    return TabBarView(
                      children: [
                        _buildGrid(trending),
                        _buildGrid(topRated),
                      ],
                    );
                  }

                  return _buildEmptyState('Cargando contenido destacado...');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<MovieModel> movies) {
    if (movies.isEmpty) {
      return _buildEmptyState('Sin contenido disponible por ahora');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return MovieCard(
          movie: movie,
          onTap: () {
            _showMovieDetails(movie.id);
          },
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: 70 * index))
            .scale(delay: Duration(milliseconds: 70 * index));
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_movies, size: 48, color: AppColors.grayWhite),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: AppColors.grayWhite),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.primaryRed, size: 48),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Error: $message',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.pureWhite),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<MovieBloc>().add(ExploreContentRequested());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}