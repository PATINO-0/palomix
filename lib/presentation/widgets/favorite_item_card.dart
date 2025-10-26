import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/favorite_model.dart';

// Tarjeta de ítem favorito
class FavoriteItemCard extends StatelessWidget {
  final FavoriteModel favorite;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const FavoriteItemCard({
    Key? key,
    required this.favorite,
    required this.onTap,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondaryBlack,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryRed.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster con botón de eliminar
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: favorite.posterPath != null
                      ? CachedNetworkImage(
                          imageUrl:
                              'https://image.tmdb.org/t/p/w500${favorite.posterPath}',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.tertiaryBlack,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryRed,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.tertiaryBlack,
                            child: Icon(
                              Icons.movie,
                              color: AppColors.grayWhite,
                              size: 40,
                            ),
                          ),
                        )
                      : Container(
                          height: 180,
                          color: AppColors.tertiaryBlack,
                          child: Icon(
                            Icons.movie,
                            color: AppColors.grayWhite,
                            size: 40,
                          ),
                        ),
                ),

                // Botón de eliminar
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.close,
                        color: AppColors.pureWhite,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Título
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                favorite.movieTitle,
                style: TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
