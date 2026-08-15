import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/login_form.dart';
import '../widgets/login_header.dart';
import '../widgets/social_login_buttons.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;

  late AnimationController _entryController;
  late Animation<double> _logoAnimation;
  late Animation<double> _welcomeAnimation;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    );
    _welcomeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.15, 0.65, curve: Curves.easeOutCubic),
    );

    _entryController.forward();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/');
        }
      });
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (_isSignUp) {
        context.read<AuthBloc>().add(
              AuthEmailSignUpPressed(email: email, password: password),
            );
      } else {
        context.read<AuthBloc>().add(
              AuthEmailSignInPressed(email: email, password: password),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/');
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LoginHeader(
                      logoAnimation: _logoAnimation,
                      welcomeAnimation: _welcomeAnimation,
                      isSignUp: _isSignUp,
                    ),
                    const SizedBox(height: 32),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return LoginForm(
                          formKey: _formKey,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          isSignUp: _isSignUp,
                          isLoading: state is AuthLoading,
                          onSubmit: _submit,
                          onToggleMode: () {
                            setState(() => _isSignUp = !_isSignUp);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    SocialLoginButtons(
                      onGoogleLogin: () {
                        context
                            .read<AuthBloc>()
                            .add(AuthGoogleSignInPressed());
                      },
                      onAppleLogin: () {
                        context
                            .read<AuthBloc>()
                            .add(AuthGoogleSignInPressed());
                      },
                      onGuestLogin: () {
                        context
                            .read<AuthBloc>()
                            .add(AuthAnonymousSignInPressed());
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
