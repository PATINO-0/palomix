import 'package:equatable/equatable.dart';


abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}


class AuthCheckRequested extends AuthEvent {}


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


class AuthLogoutRequested extends AuthEvent {}
