import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/favorite_model.dart';
import '../../bloc/movie/movie_bloc.dart';
import '../../bloc/movie/movie_event.dart';
import '../../bloc/movie/movie_state.dart';
import '../../bloc/favorites/favorites_cubit.dart';
import '../../widgets/favorite_item_card.dart';
import '../../widgets/app_network_image.dart';

// Pantalla de películas favoritas
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    context.read<FavoritesCubit>().loadFavorites();
  }

  // Mostrar detalles de película favorita
  void _showMovieDetails(int movieId) {
    context.read<MovieBloc>().add(MovieDetailsRequested(movieId));
    _showDetailsBottomSheet();
  }

  // Eliminar de favoritos
  void _removeFromFavorites(int movieId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.secondaryBlack,
        title: Text(
          '¿Eliminar de favoritos?',
          style: TextStyle(color: AppColors.pureWhite),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar esta película de tus favoritos?',
          style: TextStyle(color: AppColors.softWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.grayWhite),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<FavoritesCubit>().removeFavorite(movieId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Eliminado de favoritos'),
                  backgroundColor: AppColors.primaryRed,
                ),
              );
            },
            child: Text(
              'Eliminar',
              style: TextStyle(color: AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );
  }

  // Mostrar bottom sheet con detalles
  void _showDetailsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocBuilder<MovieBloc, MovieState>(
        builder: (context, state) {
          if (state is MovieDetailsSuccess) {
            return _buildDetailsSheet(state);
          } else if (state is MovieLoading) {
            return _buildLoadingSheet();
          }
          return const SizedBox();
        },
      ),
    );
  }

  // Sheet con detalles de película
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
              // Indicador de arrastre
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

              // Poster y título
              if (movie.fullPosterUrl != null)
                AppNetworkImage(
                  imageUrl: movie.fullPosterUrl,
                  width: double.infinity,
                  height: 300,
                  borderRadius: BorderRadius.circular(12),
                  fit: BoxFit.contain,
                ).animate().fadeIn().scale(),

              const SizedBox(height: 16),

              Text(
                movie.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pureWhite,
                ),
              ),

              const SizedBox(height: 8),

              // Valoración y fecha
              Row(
                children: [
                  Icon(Icons.star, color: AppColors.primaryRed, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${movie.voteAverage.toStringAsFixed(1)}/10',
                    style: TextStyle(
                      color: AppColors.softWhite,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (movie.releaseDate != null) ...[
                    Icon(Icons.calendar_today, 
                         color: AppColors.grayWhite, 
                         size: 16),
                    const SizedBox(width: 4),
                    Text(
                      movie.releaseDate!,
                      style: TextStyle(color: AppColors.softWhite),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // Resumen de IA
              Text(
                'Resumen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryRed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.aiSummary,
                style: TextStyle(
                  color: AppColors.softWhite,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 16),

              // Sinopsis
              Text(
                'Sinopsis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryRed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                movie.overview,
                style: TextStyle(
                  color: AppColors.softWhite,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              // Reparto
              if (movie.cast != null && movie.cast!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Reparto Principal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryRed,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: movie.cast!.length,
                    itemBuilder: (context, index) {
                      final actor = movie.cast![index];
                      return Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: AppColors.tertiaryBlack,
                              backgroundImage: actor.fullProfileUrl != null
                                  ? NetworkImage(actor.fullProfileUrl!)
                                  : null,
                              child: actor.fullProfileUrl == null
                                  ? Icon(Icons.person, 
                                         color: AppColors.grayWhite)
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              actor.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.softWhite,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Películas similares
              if (state.similarMovies.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Películas Similares',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryRed,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.similarMovies.length,
                    itemBuilder: (context, index) {
                      final similar = state.similarMovies[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showMovieDetails(similar.id);
                        },
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppNetworkImage(
                                imageUrl: similar.fullPosterUrl,
                                width: 120,
                                height: 140,
                                borderRadius: BorderRadius.circular(8),
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                similar.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.softWhite,
                                  fontSize: 12,
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
            ],
          ),
        );
      },
    );
  }

  // Sheet de carga
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: BlocConsumer<FavoritesCubit, FavoritesState>(
        listener: (context, state) {
          // Sin acciones específicas aquí; mostramos snackbars al eliminar
        },
        builder: (context, state) {
          if (state is FavoritesLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryRed,
                ),
              ),
            );
          }

          if (state is FavoritesLoaded) {
            if (state.favorites.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async => context.read<FavoritesCubit>().loadFavorites(),
              color: AppColors.primaryRed,
              backgroundColor: AppColors.secondaryBlack,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: state.favorites.length,
                itemBuilder: (context, index) {
                  final favorite = state.favorites[index];
                  return FavoriteItemCard(
                    favorite: favorite,
                    onTap: () => _showMovieDetails(favorite.movieId),
                    onRemove: () => _removeFromFavorites(favorite.movieId),
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 100 * index))
                      .scale(delay: Duration(milliseconds: 100 * index));
                },
              ),
            );
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  // Estado vacío
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: AppColors.grayWhite,
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes favoritos aún',
            style: TextStyle(
              fontSize: 20,
              color: AppColors.softWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega películas desde el chat',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grayWhite,
            ),
          ),
        ],
      ).animate().fadeIn().scale(),
    );
  }
}
