import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/movie_model.dart';
import '../../bloc/movie/movie_bloc.dart';
import '../../bloc/movie/movie_event.dart';
import '../../bloc/movie/movie_state.dart';
import '../../bloc/favorites/favorites_cubit.dart';
import '../../widgets/app_network_image.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _searchAnimationController;
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _focusNode.addListener(() {
      setState(() {
        _isSearchFocused = _focusNode.hasFocus;
      });
      if (_isSearchFocused) {
        _searchAnimationController.forward();
      } else {
        _searchAnimationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      _focusNode.unfocus();
      context.read<MovieBloc>().add(MovieSearchRequested(query));
    }
  }

  void _onClear() {
    _controller.clear();
    setState(() {});
  }

  void _showMovieDetails(int movieId) {
    context.read<MovieBloc>().add(MovieDetailsRequested(movieId));
    _showDetailsBottomSheet();
  }

  void _addToFavorites(MovieModel movie) {
    context.read<FavoritesCubit>().addToFavorites(
      movieId: movie.id,
      movieTitle: movie.title,
      posterPath: movie.posterPath,
    );
    _showSnackBar('${movie.title} agregado a favoritos ❤️');
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
          return _buildLoadingSheet();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final crossAxisCount = isTablet ? 6 : 4;

    return Container(
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
          // Decoraciones de fondo
          _buildBackgroundDecorations(),
          
          SafeArea(
            child: Column(
              children: [
                // Header con barra de búsqueda
                _buildSearchHeader(),
                
                // Contenido principal
                Expanded(
                  child: BlocBuilder<MovieBloc, MovieState>(
                    builder: (context, state) {
                      if (state is MovieLoading) {
                        return _buildLoadingState();
                      }

                      if (state is MovieSearchSuccess) {
                        final movies = state.movies;
                        if (movies.isEmpty) {
                          return _buildEmptyState(
                            'No se encontraron resultados',
                            'Intenta con otro término de búsqueda',
                            Icons.movie_filter_rounded,
                          );
                        }
                        return _buildMoviesGrid(movies, crossAxisCount);
                      }

                      return _buildEmptyState(
                        'Explora el mundo del cine',
                        'Busca tus películas favoritas',
                        Icons.search_rounded,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildSearchHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Título de la sección
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryRed, Colors.orange],
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
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 24,
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
                        colors: [AppColors.primaryRed, Colors.orange],
                      ).createShader(bounds),
                      child: Text(
                        'Buscar',
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
                      'Encuentra películas y series',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.softWhite.withOpacity(0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: -0.3, end: 0, curve: Curves.easeOut),
          
          const SizedBox(height: 16),
          
          // Barra de búsqueda mejorada
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isSearchFocused
                    ? AppColors.primaryRed.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
                width: 2,
              ),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              boxShadow: _isSearchFocused
                  ? [
                      BoxShadow(
                        color: AppColors.primaryRed.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: _isSearchFocused
                            ? AppColors.primaryRed
                            : AppColors.softWhite.withOpacity(0.5),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          onSubmitted: (_) => _onSearch(),
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Buscar películas, series, actores...',
                            hintStyle: TextStyle(
                              color: AppColors.softWhite.withOpacity(0.5),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (_controller.text.isNotEmpty)
                        GestureDetector(
                          onTap: _onClear,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: AppColors.softWhite,
                              size: 18,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 200.ms)
                            .scale(begin: const Offset(0, 0)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _onSearch,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primaryRed, Colors.orange],
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
                          child: Text(
                            'Buscar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
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
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 600.ms)
              .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
        ],
      ),
    );
  }

  Widget _buildMoviesGrid(List<MovieModel> movies, int crossAxisCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contador de resultados
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.movie_filter_rounded,
                  color: AppColors.primaryRed,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  '${movies.length} resultado${movies.length != 1 ? 's' : ''} encontrado${movies.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: AppColors.softWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.2, end: 0),
          
          const SizedBox(height: 16),
          
          // Grid de películas
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.55,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: movies.length,
              itemBuilder: (context, index) {
                return _buildMovieCard(movies[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieCard(MovieModel movie, int index) {
    return GestureDetector(
      onTap: () => _showMovieDetails(movie.id),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryRed.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: movie.posterPath != null
                  ? Image.network(
                      'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppColors.tertiaryBlack,
                      child: Icon(
                        Icons.movie_rounded,
                        size: 40,
                        color: AppColors.grayWhite,
                      ),
                    ),
            ),
            
            // Gradiente overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
            
            // Rating badge
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      movie.voteAverage.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Botón de favorito
            Positioned(
              top: 6,
              left: 6,
              child: GestureDetector(
                onTap: () => _addToFavorites(movie),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.7),
                    border: Border.all(
                      color: AppColors.primaryRed.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: AppColors.primaryRed,
                    size: 14,
                  ),
                ),
              ),
            ),
            
            // Título
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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
    )
        .animate(delay: (50 * index).ms)
        .fadeIn(duration: 400.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          curve: Curves.easeOut,
        )
        .then()
        .shimmer(
          duration: 2000.ms,
          delay: (100 * index).ms,
          color: Colors.white.withOpacity(0.1),
        );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryRed.withOpacity(0.2),
                  Colors.orange.withOpacity(0.2),
                ],
              ),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
              strokeWidth: 3,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 2000.ms),
          
          const SizedBox(height: 20),
          
          Text(
            'Buscando películas...',
            style: TextStyle(
              color: AppColors.softWhite,
              fontSize: 16,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(duration: 1000.ms)
              .then()
              .fadeOut(duration: 1000.ms),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryRed.withOpacity(0.2),
                  Colors.orange.withOpacity(0.2),
                ],
              ),
              border: Border.all(
                color: AppColors.primaryRed.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 60,
              color: AppColors.primaryRed,
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                begin: const Offset(0.5, 0.5),
                curve: Curves.elasticOut,
              ),
          
          const SizedBox(height: 24),
          
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [AppColors.primaryRed, Colors.orange],
            ).createShader(bounds),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 600.ms)
              .slideY(begin: 0.3, end: 0),
          
          const SizedBox(height: 12),
          
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.softWhite.withOpacity(0.7),
            ),
          )
              .animate()
              .fadeIn(delay: 500.ms, duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildDetailsSheet(MovieDetailsSuccess state) {
    final movie = state.movie;

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
                      )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .scale(
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
                      Icon(Icons.star, color: Colors.amber, size: 20),
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

                  if (movie.overview.isNotEmpty)
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
                      child: Text(
                        movie.overview,
                        style: TextStyle(
                          color: AppColors.softWhite,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),
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
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .scale(begin: const Offset(0, 0), curve: Curves.elasticOut),
              ),
            ],
          ),
        )
            .animate()
            .slideY(begin: 1, duration: 400.ms, curve: Curves.easeOut);
      },
    );
  }

  Widget _buildLoadingSheet() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlack, AppColors.secondaryBlack],
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
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
