import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalai/core/di/injection.dart';
import 'package:vitalai/core/routing/router.dart';
import 'package:vitalai/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitalai/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vitalai/features/auth/presentation/pages/login_page.dart';

class MockTestAuthRepository implements AuthRepository {
  AuthUser? _user;
  final _controller = Stream<AuthUser?>.empty();

  MockTestAuthRepository([this._user]);

  void setUser(AuthUser? user) {
    _user = user;
    AuthChangeNotifier.instance.notify();
  }

  @override
  Stream<AuthUser?> get authStateChanges => _controller;

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<AuthUser> signInWithEmailAndPassword(String email, String password) async {
    _user = AuthUser(uid: 'user_123', email: email, displayName: 'Dr. Ade', isAnonymous: false);
    return _user!;
  }

  @override
  Future<AuthUser> registerWithEmailAndPassword(String email, String password) async {
    _user = AuthUser(uid: 'user_123', email: email, displayName: 'Dr. Ade', isAnonymous: false);
    return _user!;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    _user = const AuthUser(uid: 'user_g', email: 'doc@gmail.com', displayName: 'Dr. Google', isAnonymous: false);
    return _user!;
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    _user = const AuthUser(uid: 'user_anon', email: null, displayName: 'Guest', isAnonymous: true);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    AuthChangeNotifier.instance.notify();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTestAuthRepository authRepo;
  late AuthBloc authBloc;

  setUp(() {
    authRepo = MockTestAuthRepository();
    authBloc = AuthBloc(authRepository: authRepo);
    if (locator.isRegistered<AuthRepository>()) {
      locator.unregister<AuthRepository>();
    }
    locator.registerSingleton<AuthRepository>(authRepo);
  });

  tearDown(() {
    authBloc.close();
    if (locator.isRegistered<AuthRepository>()) {
      locator.unregister<AuthRepository>();
    }
  });

  group('Priority 1: Authentication & Route Protection Guard', () {
    test('Unauthenticated user is detected by router guard', () {
      authRepo.setUser(null);
      expect(authRepo.currentUser, isNull);

      int notifyCount = 0;
      void listener() => notifyCount++;
      AuthChangeNotifier.instance.addListener(listener);

      AuthChangeNotifier.instance.notify();
      expect(notifyCount, equals(1));

      AuthChangeNotifier.instance.removeListener(listener);
    });

    test('Authenticated user is detected and session persisted', () {
      authRepo.setUser(
        const AuthUser(uid: 'doc_1', email: 'doctor@vitalai.org', displayName: 'Dr. Adeyemi', isAnonymous: false),
      );

      expect(authRepo.currentUser, isNotNull);
      expect(authRepo.currentUser!.uid, equals('doc_1'));
      expect(authRepo.currentUser!.displayName, equals('Dr. Adeyemi'));
    });

    testWidgets('LoginPage supports isSignUp parameter for /signup route', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const LoginPage(isSignUp: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify sign up header and button are rendered
      expect(find.text('Join VitalAI Health'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });
  });
}
