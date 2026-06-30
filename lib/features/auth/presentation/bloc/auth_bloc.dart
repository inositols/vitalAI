import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<AuthUser?>? _authStateSubscription;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthEmailSignInPressed>(_onAuthEmailSignInPressed);
    on<AuthEmailSignUpPressed>(_onAuthEmailSignUpPressed);
    on<AuthGoogleSignInPressed>(_onAuthGoogleSignInPressed);
    on<AuthAnonymousSignInPressed>(_onAuthAnonymousSignInPressed);
    on<AuthSignOutPressed>(_onAuthSignOutPressed);

    // Monitor changes in authorization status
    _authStateSubscription = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        add(AuthCheckRequested());
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<void> _onAuthCheckRequested(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    final user = _authRepository.currentUser;
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
      final user = await _authRepository.signInWithEmailAndPassword(
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
      final user = await _authRepository.registerWithEmailAndPassword(
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
      final user = await _authRepository.signInWithGoogle();
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthAnonymousSignInPressed(
      AuthAnonymousSignInPressed event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInAnonymously();
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthSignOutPressed(
      AuthSignOutPressed event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _authRepository.signOut();
    emit(AuthUnauthenticated());
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
