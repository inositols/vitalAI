import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalai/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitalai/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vitalai/features/auth/presentation/bloc/auth_event.dart';
import 'package:vitalai/features/auth/presentation/bloc/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late AuthBloc authBloc;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    // Default mock stream behavior
    when(() => mockAuthRepository.authStateChanges)
        .thenAnswer((_) => Stream.value(null));
    authBloc = AuthBloc(authRepository: mockAuthRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc Tests', () {
    const testUser = AuthUser(
      uid: 'test_123',
      email: 'test@example.com',
      displayName: 'Test User',
      isAnonymous: false,
    );

    test('initial state should be AuthInitial', () {
      when(() => mockAuthRepository.authStateChanges)
          .thenAnswer((_) => Stream.empty());
      final emptyBloc = AuthBloc(authRepository: mockAuthRepository);
      expect(emptyBloc.state, equals(AuthInitial()));
      emptyBloc.close();
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when AuthEmailSignInPressed succeeds',
      build: () {
        when(() => mockAuthRepository.signInWithEmailAndPassword(any(), any()))
            .thenAnswer((_) async => testUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthEmailSignInPressed(
        email: 'test@example.com',
        password: 'password123',
      )),
      expect: () => [
        AuthLoading(),
        const AuthAuthenticated(testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when AuthEmailSignInPressed fails',
      build: () {
        when(() => mockAuthRepository.signInWithEmailAndPassword(any(), any()))
            .thenThrow(Exception('Invalid credentials'));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthEmailSignInPressed(
        email: 'bad@example.com',
        password: 'wrongpassword',
      )),
      expect: () => [
        AuthLoading(),
        const AuthFailure('Invalid credentials'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when AuthAnonymousSignInPressed succeeds',
      build: () {
        const anonUser = AuthUser(uid: 'anon_123', isAnonymous: true);
        when(() => mockAuthRepository.signInAnonymously())
            .thenAnswer((_) async => anonUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthAnonymousSignInPressed()),
      expect: () => [
        AuthLoading(),
        const AuthAuthenticated(AuthUser(uid: 'anon_123', isAnonymous: true)),
      ],
    );
  });
}
