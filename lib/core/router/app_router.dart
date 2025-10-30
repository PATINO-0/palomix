import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/supabase_service.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';


class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = SupabaseService.getCurrentUser();
      final isLoggedIn = user != null;
      
      final isLoginRoute = state.matchedLocation == '/login';
      final isRegisterRoute = state.matchedLocation == '/register';
      final isSplashRoute = state.matchedLocation == '/';
      
      
      if (isSplashRoute) {
        return null;
      }
      
      
      if (!isLoggedIn && !isLoginRoute && !isRegisterRoute) {
        return '/login';
      }
      
      
      if (isLoggedIn && (isLoginRoute || isRegisterRoute)) {
        return '/home';
      }
      
      return null;
    },
    routes: [
      
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      
      
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    
    
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}
