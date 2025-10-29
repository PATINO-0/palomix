import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/movie/movie_bloc.dart';
import '../../bloc/movie/movie_event.dart';
import '../../bloc/movie/movie_state.dart';
import '../../widgets/movie_card.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/app_network_image.dart';
import '../../../data/models/movie_model.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({Key? key}) : super(key: key);

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  List<MovieModel> _cachedRecommendations = [];
  String _cachedAiText = '';

  @override
  void initState() {
    super.initState();
    // Disparar la carga de recomendaciones personalizadas
    context.read<MovieBloc>().add(PersonalizedRecommendationsRequested());
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
    return BlocListener<MovieBloc, MovieState>(
      listener: (context, state) {
        if (state is PersonalizedRecommendationsSuccess) {
          _cachedRecommendations = state.movies;
          _cachedAiText = state.aiRecommendations;
          setState(() {});
        }
      },
      child: BlocBuilder<MovieBloc, MovieState>(
        builder: (context, state) {
          if (state is MovieLoading && _cachedRecommendations.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
              ),
            );
          }

          if (state is MovieError && _cachedRecommendations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: AppColors.primaryRed, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      style: TextStyle(color: AppColors.pureWhite),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.read<MovieBloc>().add(PersonalizedRecommendationsRequested()),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primaryRed),
                        foregroundColor: AppColors.pureWhite,
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_cachedRecommendations.isNotEmpty) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recomendaciones para ti',
                          style: TextStyle(
                            color: AppColors.pureWhite,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_cachedAiText.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryBlack,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primaryRed, width: 1),
                            ),
                            child: Text(
                              _cachedAiText,
                              style: TextStyle(color: AppColors.grayWhite, fontSize: 14, height: 1.5),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          'Películas sugeridas',
                          style: TextStyle(
                            color: AppColors.pureWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final movie = _cachedRecommendations[index];
                        return MovieCard(
                          movie: movie,
                          onTap: () => _showMovieDetails(movie.id),
                        );
                      },
                      childCount: _cachedRecommendations.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: const SizedBox(height: 100)),
              ],
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No hay recomendaciones disponibles',
                  style: TextStyle(color: AppColors.grayWhite),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.read<MovieBloc>().add(PersonalizedRecommendationsRequested()),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primaryRed),
                    foregroundColor: AppColors.pureWhite,
                  ),
                  child: const Text('Obtener recomendaciones'),
                ),
              ],
            ),
          );
        },
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