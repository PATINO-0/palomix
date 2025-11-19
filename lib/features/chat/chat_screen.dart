import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/chat_message.dart';
import '../../core/models/movie.dart';
import '../../data/models/movie_model.dart';
import '../../data/services/tmdb_service.dart';
import '../../core/services/groq_service.dart';
import '../../core/services/supabase_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  final _tmdb = TmdbService();

  List<MovieModel> _searchResults = [];
  bool _loadingMovies = false;
  bool _loadingSummary = false;
  MovieModel? _selectedMovie;
  String? _movieSummary;
  List<MovieModel> _recommendations = [];
  bool _isFavorite = false;

  late AnimationController _fabAnimationController;
  late AnimationController _favoriteAnimationController;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _favoriteAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollButton());
    _addSystemWelcome();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _fabAnimationController.dispose();
    _favoriteAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    _updateScrollButton();
  }

  void _updateScrollButton() {
    if (!_scrollCtrl.hasClients) return;
    const threshold = 80.0;
    final hasContent = _scrollCtrl.position.maxScrollExtent > threshold;
    final shouldShow = hasContent && _scrollCtrl.offset <= threshold;
    if (shouldShow == _showScrollToBottom) return;
    setState(() {
      _showScrollToBottom = shouldShow;
    });
    if (shouldShow) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  void _addSystemWelcome() {
    _messages.add(
      ChatMessage(
        id: 'welcome',
        sender: ChatSender.assistant,
        text: '¡Hola! 👋 Soy tu asistente cinematográfico.\n\n'
            '🎬 Busca cualquier película o serie\n'
            '✨ Obtén resúmenes sin spoilers\n'
            '❤️ Guarda tus favoritas\n\n'
            '¿Qué te gustaría ver hoy?',
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _sendQuery() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          sender: ChatSender.user,
          text: text,
          timestamp: DateTime.now(),
        ),
      );
      _inputCtrl.clear();
      _loadingMovies = true;
      _searchResults = [];
      _selectedMovie = null;
      _movieSummary = null;
      _recommendations = [];
      _isFavorite = false;
    });

    try {
      final movies = await _tmdb.searchMovies(text);
      setState(() {
        _searchResults = movies;
      });

      if (movies.isEmpty) {
        _messages.add(
          ChatMessage(
            id: 'noresults-${DateTime.now().microsecondsSinceEpoch}',
            sender: ChatSender.assistant,
            text:
                '🎬 No encontré películas con ese nombre. Intenta con otro título.',
            timestamp: DateTime.now(),
          ),
        );
      } else {
        _messages.add(
          ChatMessage(
            id: 'results-${DateTime.now().microsecondsSinceEpoch}',
            sender: ChatSender.assistant,
            text:
                '✨ Encontré ${movies.length} resultado${movies.length > 1 ? 's' : ''}. '
                'Toca la película que te interese para ver el resumen.',
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      _messages.add(
        ChatMessage(
          id: 'error-${DateTime.now().microsecondsSinceEpoch}',
          sender: ChatSender.assistant,
          text:
              '❌ Ups, hubo un problema buscando películas. Verifica tu conexión.',
          timestamp: DateTime.now(),
        ),
      );
      _showErrorNotification(
          'Error de búsqueda', 'No se pudo conectar con el servidor.');
    } finally {
      setState(() {
        _loadingMovies = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _onMovieSelected(MovieModel movie) async {
    setState(() {
      _selectedMovie = movie;
      _loadingSummary = true;
      _movieSummary = null;
      _recommendations = [];
      _isFavorite = false;
    });

    await _checkIfFavorite(movie.id);

    try {
      final details = await _tmdb.getMovieDetails(movie.id);
      final recs = await _tmdb.getRecommendations(movie.id);
      final coreMovie = _toCoreMovie(details);
      final summary = await GroqService.instance.summarizeMovie(coreMovie);

      setState(() {
        _selectedMovie = details;
        _movieSummary = summary;
        _recommendations = recs;
      });

      _messages.add(
        ChatMessage(
          id: 'summary-${movie.id}',
          sender: ChatSender.assistant,
          text:
              'Aquí tienes un resumen sin spoilers fuertes de "${details.title}". '
              'También te muestro recomendaciones similares más abajo.',
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      setState(() {
        _movieSummary = '❌ No pude generar el resumen en este momento.';
      });
      _showErrorNotification(
          'Error de resumen', 'No se pudo generar el resumen de la película.');
    } finally {
      setState(() {
        _loadingSummary = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _checkIfFavorite(int movieId) async {
    try {
      final favorites = await SupabaseService.instance.getFavorites();
      setState(() {
        _isFavorite = favorites.any((fav) => fav.movie.id == movieId);
      });
    } catch (e) {
      setState(() {
        _isFavorite = false;
      });
    }
  }

  Movie _toCoreMovie(MovieModel m) {
    return Movie(
      id: m.id,
      title: m.title,
      overview: m.overview,
      posterPath: m.posterPath,
      releaseDate: m.releaseDate,
    );
  }

  Future<void> _toggleFavorite() async {
    final movie = _selectedMovie;
    if (movie == null) return;

    if (_isFavorite) {
      try {
        await SupabaseService.instance.removeFavorite(movie.id);
        setState(() {
          _isFavorite = false;
        });
        _favoriteAnimationController.reverse();
        _showSuccessNotification(
          'Eliminado de favoritos',
          '"${movie.title}" se eliminó de tu lista.',
          isNegative: true,
        );
      } catch (e) {
        _showErrorNotification(
          'Error al eliminar',
          'No se pudo eliminar la película de favoritos.',
        );
      }
    } else {
      try {
        final coreMovie = _toCoreMovie(movie);
        await SupabaseService.instance.addFavorite(coreMovie);
        setState(() {
          _isFavorite = true;
        });
        _favoriteAnimationController.forward();
        _showSuccessNotification(
          'Añadido a favoritos',
          '"${movie.title}" se guardó en tu lista.',
        );
      } on Exception catch (e) {
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('duplicate') ||
            errorMsg.contains('unique') ||
            errorMsg.contains('already exists')) {
          setState(() {
            _isFavorite = true;
          });
          _showWarningNotification(
            'Ya está en favoritos',
            '"${movie.title}" ya estaba guardada en tu lista.',
          );
        } else {
          _showErrorNotification(
            'Error al guardar',
            'No se pudo añadir la película a favoritos.',
          );
        }
      } catch (e) {
        _showErrorNotification(
          'Error al guardar',
          'Ocurrió un error inesperado. Intenta de nuevo.',
        );
      }
    }
  }

  void _showSuccessNotification(String title, String message,
      {bool isNegative = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor:
            isNegative ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  void _showWarningNotification(String title, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.info_outline, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  void _showErrorNotification(String title, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A0000),
              Color(0xFF000000),
              Color(0xFF2D0A0A),
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
                  Expanded(
                    child: _buildChatMessages(),
                  ),
                  _buildEnhancedInputBar(),
                ],
              ),
            ),
            if (_showScrollToBottom) _buildScrollToBottomButton(),
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
                  const Color(0xFFDC2626).withOpacity(0.15),
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
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFDC2626),
                      Colors.orange,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
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
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFDC2626),
                          Colors.orange,
                        ],
                      ).createShader(bounds),
                      child: const Text(
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
                        color: Colors.white.withOpacity(0.7),
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

  Widget _buildChatMessages() {
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final bottomPadding = bottomSafeArea;

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
            child: ListView(
              controller: _scrollCtrl,
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
              physics: const BouncingScrollPhysics(),
              children: [
                ..._messages.map(_buildMessageBubble),
                const SizedBox(height: 12),
                if (_loadingMovies) _buildLoadingIndicator(),
                if (_searchResults.isNotEmpty) _buildSearchResults(),
                if (_selectedMovie != null) _buildSelectedMovie(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.sender == ChatSender.user;

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
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFDC2626),
                    Colors.orange,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 20 : 4),
                  topRight: Radius.circular(isUser ? 4 : 20),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
                gradient: isUser
                    ? const LinearGradient(
                        colors: [
                          Color(0xFFDC2626),
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
                        ? const Color(0xFFDC2626).withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: isUser ? 2 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
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
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
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
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFDC2626),
                  Colors.orange,
                ],
              ),
            ),
            child: const Icon(
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
              children: const [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFDC2626),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Buscando películas...',
                  style: TextStyle(
                    color: Colors.white,
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

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(
              Icons.search_rounded,
              color: Color(0xFFDC2626),
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'Resultados:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _searchResults.length,
            itemBuilder: (ctx, i) => _buildMovieCard(_searchResults[i], i),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 600.ms)
        .slideY(begin: 0.3, end: 0);
  }

  Widget _buildMovieCard(MovieModel movie, int index) {
    final posterUrl = movie.fullPosterUrl;

    return GestureDetector(
      onTap: () => _onMovieSelected(movie),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withOpacity(0.3),
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
                    child: posterUrl != null
                        ? Image.network(
                            posterUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : Container(
                            color: Colors.grey.shade900,
                            child: const Icon(
                              Icons.movie_rounded,
                              size: 60,
                              color: Colors.white54,
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
                  if (movie.voteAverage > 0)
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              movie.voteAverage.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate(delay: (200 + index * 50).ms)
                          .fadeIn(duration: 400.ms)
                          .scale(
                              begin: const Offset(0, 0),
                              curve: Curves.elasticOut),
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
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (150 * index).ms)
        .fadeIn(duration: 600.ms)
        .slideX(begin: 0.5, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildSelectedMovie() {
    final movie = _selectedMovie!;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  movie.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _toggleFavorite,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _isFavorite
                        ? const LinearGradient(
                            colors: [
                              Color(0xFFDC2626),
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
                      color: _isFavorite
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: _isFavorite
                        ? [
                            BoxShadow(
                              color: const Color(0xFFDC2626).withOpacity(0.5),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.white : const Color(0xFFDC2626),
                    size: 24,
                  ),
                ),
              )
                  .animate(
                    onPlay: (controller) {
                      if (_isFavorite) {
                        controller.forward();
                      } else {
                        controller.reverse();
                      }
                    },
                    controller: _favoriteAnimationController,
                  )
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                    curve: Curves.elasticOut,
                  )
                  .then()
                  .shake(hz: 2, duration: 300.ms),
            ],
          ),
          const SizedBox(height: 16),
          if (_loadingSummary)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const LinearProgressIndicator(
                  minHeight: 6,
                  color: Color(0xFFDC2626),
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
          if (_movieSummary != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.white.withOpacity(0.02),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Text(
                _movieSummary!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ],
          if (_recommendations.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: const [
                Icon(
                  Icons.recommend_rounded,
                  color: Color(0xFFDC2626),
                  size: 22,
                ),
                SizedBox(width: 10),
                Text(
                  'Sugerencias similares:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _recommendations.length,
                itemBuilder: (ctx, i) =>
                    _buildMovieCard(_recommendations[i], i),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildEnhancedInputBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.08),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 25,
            spreadRadius: 5,
            offset: const Offset(0, -5),
          ),
          BoxShadow(
            color: const Color(0xFFDC2626).withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFDC2626).withOpacity(0.2),
                        Colors.orange.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFFDC2626),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar película o serie...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _sendQuery(),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendQuery,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFDC2626),
                          Colors.orange,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDC2626).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(
                        duration: 2500.ms, color: Colors.white.withOpacity(0.4))
                    .then(delay: 500.ms),
              ],
            ),
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
      bottom: 220,
      right: 20,
      child: GestureDetector(
        onTap: _scrollToBottom,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFFDC2626),
                Colors.orange,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC2626).withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.5, 0.5)),
    );
  }
}
