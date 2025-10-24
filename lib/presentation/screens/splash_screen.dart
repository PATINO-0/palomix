import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

// Pantalla de inicio con animación
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  // Navegar después de la animación
  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animado
              Text(
                'PALOMIX',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryRed,
                  letterSpacing: 8,
                ),
              )
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .scale(delay: 200.ms, duration: 600.ms)
                  .shimmer(delay: 800.ms, duration: 1200.ms),
              
              const SizedBox(height: 24),
              
              // Subtítulo
              Text(
                'Descubre tu próxima película',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.softWhite,
                  letterSpacing: 2,
                ),
              )
                  .animate()
                  .fadeIn(delay: 1000.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),
              
              const SizedBox(height: 60),
              
              // Indicador de carga
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.tertiaryBlack,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 1500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
