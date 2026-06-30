import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repositories/auth_repository.dart';

/// Concrete implementation of [AuthRepository] combining Firebase Auth
/// and a localized fallback for offline/development mode when Firebase is not configured.
class AuthRepositoryImpl implements AuthRepository {
  final _fallbackController = StreamController<AuthUser?>.broadcast();
  AuthUser? _fallbackUser;
  bool _isFirebaseInitialized = false;

  AuthRepositoryImpl() {
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
        if (user == null) throw Exception("Failed to map sign-in user credentials.");
        return user;
      } catch (e) {
        throw Exception("Email Sign-In Failed: ${e.toString()}");
      }
    } else {
      // Offline fallback: Accept any credentials for testing
      await Future.delayed(const Duration(milliseconds: 600));
      if (email.contains("@") && password.length >= 6) {
        _fallbackUser = AuthUser(
          uid: "offline_user_${email.hashCode}",
          email: email,
          displayName: email.split('@')[0],
          isAnonymous: false,
        );
        _fallbackController.add(_fallbackUser);
        return _fallbackUser!;
      }
      throw Exception("Invalid credentials. Password must be >= 6 characters.");
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
          throw Exception("Google authentication canceled.");
        }

        final credential = fb.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential =
            await fb.FirebaseAuth.instance.signInWithCredential(credential);
        final user = _mapFirebaseUser(userCredential.user);
        if (user == null) throw Exception("Failed to map Google user credentials.");
        return user;
      } catch (e) {
        throw Exception("Google Sign-In Failed: ${e.toString()}");
      }
    } else {
      // Offline fallback
      await Future.delayed(const Duration(milliseconds: 600));
      _fallbackUser = const AuthUser(
        uid: "offline_google_user",
        email: "google.user@example.com",
        displayName: "Google Guest",
        isAnonymous: false,
      );
      _fallbackController.add(_fallbackUser);
      return _fallbackUser!;
    }
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    if (_isFirebaseInitialized) {
      try {
        final credential = await fb.FirebaseAuth.instance.signInAnonymously();
        final user = _mapFirebaseUser(credential.user);
        if (user == null) throw Exception("Failed to map anonymous user credentials.");
        return user;
      } catch (e) {
        throw Exception("Anonymous Sign-In Failed: ${e.toString()}");
      }
    } else {
      // Offline fallback
      await Future.delayed(const Duration(milliseconds: 300));
      _fallbackUser = const AuthUser(
        uid: "offline_anonymous_user",
        email: null,
        displayName: "Guest Patient",
        isAnonymous: true,
      );
      _fallbackController.add(_fallbackUser);
      return _fallbackUser!;
    }
  }

  @override
  Future<AuthUser> registerWithEmailAndPassword(String email, String password) async {
    if (_isFirebaseInitialized) {
      try {
        final credential = await fb.FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        final user = _mapFirebaseUser(credential.user);
        if (user == null) throw Exception("Registration failed.");
        return user;
      } catch (e) {
        throw Exception("Registration Failed: ${e.toString()}");
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
      _fallbackUser = AuthUser(
        uid: "offline_user_${email.hashCode}",
        email: email,
        displayName: email.split('@')[0],
        isAnonymous: false,
      );
      _fallbackController.add(_fallbackUser);
      return _fallbackUser!;
    }
  }

  @override
  Future<void> signOut() async {
    if (_isFirebaseInitialized) {
      await fb.FirebaseAuth.instance.signOut();
    } else {
      _fallbackUser = null;
      _fallbackController.add(_fallbackUser);
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
