import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/chat_message.dart';
import '../../core/models/movie.dart';             // 👈 Import del modelo Movie simple
import '../../data/models/movie_model.dart';      // MovieModel de TMDb
import '../../data/services/tmdb_service.dart';
import '../../core/services/groq_service.dart';
import '../../core/services/supabase_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
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

  @override
  void initState() {
    super.initState();
    _addSystemWelcome();
  }

  void _addSystemWelcome() {
    _messages.add(
      ChatMessage(
        id: 'welcome',
        sender: ChatSender.assistant,
        text:
            '¡Hola! Soy Palomix 🎬.\nEscríbeme el nombre de una película o serie que quieras explorar.',
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
    });

    try {
      final movies = await _tmdb.searchMovies(text);
      setState(() {
        _searchResults = movies;
      });
      _messages.add(
        ChatMessage(
          id: 'results-${DateTime.now().microsecondsSinceEpoch}',
          sender: ChatSender.assistant,
          text:
              'Encontré algunas opciones. Toca la carátula de la película que te interese para ver el resumen.',
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      _messages.add(
        ChatMessage(
          id: 'error-${DateTime.now().microsecondsSinceEpoch}',
          sender: ChatSender.assistant,
          text:
              'Ups, hubo un problema buscando en TMDb: $e\nIntenta de nuevo o cambia el título.',
          timestamp: DateTime.now(),
        ),
      );
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
    });

    try {
      // Detalles completos + cast
      final details = await _tmdb.getMovieDetails(movie.id);
      final recs = await _tmdb.getRecommendations(movie.id);

      // Convertimos MovieModel -> Movie (modelo simple que entiende Groq y Supabase)
      final coreMovie = _toCoreMovie(details);

      // Resumen con Groq
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
              'Aquí tienes un resumen sin spoilers fuertes de "${details.title}". También te muestro recomendaciones similares más abajo.',
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      setState(() {
        _movieSummary = 'No pude generar el resumen en este momento: $e';
      });
    } finally {
      setState(() {
        _loadingSummary = false;
      });
      _scrollToBottom();
    }
  }

  /// Adaptador: MovieModel (TMDb) -> Movie (modelo simple de Palomix)
  Movie _toCoreMovie(MovieModel m) {
    return Movie(
      id: m.id,
      title: m.title,
      overview: m.overview,
      posterPath: m.posterPath,
      releaseDate: m.releaseDate,
    );
  }

  Future<void> _addToFavorites() async {
    final movie = _selectedMovie;
    if (movie == null) return;

    try {
      final coreMovie = _toCoreMovie(movie);

      await SupabaseService.instance.addFavorite(coreMovie);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Película añadida a favoritos 🍿')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar la película en favoritos.'),
        ),
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.sender == ChatSender.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.redAccent.withOpacity(0.9)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          msg.text,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildMovieCard(MovieModel movie) {
    final posterUrl = movie.fullPosterUrl;

    return GestureDetector(
      onTap: () => _onMovieSelected(movie),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: posterUrl != null
                    ? Image.network(
                        posterUrl,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey.shade900,
                        child: const Center(
                          child: Icon(
                            Icons.movie_creation_outlined,
                            color: Colors.white54,
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                movie.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack);
  }

  Widget _buildRecommendations() {
    if (_recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Sugerencias similares:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recommendations.length,
            itemBuilder: (ctx, i) => _buildMovieCard(_recommendations[i]),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chat
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListView(
              controller: _scrollCtrl,
              children: [
                const SizedBox(height: 8),
                ..._messages.map(_buildMessageBubble),
                const SizedBox(height: 12),
                if (_loadingMovies)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                if (_searchResults.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resultados:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 230,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _searchResults.length,
                          itemBuilder: (ctx, i) =>
                              _buildMovieCard(_searchResults[i]),
                        ),
                      ),
                    ],
                  ),
                if (_selectedMovie != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedMovie!.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _addToFavorites,
                            icon: const Icon(Icons.favorite_border),
                            tooltip: 'Añadir a favoritos',
                          ),
                        ],
                      ),
                      if (_loadingSummary)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: LinearProgressIndicator(),
                        ),
                      if (_movieSummary != null)
                        Text(
                          _movieSummary!,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      _buildRecommendations(),
                    ],
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        // Input
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Pregúntame por una película o serie...',
                    ),
                    onSubmitted: (_) => _sendQuery(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendQuery,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ).animate().scale(begin: const Offset(0.9, 0.9)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
