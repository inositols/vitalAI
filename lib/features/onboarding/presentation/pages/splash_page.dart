import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_brand_logo.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();
    _navigateNext();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 180,
            child: CustomPaint(
              painter: _SplashWavePainter(
                color: isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.5)
                    : const Color(0xFFE2F4EE),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                ScaleTransition(
                  scale: _scaleAnim,
                  child: const AppBrandLogo(size: 80),
                ),
                const SizedBox(height: 24),

                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      Text(
                        'VoiceVitals',
                        style: AppTypography.displayMedium(
                          color: isDark ? Colors.white : AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your Voice. Better Care.',
                        style: AppTypography.titleMedium(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'The AI voice assistant for healthcare providers.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: Text(
                      'Smart. Secure. Clinical.',
                      style: AppTypography.labelSmall(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashWavePainter extends CustomPainter {
  final Color color;

  _SplashWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.4);
    path.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.1,
      size.width * 0.7,
      size.height * 0.35,
    );
    path.quadraticBezierTo(
      size.width * 0.88,
      size.height * 0.5,
      size.width,
      size.height * 0.25,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
