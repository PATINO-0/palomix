import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/supabase_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

// BLoC para manejar autenticación
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    // Verificar estado de autenticación
    on<AuthCheckRequested>(_onCheckRequested);
    
    // Manejar inicio de sesión
    on<AuthLoginRequested>(_onLoginRequested);
    
    // Manejar registro
    on<AuthSignUpRequested>(_onSignUpRequested);
    
    // Manejar cierre de sesión
    on<AuthLogoutRequested>(_onLogoutRequested);
    
    // Escuchar cambios en el estado de autenticación
    _authStateSubscription();
  }
  
  void _authStateSubscription() {
    SupabaseService.authStateChanges.listen((event) {
      if (event.session != null) {
        add(AuthCheckRequested());
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }
  
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = SupabaseService.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Error al verificar autenticación'));
    }
  }
  
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await SupabaseService.signIn(
        email: event.email,
        password: event.password,
      );
      
      if (response.user != null) {
        emit(AuthAuthenticated(response.user!));
      } else {
        emit(const AuthError('Error al iniciar sesión'));
      }
    } catch (e) {
      emit(AuthError('Credenciales incorrectas: ${e.toString()}'));
    }
  }
  
  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await SupabaseService.signUp(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
      );
      
      if (response.user != null) {
        emit(AuthAuthenticated(response.user!));
      } else {
        emit(const AuthError('Error al registrar usuario'));
      }
    } catch (e) {
      emit(AuthError('Error en el registro: ${e.toString()}'));
    }
  }
  
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await SupabaseService.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Error al cerrar sesión: ${e.toString()}'));
    }
  }
}
