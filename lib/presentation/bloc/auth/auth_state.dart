import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Estados de autenticación
abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

// Estado inicial
class AuthInitial extends AuthState {}

// Cargando
class AuthLoading extends AuthState {}

// Usuario autenticado
class AuthAuthenticated extends AuthState {
  final User user;
  
  const AuthAuthenticated(this.user);
  
  @override
  List<Object?> get props => [user];
}

// Usuario no autenticado
class AuthUnauthenticated extends AuthState {}

// Error de autenticación
class AuthError extends AuthState {
  final String message;
  
  const AuthError(this.message);
  
  @override
  List<Object?> get props => [message];
}
