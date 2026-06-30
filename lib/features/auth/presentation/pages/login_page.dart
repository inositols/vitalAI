import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Screen managing user login, signup, social OAuth, and guest sign-in.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;

  @override
  void dispose() {
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
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // Success! Route to Patient selection
            context.go('/patients');
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Logo / Branding
                      Icon(
                        Icons.health_and_safety_outlined,
                        size: 72,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'VitalAI',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Your Secure Health Companion',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Form Container
                      Card(
                        elevation: 4,
                        shadowColor: theme.colorScheme.shadow.withOpacity(0.05),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _isSignUp ? 'Create Account' : 'Welcome Back',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 20),

                              // Email Input
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Email Address',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (val) {
                                  if (val == null || !val.contains('@')) {
                                    return 'Please enter a valid email address.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password Input
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outlined),
                                ),
                                validator: (val) {
                                  if (val == null || val.length < 6) {
                                    return 'Password must be at least 6 characters.';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              const SizedBox(height: 24),

                              // Submit Button
                              if (isLoading)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else
                                ElevatedButton(
                                  onPressed: _submit,
                                  child: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                                ),
                              const SizedBox(height: 12),

                              // Toggle Sign In/Up
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isSignUp = !_isSignUp;
                                  });
                                },
                                child: Text(
                                  _isSignUp
                                      ? 'Already have an account? Sign In'
                                      : 'New to VitalAI? Register Here',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Social Login and Offline Mode Separator
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'OR',
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Google Authentication Button
                      OutlinedButton.icon(
                        icon: const Icon(Icons.login),
                        label: const Text('Sign in with Google'),
                        onPressed: isLoading
                            ? null
                            : () {
                                context.read<AuthBloc>().add(AuthGoogleSignInPressed());
                              },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(88, 56),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Guest/Anonymous mode for Offline support
                      ElevatedButton.icon(
                        icon: const Icon(Icons.cloud_off_outlined),
                        label: const Text('Continue Offline (Guest Profile)'),
                        onPressed: isLoading
                            ? null
                            : () {
                                context
                                    .read<AuthBloc>()
                                    .add(AuthAnonymousSignInPressed());
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          foregroundColor: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
