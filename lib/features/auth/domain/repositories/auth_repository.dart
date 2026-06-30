import 'package:equatable/equatable.dart';

/// Representation of an authenticated user.
class AuthUser extends Equatable {
  final String uid;
  final String? email;
  final String? displayName;
  final bool isAnonymous;

  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    required this.isAnonymous,
  });

  @override
  List<Object?> get props => [uid, email, displayName, isAnonymous];
}

/// Abstract contract for authentication methods and state tracking.
abstract class AuthRepository {
  /// Stream of user authentication state changes.
  Stream<AuthUser?> get authStateChanges;

  /// Retrieve the currently logged in user, if any.
  AuthUser? get currentUser;

  /// Authenticate using email and password.
  Future<AuthUser> signInWithEmailAndPassword(String email, String password);

  /// Authenticate using Google account.
  Future<AuthUser> signInWithGoogle();

  /// Authenticate as an anonymous offline-only session.
  Future<AuthUser> signInAnonymously();

  /// Register a new account with email and password.
  Future<AuthUser> registerWithEmailAndPassword(String email, String password);

  /// Terminate the current session.
  Future<void> signOut();
}
