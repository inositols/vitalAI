import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';

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
    final isDark = context.isDarkMode;

    return Column(
      children: [
        ScaleTransition(
          scale: logoAnimation,
          child: Container(
            width: 88,
            height: 88,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/vitalai_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) {
                  return const Icon(
                    Icons.favorite_rounded,
                    size: 44,
                    color: AppColors.primary,
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FadeTransition(
          opacity: welcomeAnimation,
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: AppDurations.normal,
                child: Text(
                  isSignUp ? 'Join VitalAI Health' : 'Welcome Back',
                  key: ValueKey(isSignUp),
                  style: context.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: AppDurations.normal,
                child: Text(
                  isSignUp
                      ? 'Create your account to start tracking vitals with AI insights'
                      : 'Log in to access real-time clinical monitoring & AI guidance',
                  key: ValueKey(isSignUp ? 'signup_sub' : 'signin_sub'),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
