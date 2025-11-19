// lib/features/movie_detail/movie_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/movie.dart';
import '../../core/services/groq_service.dart';
import '../../core/services/supabase_service.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;           // modelo simple de Palomix
  final String? fullPosterUrl; // URL completa de la imagen

  const MovieDetailScreen({
    super.key,
    required this.movie,
    this.fullPosterUrl,
  });

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  String? _summary;
  bool _loadingSummary = true;
  bool _savingFavorite = false;

  @override
  void initState() {
    super.initState();
    _generateSummary();
  }

  Future<void> _generateSummary() async {
    setState(() {
      _loadingSummary = true;
      _summary = null;
    });

    try {
      final text = await GroqService.instance.summarizeMovie(widget.movie);
      if (!mounted) return;
      setState(() {
        _summary = text;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _summary =
            'No pude generar el resumen en este momento. Intenta de nuevo más tarde.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingSummary = false;
      });
    }
  }

  Future<void> _saveAsFavorite() async {
    setState(() {
      _savingFavorite = true;
    });

    try {
      await SupabaseService.instance.addFavorite(widget.movie);
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
    } finally {
      if (!mounted) return;
      setState(() {
        _savingFavorite = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.movie;
    final posterUrl = widget.fullPosterUrl;
    final isWide = MediaQuery.of(context).size.width >= 700;

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Hero(
          tag: 'poster-${m.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: posterUrl != null
                  ? Image.network(
                      posterUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey.shade900,
                      child: const Center(
                        child: Icon(
                          Icons.movie_outlined,
                          color: Colors.white54,
                          size: 40,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              if (m.releaseDate != null)
                Text(
                  'Estreno: ${m.releaseDate}',
                  style: const TextStyle(color: Colors.white70),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _savingFavorite ? null : _saveAsFavorite,
                    icon: _savingFavorite
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.favorite_border),
                    label: const Text('Guardar favorito'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _loadingSummary ? null : _generateSummary,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Regenerar resumen'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final summarySection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Resumen generado por IA:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        if (_loadingSummary)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Estoy analizando la película, dame un momento...',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(minHeight: 2),
            ],
          )
        else
          Text(
            _summary ??
                'No pude generar el resumen en este momento. Intenta de nuevo más tarde.',
            style: const TextStyle(
              color: Colors.white70,
              height: 1.3,
            ),
          ),
      ],
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.05, curve: Curves.easeOut),
        summarySection
            .animate()
            .fadeIn(duration: 400.ms, delay: 100.ms)
            .slideY(begin: 0.03),
        const SizedBox(height: 24),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(m.title),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 32 : 16,
          vertical: 24,
        ),
        child: content,
      ),
    );
  }
}
