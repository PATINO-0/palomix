import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/api_constants.dart';
import 'core/constants/app_colors.dart';
import 'core/router/app_router.dart';
import 'core/config/tmdb_config.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_event.dart';
import 'presentation/bloc/movie/movie_bloc.dart';
import 'presentation/bloc/favorites/favorites_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TmdbConfig.load();
  await Supabase.initialize(
    url: ApiConstants.supabaseUrl,
    anonKey: ApiConstants.supabaseAnonKey,
  );
  final hasApiKey = TmdbConfig.apiKey.isNotEmpty;
  final hasBearer = TmdbConfig.bearerToken.isNotEmpty;
  debugPrint('TMDB config -> api_key: $hasApiKey, bearer: $hasBearer');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryRed,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.primaryBlack,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.secondaryBlack,
        foregroundColor: AppColors.pureWhite,
      ),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(AuthCheckRequested()),
        ),
        BlocProvider<MovieBloc>(
          create: (context) => MovieBloc(),
        ),
        BlocProvider<FavoritesCubit>(
          create: (context) => FavoritesCubit(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Palomix',
        theme: theme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false, 
      ),
    );
  }
}
