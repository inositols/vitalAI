import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthEmailSignInPressed extends AuthEvent {
  final String email;
  final String password;

  const AuthEmailSignInPressed({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthEmailSignUpPressed extends AuthEvent {
  final String email;
  final String password;

  const AuthEmailSignUpPressed({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthGoogleSignInPressed extends AuthEvent {}

class AuthAnonymousSignInPressed extends AuthEvent {}

class AuthSignOutPressed extends AuthEvent {}
