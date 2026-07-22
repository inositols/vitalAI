import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';

class LoginHeader extends StatelessWidget {
  final Animation<double> logoAnimation;
  final Animation<double> welcomeAnimation;
  final bool isSignUp;

  const LoginHeader({
    super.key,
    required this.logoAnimation,
    required this.welcomeAnimation,
    required this.isSignUp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScaleTransition(
          scale: logoAnimation,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.colorScheme.primary,
                  context.colorScheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: context.colorScheme.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite,
              size: 42,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeTransition(
          opacity: welcomeAnimation,
          child: Column(
            children: [
              Text(
                isSignUp ? 'Create VitalAI Account' : 'Welcome Back',
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                isSignUp
                    ? 'Join VitalAI to track your vitals with context-aware AI insights'
                    : 'Log in to securely access your personal health records',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
