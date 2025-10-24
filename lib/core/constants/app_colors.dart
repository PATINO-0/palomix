import 'package:flutter/material.dart';

// Paleta de colores futurista: negro, blanco y rojo
class AppColors {
  // Colores principales
  static const Color primaryBlack = Color(0xFF0A0A0A);
  static const Color secondaryBlack = Color(0xFF1A1A1A);
  static const Color tertiaryBlack = Color(0xFF2A2A2A);
  
  static const Color primaryRed = Color(0xFFE50914);
  static const Color secondaryRed = Color(0xFFB20710);
  static const Color accentRed = Color(0xFFFF1744);
  
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color softWhite = Color(0xFFF5F5F5);
  static const Color grayWhite = Color(0xFFE0E0E0);
  
  // Colores de estado
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningYellow = Color(0xFFFFC107);
  static const Color errorRed = Color(0xFFFF5252);
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlack, secondaryBlack],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [primaryRed, secondaryRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
