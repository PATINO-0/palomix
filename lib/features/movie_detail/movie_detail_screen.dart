import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/movie.dart';
import '../../core/services/groq_service.dart';
import '../../core/services/supabase_service.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;
  final String? fullPosterUrl;

  const MovieDetailScreen({
    super.key,
    required this.movie,
    this.fullPosterUrl,
  });

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen>
    with TickerProviderStateMixin {
  String? _summary;
  bool _loadingSummary = true;
  bool _savingFavorite = false;
  bool _isFavorite = false;
  late AnimationController _favoriteAnimationController;

  @override
  void initState() {
    super.initState();
    _favoriteAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _generateSummary();
    _checkIfFavorite();
  }

  @override
  void dispose() {
    _favoriteAnimationController.dispose();
    super.dispose();
  }

  Future<void> _checkIfFavorite() async {
    try {
      final favorites = await SupabaseService.instance.getFavorites();
      if (mounted) {
        setState(() {
          _isFavorite = favorites.any((fav) => fav.movie.id == widget.movie.id);
          if (_isFavorite) {
            _favoriteAnimationController.value = 1.0;
          }
        });
      }
    } catch (e) {
      // Ignorar error silenciosamente
    }
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
    } catch (e) {
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

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      // Remover de favoritos
      setState(() {
        _savingFavorite = true;
      });

      try {
        await SupabaseService.instance.removeFavorite(widget.movie.id);
        if (!mounted) return;
        setState(() {
          _isFavorite = false;
        });
        _favoriteAnimationController.reverse();
        _showSuccessNotification('Eliminado de favoritos', '💔');
      } catch (e) {
        if (!mounted) return;
        _showErrorNotification('No se pudo eliminar la película');
      } finally {
        if (mounted) {
          setState(() {
            _savingFavorite = false;
          });
        }
      }
    } else {
      // Añadir a favoritos
      setState(() {
        _savingFavorite = true;
      });

      try {
        await SupabaseService.instance.addFavorite(widget.movie);
        if (!mounted) return;
        setState(() {
          _isFavorite = true;
        });
        _favoriteAnimationController.forward();
        _showSuccessNotification('Añadido a favoritos', '🍿');
      } catch (e) {
        if (!mounted) return;
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('duplicate') ||
            errorMsg.contains('unique') ||
            errorMsg.contains('already exists')) {
          setState(() {
            _isFavorite = true;
          });
          _showWarningNotification('Ya está en favoritos');
        } else {
          _showErrorNotification('No se pudo guardar la película');
        }
      } finally {
        if (mounted) {
          setState(() {
            _savingFavorite = false;
          });
        }
      }
    }
  }

  void _showSuccessNotification(String message, String emoji) {
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
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showWarningNotification(String message) {
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
              child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorNotification(String message) {
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
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.movie;
    final posterUrl = widget.fullPosterUrl;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

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
                  _buildModernAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isTablet)
                              _buildTabletLayout(m, posterUrl)
                            else
                              _buildMobileLayout(m, posterUrl),
                            const SizedBox(height: 24),
                            _buildActionButtons(),
                            const SizedBox(height: 24),
                            _buildSummaryCard(),
                            const SizedBox(height: 80),
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
                colors: [Colors.orange.withOpacity(0.1), Colors.transparent],
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

  Widget _buildModernAppBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
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
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.movie.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  Widget _buildMobileLayout(Movie m, String? posterUrl) {
    return Column(
      children: [
        _buildPosterCard(posterUrl),
        const SizedBox(height: 20),
        _buildInfoCard(m),
      ],
    );
  }

  Widget _buildTabletLayout(Movie m, String? posterUrl) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildPosterCard(posterUrl)),
        const SizedBox(width: 20),
        Expanded(flex: 3, child: _buildInfoCard(m)),
      ],
    );
  }

  Widget _buildPosterCard(String? posterUrl) {
    return Hero(
      tag: 'poster-${widget.movie.id}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDC2626).withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: posterUrl != null
                ? Image.network(
                    posterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPalomixPlaceholder();
                    },
                  )
                : _buildPalomixPlaceholder(),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 800.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          curve: Curves.easeOut,
        );
  }

  Widget _buildPalomixPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0000),
            Color(0xFF000000),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/palomix.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.movie_filter_rounded,
                  size: 80,
                  color: Color(0xFFDC2626),
                );
              },
            )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text(
              'PALOMIX',
              style: TextStyle(
                color: const Color(0xFFDC2626).withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Movie m) {
    // ✅ Verificación de null para overview
    final hasOverview = m.overview != null && m.overview!.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFDC2626), Colors.orange],
                ).createShader(bounds),
                child: Text(
                  m.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (m.releaseDate != null) ...[
                _buildInfoRow(
                  Icons.calendar_today_rounded,
                  'Estreno',
                  m.releaseDate!,
                ),
                const SizedBox(height: 12),
              ],
              // ✅ Verificación de null corregida
              if (hasOverview) ...[
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.description_rounded,
                        color: Color(0xFFDC2626), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Sinopsis',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  m.overview!, // ✅ Ya verificamos que no es null
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 800.ms)
        .slideX(begin: 0.3, end: 0, curve: Curves.easeOut);
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFDC2626), size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _savingFavorite ? null : _toggleFavorite,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: _isFavorite
                    ? const LinearGradient(
                        colors: [Color(0xFFDC2626), Colors.orange],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                borderRadius: BorderRadius.circular(16),
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
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_savingFavorite)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white,
                      size: 22,
                    )
                        .animate(
                          onPlay: (controller) {
                            if (_isFavorite) {
                              controller.forward();
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
                  const SizedBox(width: 12),
                  Text(
                    _isFavorite ? 'En Favoritos' : 'Añadir a Favoritos',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _loadingSummary ? null : _generateSummary,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.refresh_rounded,
              color: _loadingSummary
                  ? Colors.white.withOpacity(0.5)
                  : Colors.white,
              size: 24,
            ),
          ),
        )
            .animate(onPlay: (controller) {
              if (_loadingSummary) {
                controller.repeat();
              }
            })
            .rotate(duration: 1000.ms),
      ],
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 600.ms)
        .slideY(begin: 0.3, end: 0);
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDC2626), Colors.orange],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resumen IA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Generado con inteligencia artificial',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              if (_loadingSummary)
                Column(
                  children: [
                    const LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: Colors.white24,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFDC2626)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Analizando película con IA...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .fadeIn(duration: 1000.ms)
                    .then()
                    .fadeOut(duration: 1000.ms)
              else
                Text(
                  _summary ??
                      'No pude generar el resumen. Intenta de nuevo.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 600.ms, duration: 800.ms)
        .slideY(begin: 0.3, end: 0);
  }
}
