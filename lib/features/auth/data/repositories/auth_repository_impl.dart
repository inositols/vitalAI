import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Concrete implementation of [AuthRepository] combining Firebase Auth
/// and a localized fallback for offline/development mode when Firebase is not configured.
class AuthRepositoryImpl implements AuthRepository {
  final FlutterSecureStorage _secureStorage;
  final _fallbackController = StreamController<AuthUser?>.broadcast();
  AuthUser? _fallbackUser;
  bool _isFirebaseInitialized = false;

  AuthRepositoryImpl(this._secureStorage) {
    _determineFirebaseStatus();
  }

  void _determineFirebaseStatus() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _isFirebaseInitialized = true;
      }
    } catch (_) {
      _isFirebaseInitialized = false;
    }

    if (!_isFirebaseInitialized) {
      // Start in anonymous/offline mode as fallback
      _fallbackUser = null;
      _fallbackController.add(_fallbackUser);
    }
  }

  /// Initialize local stored session if in offline fallback mode.
  Future<void> init() async {
    if (!_isFirebaseInitialized) {
      final storedUserJson = await _secureStorage.read(key: 'offline_auth_user');
      if (storedUserJson != null) {
        try {
          final map = jsonDecode(storedUserJson) as Map<String, dynamic>;
          _fallbackUser = AuthUser(
            uid: map['uid'] as String,
            email: map['email'] as String?,
            displayName: map['displayName'] as String?,
            isAnonymous: map['isAnonymous'] as bool? ?? false,
          );
          _fallbackController.add(_fallbackUser);
        } catch (_) {
          // Ignore corruption
        }
      }
    }
  }

  Future<void> _persistFallbackUser(AuthUser? user) async {
    _fallbackUser = user;
    _fallbackController.add(user);
    if (user != null) {
      final map = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'isAnonymous': user.isAnonymous,
      };
      await _secureStorage.write(key: 'offline_auth_user', value: jsonEncode(map));
    } else {
      await _secureStorage.delete(key: 'offline_auth_user');
    }
  }

  @override
  Stream<AuthUser?> get authStateChanges {
    if (_isFirebaseInitialized) {
      return fb.FirebaseAuth.instance.authStateChanges().map(_mapFirebaseUser);
    } else {
      return _fallbackController.stream;
    }
  }

  @override
  AuthUser? get currentUser {
    if (_isFirebaseInitialized) {
      return _mapFirebaseUser(fb.FirebaseAuth.instance.currentUser);
    } else {
      return _fallbackUser;
    }
  }

  @override
  Future<AuthUser> signInWithEmailAndPassword(String email, String password) async {
    if (_isFirebaseInitialized) {
      try {
        final credential = await fb.FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        final user = _mapFirebaseUser(credential.user);
        if (user == null) throw const AuthException("Failed to map sign-in user credentials.");
        return user;
      } catch (e) {
        throw AuthException(_mapFirebaseAuthError(e, isSignUp: false));
      }
    } else {
      // Offline fallback: Accept any credentials for testing
      await Future.delayed(const Duration(milliseconds: 600));
      if (email.contains("@") && password.length >= 6) {
        final user = AuthUser(
          uid: "offline_user_${email.hashCode}",
          email: email,
          displayName: email.split('@')[0],
          isAnonymous: false,
        );
        await _persistFallbackUser(user);
        return user;
      }
      throw const AuthException("Invalid credentials. Password must be >= 6 characters.");
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    if (_isFirebaseInitialized) {
      try {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        final GoogleSignInAuthentication? googleAuth =
            await googleUser?.authentication;

        if (googleAuth == null) {
          throw const AuthException("Google authentication canceled.");
        }

        final credential = fb.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential =
            await fb.FirebaseAuth.instance.signInWithCredential(credential);
        final user = _mapFirebaseUser(userCredential.user);
        if (user == null) throw const AuthException("Failed to map Google user credentials.");
        return user;
      } catch (e) {
        throw AuthException("Google Sign-In Failed: ${_mapFirebaseAuthError(e, isSignUp: false)}");
      }
    } else {
      // Offline fallback
      await Future.delayed(const Duration(milliseconds: 600));
      final user = const AuthUser(
        uid: "offline_google_user",
        email: "google.user@example.com",
        displayName: "Google Guest",
        isAnonymous: false,
      );
      await _persistFallbackUser(user);
      return user;
    }
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    if (_isFirebaseInitialized) {
      try {
        final credential = await fb.FirebaseAuth.instance.signInAnonymously();
        final user = _mapFirebaseUser(credential.user);
        if (user == null) throw const AuthException("Failed to map anonymous user credentials.");
        return user;
      } catch (e) {
        throw AuthException("Anonymous Sign-In Failed: ${_mapFirebaseAuthError(e, isSignUp: false)}");
      }
    } else {
      // Offline fallback
      await Future.delayed(const Duration(milliseconds: 300));
      final user = const AuthUser(
        uid: "offline_anonymous_user",
        email: null,
        displayName: "Guest Patient",
        isAnonymous: true,
      );
      await _persistFallbackUser(user);
      return user;
    }
  }

  @override
  Future<AuthUser> registerWithEmailAndPassword(String email, String password) async {
    if (_isFirebaseInitialized) {
      try {
        final credential = await fb.FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        final user = _mapFirebaseUser(credential.user);
        if (user == null) throw const AuthException("Registration failed.");
        return user;
      } catch (e) {
        throw AuthException(_mapFirebaseAuthError(e, isSignUp: true));
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
      final user = AuthUser(
        uid: "offline_user_${email.hashCode}",
        email: email,
        displayName: email.split('@')[0],
        isAnonymous: false,
      );
      await _persistFallbackUser(user);
      return user;
    }
  }

  String _mapFirebaseAuthError(dynamic e, {required bool isSignUp}) {
    if (e is fb.FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'The email address is badly formatted.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'user-not-found':
          return 'No user found with this email. Please sign up first.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-credential':
          return 'Incorrect email or password. Please try again.';
        case 'too-many-requests':
          return 'Too many login attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'email-already-in-use':
          return 'This email is already registered. Please sign in instead.';
        case 'weak-password':
          return 'The password is too weak. Please use a stronger password (at least 6 characters).';
        case 'operation-not-allowed':
          return 'Email/password accounts are not enabled.';
        default:
          return e.message ?? 'An authentication error occurred. Please try again.';
      }
    }
    // Clean up generic exceptions
    final str = e.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring(11);
    }
    return str;
  }

  @override
  Future<void> signOut() async {
    await _secureStorage.delete(key: 'offline_auth_user');
    if (_isFirebaseInitialized) {
      await fb.FirebaseAuth.instance.signOut();
    } else {
      _fallbackUser = null;
      _fallbackController.add(null);
    }
  }

  AuthUser? _mapFirebaseUser(fb.User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      isAnonymous: user.isAnonymous,
    );
  }
}
