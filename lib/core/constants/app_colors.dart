// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryRed = Color(0xFFE50914);
  static const Color softWhite = Color(0xFFF5F5F5);

  static const Gradient primaryGradient = LinearGradient(
    colors: [
      Colors.black,
      Color(0xFF1A0000),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
