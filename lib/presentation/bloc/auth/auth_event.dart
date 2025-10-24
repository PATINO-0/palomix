import 'package:equatable/equatable.dart';

// Eventos de autenticación
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

// Verificar estado de autenticación
class AuthCheckRequested extends AuthEvent {}

// Iniciar sesión
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  
  const AuthLoginRequested({
    required this.email,
    required this.password,
  });
  
  @override
  List<Object?> get props => [email, password];
}

// Registrar nuevo usuario
class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  
  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.fullName,
  });
  
  @override
  List<Object?> get props => [email, password, fullName];
}

// Cerrar sesión
class AuthLogoutRequested extends AuthEvent {}
