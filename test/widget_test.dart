import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalai/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitalai/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vitalai/features/auth/presentation/pages/login_page.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late AuthBloc authBloc;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    when(() => mockAuthRepository.authStateChanges)
        .thenAnswer((_) => Stream.value(null));
    authBloc = AuthBloc(authRepository: mockAuthRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  testWidgets('LoginPage renders correctly with fields and buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const LoginPage(),
        ),
      ),
    );

    // Verify presence of branding text
    expect(find.text('Welcome Back'), findsOneWidget);

    // Verify presence of standard Email/Password input forms
    expect(find.byType(TextFormField), findsNWidgets(2));

    // Verify presence of login action button
    expect(find.text('Sign In'), findsOneWidget);
  });
}
