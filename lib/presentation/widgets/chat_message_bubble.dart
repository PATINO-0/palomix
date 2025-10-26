import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/chat_message_model.dart';
import 'movie_card.dart';
import 'app_network_image.dart';

// Burbuja de mensaje en el chat
class ChatMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final Function(int) onMovieSelected;

  const ChatMessageBubble({
    Key? key,
    required this.message,
    required this.onMovieSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = message.type == MessageType.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Burbuja de texto
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primaryRed : AppColors.secondaryBlack,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 20),
              ),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: AppColors.pureWhite,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ).animate().fadeIn(duration: 300.ms).slideX(
                begin: isUser ? 0.2 : -0.2,
                end: 0,
                duration: 300.ms,
              ),

          // Tarjeta de película si está disponible
          if (message.movieData != null) ...[
            const SizedBox(height: 12),
            MovieCard(
              movie: message.movieData!,
              onTap: () => onMovieSelected(message.movieData!.id),
            ),
          ],

          // Lista de recomendaciones
          if (message.recommendations != null &&
              message.recommendations!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: message.recommendations!.length,
                itemBuilder: (context, index) {
                  final movie = message.recommendations![index];
                  return GestureDetector(
                    onTap: () => onMovieSelected(movie.id),
                    child: Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppNetworkImage(
                            imageUrl: movie.fullPosterUrl,
                            width: 130,
                            height: 160,
                            borderRadius: BorderRadius.circular(8),
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            movie.title,
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
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 100 * index))
                      .slideX(begin: -0.3, end: 0);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
