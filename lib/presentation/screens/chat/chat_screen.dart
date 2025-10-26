import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/models/movie_model.dart';
import '../../bloc/movie/movie_bloc.dart';
import '../../bloc/movie/movie_event.dart';
import '../../bloc/movie/movie_state.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/chat_message_bubble.dart';
import '../../widgets/custom_button.dart';
import 'package:uuid/uuid.dart';

// Pantalla principal de chat con IA
class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessageModel> _messages = [];
  final _uuid = const Uuid();
  MovieModel? _currentMovie;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Agregar mensaje de bienvenida
  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessageModel(
      id: _uuid.v4(),
      content: '¡Hola! 👋 Soy tu asistente de películas. Puedes:\n\n'
          '• Buscar cualquier película o serie\n'
          '• Pedirme recomendaciones personalizadas\n'
          '• Agregar películas a tus favoritos\n\n'
          '¿Qué película te gustaría buscar hoy?',
      type: MessageType.assistant,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.insert(0, welcomeMessage);
    });
  }

  // Enviar mensaje del usuario
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = ChatMessageModel(
      id: _uuid.v4(),
      content: _messageController.text.trim(),
      type: MessageType.user,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, userMessage);
    });

    final query = _messageController.text.trim().toLowerCase();
    _messageController.clear();

    // Verificar si pide recomendaciones
    if (query.contains('recomiend') || 
        query.contains('suger') || 
        query.contains('qué ver') ||
        query.contains('que ver')) {
      context.read<MovieBloc>().add(PersonalizedRecommendationsRequested());
    } else {
      // Buscar película
      context.read<MovieBloc>().add(MovieSearchRequested(query));
    }

    _scrollToBottom();
  }

  // Scroll automático al final
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Mostrar detalles de película
  void _showMovieDetails(int movieId) {
    context.read<MovieBloc>().add(MovieDetailsRequested(movieId));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Column(
        children: [
          // Lista de mensajes
          Expanded(
            child: BlocConsumer<MovieBloc, MovieState>(
              listener: (context, state) {
                if (state is MovieSearchSuccess) {
                  _handleSearchResults(state.movies);
                } else if (state is MovieDetailsSuccess) {
                  _handleMovieDetails(state);
                } else if (state is PersonalizedRecommendationsSuccess) {
                  _handleRecommendations(state);
                } else if (state is MovieError) {
                  _handleError(state.message);
                } else if (state is AddedToFavoritesSuccess) {
                  _showSnackBar('Agregado a favoritos ✓');
                }
              },
              builder: (context, state) {
                final isLoading = state is MovieLoading;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Mostrar indicador de carga
                    if (isLoading && index == 0) {
                      return _buildLoadingIndicator();
                    }

                    final messageIndex = isLoading ? index - 1 : index;
                    final message = _messages[messageIndex];

                    return ChatMessageBubble(
                      message: message,
                      onMovieSelected: _showMovieDetails,
                    );
                  },
                );
              },
            ),
          ),

          // Campo de entrada de texto
          _buildInputField(),
        ],
      ),
    );
  }

  // Indicador de carga
  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondaryBlack,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryRed,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Buscando...',
                  style: TextStyle(color: AppColors.softWhite),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.2, end: 0);
  }

  // Campo de entrada
  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryBlack,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: AppColors.pureWhite),
                decoration: InputDecoration(
                  hintText: 'Buscar película o pedir recomendaciones...',
                  hintStyle: TextStyle(color: AppColors.grayWhite),
                  filled: true,
                  fillColor: AppColors.tertiaryBlack,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            // Botón de enviar
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryRed.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: AppColors.pureWhite,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Manejar resultados de búsqueda
  void _handleSearchResults(List<MovieModel> movies) {
    if (movies.isEmpty) {
      final message = ChatMessageModel(
        id: _uuid.v4(),
        content: 'No encontré películas con ese nombre. Intenta con otro título.',
        type: MessageType.assistant,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.insert(0, message);
      });
      return;
    }

    final message = ChatMessageModel(
      id: _uuid.v4(),
      content: 'Encontré ${movies.length} resultado${movies.length > 1 ? 's' : ''}. '
          'Selecciona una película para ver más detalles:',
      type: MessageType.assistant,
      timestamp: DateTime.now(),
      recommendations: movies.take(5).toList(),
    );

    setState(() {
      _messages.insert(0, message);
    });
    _scrollToBottom();
  }

  // Manejar detalles de película
  void _handleMovieDetails(MovieDetailsSuccess state) {
    final message = ChatMessageModel(
      id: _uuid.v4(),
      content: state.aiSummary,
      type: MessageType.movie,
      timestamp: DateTime.now(),
      movieData: state.movie,
      recommendations: state.similarMovies,
    );

    setState(() {
      _currentMovie = state.movie;
      _messages.insert(0, message);
    });
    _scrollToBottom();
  }

  // Manejar recomendaciones personalizadas
  void _handleRecommendations(PersonalizedRecommendationsSuccess state) {
    final message = ChatMessageModel(
      id: _uuid.v4(),
      content: state.aiRecommendations.isNotEmpty
          ? state.aiRecommendations
          : 'Aquí tienes algunas películas populares que podrían interesarte:',
      type: MessageType.assistant,
      timestamp: DateTime.now(),
      recommendations: state.movies,
    );

    setState(() {
      _messages.insert(0, message);
    });
    _scrollToBottom();
  }

  // Manejar errores
  void _handleError(String message) {
    final errorMessage = ChatMessageModel(
      id: _uuid.v4(),
      content: 'Lo siento, ocurrió un error: $message',
      type: MessageType.error,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, errorMessage);
    });
    _scrollToBottom();
  }

  // Mostrar snackbar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryRed,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
