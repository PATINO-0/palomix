import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _navigateToHome();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 4000));
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente animado
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          
          // Círculos flotantes animados de fondo
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -100 + (_pulseController.value * 50),
                    left: -100,
                    child: _buildFloatingCircle(300, Colors.red.withOpacity(0.1)),
                  ),
                  Positioned(
                    bottom: -150 + (_pulseController.value * 40),
                    right: -150,
                    child: _buildFloatingCircle(400, Colors.red.withOpacity(0.08)),
                  ),
                  Positioned(
                    top: size.height * 0.3,
                    right: -50,
                    child: _buildFloatingCircle(200, Colors.white.withOpacity(0.05)),
                  ),
                ],
              );
            },
          ),
          
          // Contenido principal
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Contenedor con efecto glassmorphism para el logo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryRed.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Column(
                        children: [
                          // Ícono de película animado
                          Icon(
                            Icons.movie_creation_rounded,
                            size: 80,
                            color: AppColors.primaryRed,
                          )
                              .animate(onPlay: (controller) => controller.repeat())
                              .rotate(
                                duration: 2000.ms,
                                begin: 0,
                                end: 0.05,
                                curve: Curves.easeInOut,
                              )
                              .then()
                              .rotate(
                                duration: 2000.ms,
                                begin: 0.05,
                                end: -0.05,
                                curve: Curves.easeInOut,
                              )
                              .then()
                              .rotate(
                                duration: 2000.ms,
                                begin: -0.05,
                                end: 0,
                                curve: Curves.easeInOut,
                              ),
                          
                          const SizedBox(height: 20),
                          
                          // Logo PALOMIX
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                AppColors.primaryRed,
                                Colors.orange,
                                AppColors.primaryRed,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'PALOMIX',
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 8,
                                shadows: [
                                  Shadow(
                                    color: AppColors.primaryRed.withOpacity(0.5),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 800.ms)
                              .scale(delay: 200.ms, duration: 600.ms)
                              .then()
                              .shimmer(
                                duration: 2000.ms,
                                color: Colors.white.withOpacity(0.5),
                              ),
                        ],
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(delay: 100.ms, duration: 800.ms, curve: Curves.elasticOut),
                
                const SizedBox(height: 50),
                
                // Subtítulo con efecto typewriter
                Text(
                  'Descubre tu próxima película',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.softWhite,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w300,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1200.ms, duration: 800.ms)
                    .slideY(begin: 0.5, end: 0, curve: Curves.easeOut),
                
                const SizedBox(height: 60),
                
                // Indicador de carga personalizado
                SizedBox(
                  width: 250,
                  child: Column(
                    children: [
                      // Barra de progreso con gradiente
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryRed,
                              Colors.orange,
                              AppColors.primaryRed,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryRed.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(duration: 1500.ms)
                          .shake(duration: 2000.ms, hz: 0.5),
                      
                      const SizedBox(height: 20),
                      
                      // Puntos de carga animados
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryRed.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          )
                              .animate(onPlay: (controller) => controller.repeat())
                              .scale(
                                delay: (300 * index).ms,
                                duration: 600.ms,
                                begin: const Offset(0.5, 0.5),
                                end: const Offset(1.5, 1.5),
                              )
                              .then()
                              .scale(
                                duration: 600.ms,
                                begin: const Offset(1.5, 1.5),
                                end: const Offset(0.5, 0.5),
                              ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1800.ms, duration: 600.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
