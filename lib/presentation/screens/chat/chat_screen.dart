import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/models/movie_model.dart';
import '../../bloc/movie/movie_bloc.dart';
import '../../bloc/movie/movie_event.dart';
import '../../bloc/movie/movie_state.dart';
import '../../widgets/chat_message_bubble.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _recommendationsScrollController = ScrollController();
  final List<ChatMessageModel> _messages = [];
  final Map<String, bool> _expandedRecommendations = {}; // Track expanded state
  final _uuid = const Uuid();
  MovieModel? _currentMovie;
  late AnimationController _fabAnimationController;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scrollController.addListener(_onScroll);
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _recommendationsScrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 300 && !_showScrollToBottom) {
      setState(() => _showScrollToBottom = true);
      _fabAnimationController.forward();
    } else if (_scrollController.offset <= 300 && _showScrollToBottom) {
      setState(() => _showScrollToBottom = false);
      _fabAnimationController.reverse();
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessageModel(
      id: _uuid.v4(),
      content: '¡Hola! 👋 Soy tu asistente cinematográfico.\n\n'
          '🎬 Busca cualquier película o serie\n'
          '✨ Pide recomendaciones personalizadas\n'
          '❤️ Guarda tus favoritas\n\n'
          '¿Qué te gustaría ver hoy?',
      type: MessageType.assistant,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.insert(0, welcomeMessage);
    });
  }

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

    if (query.contains('recomiend') || 
        query.contains('suger') || 
        query.contains('qué ver') ||
        query.contains('que ver')) {
      context.read<MovieBloc>().add(PersonalizedRecommendationsRequested());
    } else {
      context.read<MovieBloc>().add(MovieSearchRequested(query));
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _showMovieDetails(int movieId) {
    context.read<MovieBloc>().add(MovieDetailsRequested(movieId));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryBlack,
              AppColors.secondaryBlack,
              AppColors.primaryBlack,
            ],
          ),
        ),
        child: Stack(
          children: [
            _buildBackgroundDecorations(),
            SafeArea(
              child: Column(
                children: [
                  _buildModernHeader(),
                  BlocBuilder<MovieBloc, MovieState>(
                    builder: (context, state) {
                      if (state is PersonalizedRecommendationsSuccess) {
                        return _buildFeaturedSection(state.movies);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  Expanded(
                    child: _buildChatMessages(isTablet),
                  ),
                  _buildEnhancedInputBar(),
                ],
              ),
            ),
            if (_showScrollToBottom)
              _buildScrollToBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryRed.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                duration: 4000.ms,
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
              ),
        ),
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.orange.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                duration: 5000.ms,
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.3, 1.3),
              ),
        ),
      ],
    );
  }

  Widget _buildModernHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryRed,
                      Colors.orange,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryRed.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.movie_filter_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3)),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          AppColors.primaryRed,
                          Colors.orange,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'PALOMIX AI',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tu asistente cinematográfico',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.softWhite.withOpacity(0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat())
                        .fadeOut(duration: 1000.ms)
                        .then()
                        .fadeIn(duration: 1000.ms),
                    const SizedBox(width: 8),
                    Text(
                      'Online',
                      style: TextStyle(
                        color: Colors.green.shade300,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.3, end: 0, curve: Curves.easeOut);
  }

  Widget _buildFeaturedSection(List<MovieModel> movies) {
    if (movies.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.primaryRed,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Recomendadas para ti',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.softWhite,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: ListView.builder(
              controller: _recommendationsScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: movies.length,
              itemBuilder: (context, index) {
                return _buildMovieCard(movies[index], index);
              },
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 600.ms)
        .slideY(begin: 0.3, end: 0);
  }

  // 🎬 Card de película mejorada con ANIMACIONES ESPECTACULARES
  Widget _buildMovieCard(MovieModel movie, int index) {
    return GestureDetector(
      onTap: () => _showMovieDetails(movie.id),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryRed.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: movie.posterPath != null
                        ? Image.network(
                            'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : Container(
                            color: AppColors.tertiaryBlack,
                            child: Icon(
                              Icons.movie_rounded,
                              size: 60,
                              color: AppColors.grayWhite,
                            ),
                          ),
                  ),
                  
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  
                  // Rating badge con animación
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                movie.voteAverage.toStringAsFixed(1),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                        .animate(delay: (200 + index * 50).ms)
                        .fadeIn(duration: 400.ms)
                        .scale(begin: const Offset(0, 0), curve: Curves.elasticOut),
                  ),
                  
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.8),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Efecto de brillo al pasar
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.transparent,
                            Colors.transparent,
                          ],
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
    )
        .animate(delay: (150 * index).ms)
        .fadeIn(duration: 600.ms)
        .slideX(begin: 0.5, end: 0, curve: Curves.easeOutCubic)
        .then()
        .shimmer(
          duration: 2000.ms,
          delay: (500 * index).ms,
          color: Colors.white.withOpacity(0.1),
        );
  }

  Widget _buildChatMessages(bool isTablet) {
    return BlocConsumer<MovieBloc, MovieState>(
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
          _showSnackBar('Agregado a favoritos ✓', isError: false);
        }
      },
      builder: (context, state) {
        final isLoading = state is MovieLoading;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _messages.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (isLoading && index == 0) {
                      return _buildLoadingIndicator();
                    }

                    final messageIndex = isLoading ? index - 1 : index;
                    final message = _messages[messageIndex];

                    return _buildMessageBubble(message, messageIndex);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, int index) {
    final isUser = message.type == MessageType.user;
    final messageId = message.id;
    final hasRecommendations = message.recommendations != null && 
                                message.recommendations!.isNotEmpty;
    final isExpanded = _expandedRecommendations[messageId] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryRed,
                    Colors.orange,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryRed.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: isUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isUser ? 20 : 4),
                      topRight: Radius.circular(isUser ? 4 : 20),
                      bottomLeft: const Radius.circular(20),
                      bottomRight: const Radius.circular(20),
                    ),
                    gradient: isUser
                        ? LinearGradient(
                            colors: [
                              AppColors.primaryRed,
                              Colors.orange,
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                    border: Border.all(
                      color: isUser
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? AppColors.primaryRed.withOpacity(0.3)
                            : Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: isUser ? 2 : 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      
                      // 🎯 BOTÓN PARA MOSTRAR RECOMENDACIONES
                      if (hasRecommendations && !isUser)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _expandedRecommendations[messageId] = !isExpanded;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryRed,
                                    Colors.orange,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryRed.withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isExpanded 
                                        ? Icons.visibility_off_rounded 
                                        : Icons.visibility_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isExpanded 
                                        ? 'Ocultar películas' 
                                        : 'Ver ${message.recommendations!.length} películas',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    isExpanded 
                                        ? Icons.keyboard_arrow_up_rounded 
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          )
                              .animate(delay: 300.ms)
                              .fadeIn(duration: 400.ms)
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                curve: Curves.easeOut,
                              )
                              .then()
                              .shimmer(
                                duration: 2000.ms,
                                color: Colors.white.withOpacity(0.3),
                              ),
                        ),
                    ],
                  ),
                ),
                
                // 🎬 PELÍCULAS EXPANDIBLES CON ANIMACIÓN ESPECTACULAR
                if (hasRecommendations && isExpanded)
                  _buildExpandedMovieGrid(message.recommendations!),
              ],
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade400,
                    Colors.purple.shade400,
                  ],
                ),
              ),
              child: Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ],
      ),
    )
        .animate(delay: (50 * index).ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
  }

  // 🎬 GRID DE PELÍCULAS EXPANDIDO CON CARDS MÁS GRANDES
  Widget _buildExpandedMovieGrid(List<MovieModel> movies) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: movies.take(6).map((movie) {
          final index = movies.indexOf(movie);
          return _buildLargeMovieCard(movie, index);
        }).toList(),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.2, end: 0, curve: Curves.easeOut);
  }

  // 🎬 CARD DE PELÍCULA GRANDE CON ANIMACIONES ESPECTACULARES
  Widget _buildLargeMovieCard(MovieModel movie, int index) {
    return GestureDetector(
      onTap: () => _showMovieDetails(movie.id),
      child: Container(
        width: 140,
        child: Column(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryRed.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 3,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: movie.posterPath != null
                        ? Image.network(
                            'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : Container(
                            color: AppColors.tertiaryBlack,
                            child: Icon(
                              Icons.movie_rounded,
                              size: 50,
                              color: AppColors.grayWhite,
                            ),
                          ),
                  ),
                  
                  // Gradiente overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  
                  // Rating badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.6),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            movie.voteAverage.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate(delay: (200 + index * 100).ms)
                        .fadeIn(duration: 500.ms)
                        .scale(
                          begin: const Offset(0, 0),
                          curve: Curves.elasticOut,
                        ),
                  ),
                  
                  // Play icon overlay
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.3),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.6),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  )
                      .animate(delay: (300 + index * 100).ms)
                      .fadeIn(duration: 500.ms)
                      .scale(
                        begin: const Offset(0, 0),
                        curve: Curves.elasticOut,
                      ),
                  
                  // Título
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.8),
                              blurRadius: 6,
                            ),
                          ],
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
    )
        .animate(delay: (150 * index).ms)
        .fadeIn(duration: 600.ms)
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.0, 1.0),
          curve: Curves.elasticOut,
        )
        .then(delay: (100 * index).ms)
        .shimmer(
          duration: 1500.ms,
          color: Colors.white.withOpacity(0.3),
        );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryRed,
                  Colors.orange,
                ],
              ),
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryRed,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Buscando películas...',
                  style: TextStyle(
                    color: AppColors.softWhite,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .fadeIn(duration: 800.ms)
        .then()
        .fadeOut(duration: 800.ms);
  }

  Widget _buildEnhancedInputBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  context.read<MovieBloc>().add(PersonalizedRecommendationsRequested());
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Colors.orange,
                    size: 22,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar película o pedir recomendaciones...',
                    hintStyle: TextStyle(
                      color: AppColors.softWhite.withOpacity(0.5),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              
              const SizedBox(width: 12),
              
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryRed,
                        Colors.orange,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryRed.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    duration: 2000.ms,
                    color: Colors.white.withOpacity(0.3),
                  ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 600.ms)
        .slideY(begin: 0.5, end: 0);
  }

  Widget _buildScrollToBottomButton() {
    return Positioned(
      bottom: 100,
      right: 24,
      child: GestureDetector(
        onTap: _scrollToBottom,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.primaryRed,
                Colors.orange,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryRed.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 300.ms)
          .scale(begin: const Offset(0.5, 0.5)),
    );
  }

  void _handleSearchResults(List<MovieModel> movies) {
    if (movies.isEmpty) {
      final message = ChatMessageModel(
        id: _uuid.v4(),
        content: '🎬 No encontré películas con ese nombre. Intenta con otro título.',
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
      content: '✨ Encontré ${movies.length} resultado${movies.length > 1 ? 's' : ''}.',
      type: MessageType.assistant,
      timestamp: DateTime.now(),
      recommendations: movies.take(6).toList(),
    );

    setState(() {
      _messages.insert(0, message);
    });
    _scrollToBottom();
  }

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

  void _handleRecommendations(PersonalizedRecommendationsSuccess state) {
    final message = ChatMessageModel(
      id: _uuid.v4(),
      content: state.aiRecommendations.isNotEmpty
          ? state.aiRecommendations
          : '🎯 Tengo algunas recomendaciones para ti.',
      type: MessageType.assistant,
      timestamp: DateTime.now(),
      recommendations: state.movies,
    );

    setState(() {
      _messages.insert(0, message);
    });
    _scrollToBottom();
  }

  void _handleError(String message) {
    final errorMessage = ChatMessageModel(
      id: _uuid.v4(),
      content: '❌ Lo siento, ocurrió un error: $message',
      type: MessageType.error,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, errorMessage);
    });
    _scrollToBottom();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.errorRed : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
