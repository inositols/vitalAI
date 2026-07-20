import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Screen managing user login, signup, social OAuth, and guest sign-in.
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
  bool _showSuccessOverlay = false;

  late AnimationController _bgController;
  late AnimationController _entryController;

  late Animation<double> _logoAnimation;
  late Animation<double> _welcomeAnimation;
  late Animation<double> _formAnimation;
  late Animation<double> _dividerAnimation;
  late Animation<double> _socialAnimation;
  late Animation<double> _guestAnimation;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    );
    _welcomeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.15, 0.65, curve: Curves.easeOutCubic),
    );
    _formAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
    );
    _dividerAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.45, 0.9, curve: Curves.easeOutCubic),
    );
    _socialAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.55, 0.95, curve: Curves.easeOutCubic),
    );
    _guestAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic),
    );

    _entryController.forward();

    // Check if already authenticated on load
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/patients');
        }
      });
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
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

  Widget _buildFadeSlide({
    required Animation<double> animation,
    required Widget child,
  }) {
    final slide = Tween<Offset>(
      begin: const Offset(0.0, 0.05),
      end: Offset.zero,
    ).animate(animation);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: slide, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isHighContrast = false;
    try {
      isHighContrast = context.watch<SettingsBloc>().state.isHighContrast;
    } catch (_) {}

    return Scaffold(
      body: Stack(
        children: [
          // 1. Premium Breathing Canvas Background (bypassed if high contrast)
          if (!isHighContrast)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _BreathingBackgroundPainter(
                      animationValue: _bgController.value,
                      theme: theme,
                    ),
                  );
                },
              ),
            ),

          // 2. Main Login content
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthAuthenticated) {
                setState(() {
                  _showSuccessOverlay = true;
                });
                Future.delayed(const Duration(milliseconds: 1800), () {
                  if (mounted) {
                    context.go('/patients');
                  }
                });
              } else if (state is AuthFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: theme.colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                final isLoading = state is AuthLoading;

                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 40.0,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildFadeSlide(
                            animation: _logoAnimation,
                            child: Center(
                              child: Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.15),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Image.asset(
                                    'assets/images/vitalai_logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildFadeSlide(
                            animation: _welcomeAnimation,
                            child: Text(
                              'Your Secure Health Companion',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onBackground
                                    .withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Glassmorphic Card Container
                          _buildFadeSlide(
                            animation: _formAnimation,
                            child: Container(
                              decoration: isHighContrast
                                  ? BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: theme.colorScheme.onBackground,
                                        width: 2.0,
                                      ),
                                    )
                                  : BoxDecoration(
                                      color:
                                          theme.brightness == Brightness.light
                                          ? Colors.white.withOpacity(0.75)
                                          : theme.colorScheme.surface
                                                .withOpacity(0.65),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color:
                                            theme.brightness == Brightness.light
                                            ? Colors.white.withOpacity(0.6)
                                            : Colors.white.withOpacity(0.08),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 24,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Padding(
                                  padding: const EdgeInsets.all(28.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        _isSignUp
                                            ? 'Create Account'
                                            : 'Welcome Back',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Email Input
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        decoration: const InputDecoration(
                                          labelText: 'Email Address',
                                          prefixIcon: Icon(
                                            Icons.email_outlined,
                                          ),
                                        ),
                                        validator: (val) {
                                          if (val == null ||
                                              !val.contains('@')) {
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
                                      const SizedBox(height: 28),

                                      // Submit Button
                                      if (isLoading)
                                        const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      else
                                        SpringTap(
                                          onTap: _submit,
                                          child: Container(
                                            height: 56,
                                            decoration: BoxDecoration(
                                              gradient: isHighContrast
                                                  ? null
                                                  : LinearGradient(
                                                      colors: [
                                                        theme
                                                            .colorScheme
                                                            .primary,
                                                        theme
                                                            .colorScheme
                                                            .tertiary,
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                    ),
                                              color: isHighContrast
                                                  ? theme.colorScheme.primary
                                                  : null,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: isHighContrast
                                                  ? null
                                                  : [
                                                      BoxShadow(
                                                        color: theme
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.25),
                                                        blurRadius: 12,
                                                        offset: const Offset(
                                                          0,
                                                          4,
                                                        ),
                                                      ),
                                                    ],
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              _isSignUp ? 'Sign Up' : 'Sign In',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 16),

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
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
          if (_showSuccessOverlay) _buildSuccessOverlay(theme),
        ],
      ),
    );
  }

  Widget _buildSuccessOverlay(ThemeData theme) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.55),
        child: Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 650),
            curve: Curves.elasticOut,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Card(
              elevation: 24,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              color: theme.colorScheme.surface,
              child: Container(
                width: 290,
                padding: const EdgeInsets.symmetric(
                  vertical: 36,
                  horizontal: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.25),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 52,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Access Granted',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome to VitalAI',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
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

// 3. Premium Background Breathing Canvas Painter
class _BreathingBackgroundPainter extends CustomPainter {
  final double animationValue;
  final ThemeData theme;

  _BreathingBackgroundPainter({
    required this.animationValue,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    final double radian = animationValue * 2 * math.pi;

    // Blob 1: Soft Purple-Indigo (top-left moving)
    final double cx1 = size.width * 0.15 + 60 * math.cos(radian);
    final double cy1 = size.height * 0.15 + 60 * math.sin(radian);
    final double radius1 = size.width * 0.45 + 30 * math.sin(radian);
    final paint1 = paint..color = theme.colorScheme.primary.withOpacity(0.12);
    canvas.drawCircle(Offset(cx1, cy1), radius1, paint1);

    // Blob 2: Soft Violet (bottom-right moving)
    final double cx2 = size.width * 0.8 + 60 * math.cos(radian + math.pi);
    final double cy2 = size.height * 0.75 + 60 * math.sin(radian + math.pi);
    final double radius2 = size.width * 0.5 + 40 * math.cos(radian);
    final paint2 = paint..color = theme.colorScheme.tertiary.withOpacity(0.10);
    canvas.drawCircle(Offset(cx2, cy2), radius2, paint2);

    // Blob 3: Emerald (subtle green blob at middle right)
    final double cx3 = size.width * 0.85 + 40 * math.sin(radian * 2);
    final double cy3 = size.height * 0.35 + 40 * math.cos(radian * 2);
    final double radius3 = size.width * 0.3 + 20 * math.sin(radian);
    final paint3 = paint..color = theme.colorScheme.secondary.withOpacity(0.06);
    canvas.drawCircle(Offset(cx3, cy3), radius3, paint3);
  }

  @override
  bool shouldRepaint(covariant _BreathingBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// 4. Custom spring animation tap wrapper
class SpringTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const SpringTap({super.key, required this.child, this.onTap});

  @override
  State<SpringTap> createState() => _SpringTapState();
}

class _SpringTapState extends State<SpringTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => widget.onTap != null ? _controller.forward() : null,
      onTapUp: (_) {
        if (widget.onTap != null) {
          _controller.reverse();
          widget.onTap!();
        }
      },
      onTapCancel: () => widget.onTap != null ? _controller.reverse() : null,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
