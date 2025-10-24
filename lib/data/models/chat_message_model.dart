import 'package:equatable/equatable.dart';
import 'movie_model.dart';
// Modelo para mensajes del chat
class ChatMessageModel extends Equatable {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MovieModel? movieData;
  final List<MovieModel>? recommendations;
  
  const ChatMessageModel({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.movieData,
    this.recommendations,
  });
  
  @override
  List<Object?> get props => [
        id,
        content,
        type,
        timestamp,
        movieData,
        recommendations,
      ];
}

enum MessageType {
  user,      // Mensaje del usuario
  assistant, // Respuesta de la IA
  movie,     // Información de película
  error,     // Mensaje de error
}
