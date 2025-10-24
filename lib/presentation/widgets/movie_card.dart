import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/movie_model.dart';
import '../bloc/movie/movie_bloc.dart';
import '../bloc/movie/movie_event.dart';

// Tarjeta de película
class MovieCard extends StatelessWidget {
  final MovieModel movie;
  final VoidCallback? onTap;

  const MovieCard({
    Key? key,
    required this.movie,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondaryBlack,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryRed.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            if (movie.fullPosterUrl != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  movie.fullPosterUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    movie.title,
                    style: TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Valoración y fecha
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: AppColors.primaryRed,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        movie.voteAverage.toStringAsFixed(1),
                        style: TextStyle(
                          color: AppColors.softWhite,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (movie.releaseDate != null)
                        Text(
                          movie.releaseDate!.split('-')[0],
                          style: TextStyle(
                            color: AppColors.grayWhite,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Botón de favoritos
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<MovieBloc>().add(
                              AddToFavoritesRequested(
                                movieId: movie.id,
                                movieTitle: movie.title,
                                posterPath: movie.posterPath,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
