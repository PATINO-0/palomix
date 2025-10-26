import 'dart:async';
import '../../../core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/movie/movie_bloc.dart';
import '../../bloc/movie/movie_event.dart';
import '../../bloc/movie/movie_state.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/app_network_image.dart';

class GenresScreen extends StatefulWidget {
  const GenresScreen({Key? key}) : super(key: key);

  @override
  State<GenresScreen> createState() => _GenresScreenState();
}

class _GenresScreenState extends State<GenresScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollDebounceTimer;

  // IDs de géneros populares (mismo set que ExploreScreen)
  final Map<String, int> genres = const {
    'Acción': 28,
    'Comedia': 35,
    'Drama': 18,
    'Terror': 27,
    'Romance': 10749,
    'Ciencia Ficción': 878,
    'Aventura': 12,
    'Animación': 16,
    'Crimen': 80,
    'Documental': 99,
    'Familia': 10751,
    'Fantasía': 14,
    'Historia': 36,
    'Misterio': 9648,
    'Música': 10402,
    'Guerra': 10752,
    'Western': 37,
    'Thriller': 53,
  };

  String? _selectedGenreName;
  int? _selectedGenreId;

  void _selectGenre(String name, int id) {
    setState(() {
      _selectedGenreName = name;
      _selectedGenreId = id;
    });
    context.read<MovieBloc>().add(MoviesByGenreRequested(genreId: id, genreName: name));
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
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'Explorar por Género',
                    style: TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final genreName = genres.keys.elementAt(index);
                      final genreId = genres[genreName]!;
                      final isSelected = _selectedGenreId == genreId;
                      return GestureDetector(
                        onTap: () => _selectGenre(genreName, genreId),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                isSelected ? AppColors.primaryRed : AppColors.secondaryBlack,
                                AppColors.primaryRed.withValues(alpha: isSelected ? 0.7 : 0.3),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryRed : AppColors.grayWhite,
                              width: 1,
                            ),
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
                    childCount: genres.length,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedGenreName != null
                              ? 'Películas de ${_selectedGenreName!}'
                              : 'Selecciona un género',
                          style: TextStyle(
                            color: AppColors.pureWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_selectedGenreId != null)
                        IconButton(
                          onPressed: () {
                            context.read<MovieBloc>().add(
                                  MoviesByGenreRequested(
                                    genreId: _selectedGenreId!,
                                    genreName: _selectedGenreName!,
                                  ),
                                );
                          },
                          icon: Icon(Icons.refresh, color: AppColors.pureWhite),
                        ),
                    ],
                  ),
                ),
              ),

              BlocBuilder<MovieBloc, MovieState>(
                builder: (context, state) {
                  if (_selectedGenreId == null) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Elige un género para ver películas.',
                          style: TextStyle(color: AppColors.grayWhite),
                        ),
                      ),
                    );
                  }

                  if (state is MovieLoading) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                          ),
                        ),
                      ),
                    );
                  }

                  if (state is MovieError) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.error_outline, color: AppColors.primaryRed, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              state.message,
                              style: TextStyle(color: AppColors.pureWhite),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is MoviesByGenreSuccess) {
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification.metrics.pixels >=
                                      notification.metrics.maxScrollExtent - 200 &&
                                  state.hasMore &&
                                  !state.isLoadingMore) {
                                _scrollDebounceTimer?.cancel();
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
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.68,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: state.movies.length,
                              itemBuilder: (context, index) {
                                final movie = state.movies[index];
                                return MovieCard(
                                  movie: movie,
                                  onTap: () => _showMovieDetails(movie.id),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: state.isLoadingMore
                                  ? SizedBox(
                                      height: 32,
                                      width: 32,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                                      ),
                                    )
                                  : !state.hasMore && state.movies.isNotEmpty
                                      ? Text(
                                          'No hay más resultados',
                                          style: TextStyle(color: AppColors.grayWhite),
                                        )
                                      : const SizedBox.shrink(),
                            ),
                          ),
                        ]),
                      ),
                    );
                  }

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'No hay resultados para este género',
                        style: TextStyle(color: AppColors.grayWhite),
                      ),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ],
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