import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  StreamSubscription<AuthUser?>? _authStateSubscription;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthEmailSignInPressed>(_onAuthEmailSignInPressed);
    on<AuthEmailSignUpPressed>(_onAuthEmailSignUpPressed);
    on<AuthGoogleSignInPressed>(_onAuthGoogleSignInPressed);
    on<AuthAnonymousSignInPressed>(_onAuthAnonymousSignInPressed);
    on<AuthSignOutPressed>(_onAuthSignOutPressed);

    _authStateSubscription = authRepository.authStateChanges.listen((_) {
      add(AuthCheckRequested());
    });
  }

  Future<void> _onAuthCheckRequested(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    final user = authRepository.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthEmailSignInPressed(
      AuthEmailSignInPressed event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithEmailAndPassword(
          event.email, event.password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthEmailSignUpPressed(
      AuthEmailSignUpPressed event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.registerWithEmailAndPassword(
          event.email, event.password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthGoogleSignInPressed(
      AuthGoogleSignInPressed event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithGoogle();
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthAnonymousSignInPressed(
      AuthAnonymousSignInPressed event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInAnonymously();
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthSignOutPressed(
      AuthSignOutPressed event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
