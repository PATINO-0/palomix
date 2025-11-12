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
import '../../bloc/favorites/favorites_cubit.dart';
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
  final Map<String, bool> _expandedRecommendations = {};
  final _uuid = const Uuid();
  MovieModel? _currentMovie;
  late AnimationController _fabAnimationController;
  bool _showScrollToBottom = false;
  Set<int> _favoriteMovieIds = {};
  bool _suppressNextDetailMessage = false;
  String? _lastSearchQuery;

  static const Set<String> _searchStopWords = {
    'la',
    'el',
    'los',
    'las',
    'de',
    'del',
    'al',
    'un',
    'una',
    'unos',
    'unas',
    'que',
    'por',
    'para',
    'con',
    'sin',
    'donde',
    'd\u00f3nde',
    'actua',
    'actu\u00f3',
    'actuo',
    'actor',
    'actriz',
    'pelicula',
    'pel\u00edculas',
    'peliculas',
    'pel\u00edcula',
    'pelis',
    'serie',
    'series',
    'ver',
    'quiero',
    'busca',
    'buscar',
    'favor',
    'basada',
    'basado',
    'protagonizada',
    'protagonizado',
    'dime',
    'algo',
    'sobre',
    'trata',
    'tema',
    'tipo'
  };

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scrollController.addListener(_onScroll);
    _addWelcomeMessage();
    context.read<FavoritesCubit>().loadFavorites();
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
      content: '\u00a1Hola! 👋 Soy tu asistente cinematogr\u00e1fico.\n\n'
          '🎬 Busca cualquier pel\u00edcula o serie\n'
          '✨ Pide recomendaciones personalizadas\n'
          '❤️ Guarda tus favoritas\n\n'
          '\u00bfQu\u00e9 te gustar\u00eda ver hoy?',
      type: MessageType.assistant,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, welcomeMessage);
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final rawMessage = _messageController.text.trim();
    final userMessage = ChatMessageModel(
      id: _uuid.v4(),
      content: rawMessage,
      type: MessageType.user,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, userMessage);
    });

    final query = rawMessage.toLowerCase();
    _messageController.clear();

    if (query.contains('recomiend') ||
        query.contains('suger') ||
        query.contains('qu\u00e9 ver') ||
        query.contains('que ver') ||
        query.contains('recommend') ||
        query.contains('suggest') ||
        query.contains('what should i watch') ||
        query.contains('what to watch')) {
      if (_favoriteMovieIds.isEmpty) {
        _pushAssistantMessage(
          'A\u00fan no tienes favoritos guardados. Agrega al menos uno para crear recomendaciones personalizadas.',
        );
        _scrollToBottom();
        return;
      } else {
        context.read<MovieBloc>().add(PersonalizedRecommendationsRequested());
      }
    } else {
      final prepared = _prepareQuery(rawMessage);
      final searchQuery = prepared.isNotEmpty ? prepared : rawMessage;
      _lastSearchQuery = searchQuery;
      context.read<MovieBloc>().add(MovieSearchRequested(searchQuery));
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

  String _prepareQuery(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final cleaned = trimmed
        .replaceAll(RegExp(r'[\u00bf\u00a1\?\!\.,;:"]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return '';
    final tokens = cleaned.split(' ');
    final filtered = <String>[];
    for (final token in tokens) {
      final lower = token.toLowerCase();
      if (_searchStopWords.contains(lower)) continue;
      filtered.add(token);
    }
    final candidate = filtered.join(' ').trim();
    return candidate.isNotEmpty ? candidate : cleaned;
  }

  void _pushAssistantMessage(
    String content, {
    MessageType type = MessageType.assistant,
    List<MovieModel>? recommendations,
  }) {
    final message = ChatMessageModel(
      id: _uuid.v4(),
      content: content,
      type: type,
      timestamp: DateTime.now(),
      recommendations: recommendations,
    );
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _showMovieDetails(int movieId) {
    _suppressNextDetailMessage = true;
    context.read<MovieBloc>().add(MovieDetailsRequested(movieId));
    _showDetailsBottomSheet();
  }

  Future<void> _toggleFavorite(MovieModel movie) async {
    final favoritesCubit = context.read<FavoritesCubit>();
    final isFavorite = _favoriteMovieIds.contains(movie.id);
    try {
      if (isFavorite) {
        await favoritesCubit.removeFavorite(movie.id);
        setState(() {
          _favoriteMovieIds.remove(movie.id);
        });
        _showSnackBar('${movie.title} se elimin\u00f3 de favoritos',
            isError: false);
      } else {
        await favoritesCubit.addToFavorites(
          movieId: movie.id,
          movieTitle: movie.title,
          posterPath: movie.posterPath,
        );
        setState(() {
          _favoriteMovieIds.add(movie.id);
        });
        _showSnackBar('${movie.title} se agreg\u00f3 a favoritos ❤️',
            isError: false);
      }
    } catch (_) {
      _showSnackBar('No pude actualizar tus favoritos, intenta de nuevo.',
          isError: true);
    }
  }

  void _showDetailsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocBuilder<MovieBloc, MovieState>(
        builder: (context, state) {
          if (state is MovieDetailsSuccess) {
            return _buildDetailsSheet(state);
          }
          return _buildDetailsLoadingSheet();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return BlocListener<FavoritesCubit, FavoritesState>(
      listener: _handleFavoritesState,
      child: Scaffold(
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
              if (_showScrollToBottom) _buildScrollToBottomButton(),
            ],
          ),
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

  Widget _buildDetailsSheet(MovieDetailsSuccess state) {
    final movie = state.movie;
    final summaryText = state.aiSummary.isNotEmpty
        ? state.aiSummary
        : (movie.overview.isNotEmpty ? movie.overview : '');

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryBlack,
                AppColors.secondaryBlack,
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: Stack(
            children: [
              ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  if (movie.fullPosterUrl != null)
                    Center(
                      child: Container(
                        width: 200,
                        height: 280,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryRed.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            movie.fullPosterUrl!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ).animate().fadeIn(duration: 600.ms).scale(
                            duration: 600.ms,
                            begin: const Offset(0.8, 0.8),
                            curve: Curves.easeOut,
                          ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    movie.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        '${movie.voteAverage.toStringAsFixed(1)} / 10',
                        style: TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (summaryText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.05),
                            Colors.white.withOpacity(0.02),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumen',
                            style: TextStyle(
                              color: AppColors.pureWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            summaryText,
                            style: TextStyle(
                              color: AppColors.softWhite,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (state.similarMovies.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Pel\u00edculas similares',
                      style: TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(right: 8),
                        itemCount: state.similarMovies.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final similar = state.similarMovies[index];
                          return GestureDetector(
                            onTap: () => _showMovieDetails(similar.id),
                            child: Column(
                              children: [
                                Container(
                                  width: 110,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: similar.posterPath != null
                                        ? Image.network(
                                            'https://image.tmdb.org/t/p/w500${similar.posterPath}',
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            color: AppColors.tertiaryBlack,
                                            child: Icon(
                                              Icons.movie_rounded,
                                              color: AppColors.grayWhite,
                                              size: 32,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 110,
                                  child: Text(
                                    similar.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.softWhite,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
              Positioned(
                top: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms).scale(
                      begin: const Offset(0, 0),
                      curve: Curves.elasticOut,
                    ),
              ),
            ],
          ),
        ).animate().slideY(begin: 1, duration: 400.ms, curve: Curves.easeOut);
      },
    );
  }

  Widget _buildDetailsLoadingSheet() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlack,
            AppColors.secondaryBlack,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
        ),
      ),
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
              ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                  duration: 2000.ms, color: Colors.white.withOpacity(0.3)),
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
                      'Tu asistente cinematogr\u00e1fico',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Widget _buildMovieCard(MovieModel movie, int index) {
    final isFavorite = _favoriteMovieIds.contains(movie.id);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
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
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                        .scale(
                            begin: const Offset(0, 0),
                            curve: Curves.elasticOut),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(movie),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.75),
                          border: Border.all(
                            color: isFavorite
                                ? AppColors.primaryRed
                                : Colors.white.withOpacity(0.4),
                            width: 1.3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color:
                              isFavorite ? AppColors.primaryRed : Colors.white,
                          size: 18,
                        ),
                      ),
                    )
                        .animate(delay: (250 + index * 50).ms)
                        .fadeIn(duration: 400.ms)
                        .scale(
                          begin: const Offset(0, 0),
                          curve: Curves.elasticOut,
                        ),
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
    final hasRecommendations =
        message.recommendations != null && message.recommendations!.isNotEmpty;
    final isExpanded = _expandedRecommendations[messageId] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      if (hasRecommendations && !isUser)
                        Builder(
                          builder: (context) {
                            final movieCount = message.recommendations!.length;
                            final isSingular = movieCount == 1;
                            final buttonLabel = isExpanded
                                ? 'Ocultar pel\u00edculas'
                                : "Ver $movieCount ${isSingular ? 'pel\u00edcula' : 'pel\u00edculas'}";
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _expandedRecommendations[messageId] =
                                        !isExpanded;
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
                                        color: AppColors.primaryRed
                                            .withOpacity(0.4),
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
                                        buttonLabel,
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
                            );
                          },
                        ),
                    ],
                  ),
                ),
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

  void _handleFavoritesState(BuildContext context, FavoritesState state) {
    if (state is FavoritesLoaded) {
      setState(() {
        _favoriteMovieIds =
            state.favorites.map((favorite) => favorite.movieId).toSet();
      });
    }
  }

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

  Widget _buildLargeMovieCard(MovieModel movie, int index) {
    final isFavorite = _favoriteMovieIds.contains(movie.id);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
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
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(movie),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.75),
                          border: Border.all(
                            color: isFavorite
                                ? AppColors.primaryRed
                                : Colors.white.withOpacity(0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.45),
                              blurRadius: 12,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color:
                              isFavorite ? AppColors.primaryRed : Colors.white,
                          size: 20,
                        ),
                      ),
                    )
                        .animate(delay: (250 + index * 100).ms)
                        .fadeIn(duration: 500.ms)
                        .scale(
                          begin: const Offset(0, 0),
                          curve: Curves.elasticOut,
                        ),
                  ),
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
                  'Buscando pel\u00edculas...',
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
                  context
                      .read<MovieBloc>()
                      .add(PersonalizedRecommendationsRequested());
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
                    hintText: 'Buscar pel\u00edcula o pedir recomendaciones...',
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
              ).animate(onPlay: (controller) => controller.repeat()).shimmer(
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
      ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.5, 0.5)),
    );
  }

  void _handleSearchResults(List<MovieModel> movies) {
    if (movies.isEmpty) {
      final queryText =
          _lastSearchQuery != null ? ' para "${_lastSearchQuery!}"' : '';
      _pushAssistantMessage(
        '🎬 No encontr\u00e9 coincidencias$queryText. Intenta escribir solo el t\u00edtulo principal o alg\u00fan actor destacado.',
      );
      return;
    }

    final total = movies.length;
    _pushAssistantMessage(
      total == 1
          ? '✨ Encontr\u00e9 1 resultado.'
          : '✨ Encontr\u00e9 $total resultados.',
      recommendations: movies.take(6).toList(),
    );
    _scrollToBottom();
  }

  void _handleMovieDetails(MovieDetailsSuccess state) {
    if (_suppressNextDetailMessage) {
      _suppressNextDetailMessage = false;
      setState(() {
        _currentMovie = state.movie;
      });
      return;
    }

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
    final hasFavorites = _favoriteMovieIds.isNotEmpty;
    String content;
    if (hasFavorites && state.aiRecommendations.isNotEmpty) {
      content = state.aiRecommendations;
    } else if (hasFavorites) {
      content =
          '🎯 Estas coincidencias se basan en lo que marcaste como favorito.';
    } else {
      content =
          '🎯 A\u00fan no detecto favoritos, as\u00ed que aqu\u00ed tienes algunas sugerencias populares.';
    }

    _pushAssistantMessage(
      content,
      recommendations: state.movies,
    );
    _scrollToBottom();
  }

  void _handleError(String message) {
    final errorMessage = ChatMessageModel(
      id: _uuid.v4(),
      content: '❌ Lo siento, ocurri\u00f3 un error: $message',
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
