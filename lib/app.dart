// lib/app.dart
import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'features/splash/splash_screen.dart';

class PalomixApp extends StatelessWidget {
  const PalomixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Palomix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(),
      home: const SplashScreen(), 
    );
  }
}
