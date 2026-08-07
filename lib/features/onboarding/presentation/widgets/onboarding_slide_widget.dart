import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final String badgeText;
  final Color accentColor;
  final List<String> featureChips;

  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.badgeText,
    this.accentColor = AppColors.primary,
    this.featureChips = const [],
  });
}

class OnboardingSlideWidget extends StatelessWidget {
  final OnboardingSlide slide;
  final AnimationController floatController;
  final bool isDark;

  const OnboardingSlideWidget({
    super.key,
    required this.slide,
    required this.floatController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Breathtaking Multi-Layer Hero Animation Container
          SizedBox(
            height: 320,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Concentric Multi-Ring Pulse & Floating Logo Core
                AnimatedBuilder(
                  animation: floatController,
                  builder: (context, child) {
                    final angle = floatController.value * 2 * math.pi;
                    final dy = -14.0 * math.sin(angle);
                    // Dramatic concentric pulse scale (Expands up to 1.35x outwards!)
                    final pulseScale = 1.0 + 0.35 * (0.5 + 0.5 * math.sin(angle));
                    final pulseOpacity = (0.35 - 0.20 * (0.5 + 0.5 * math.sin(angle))).clamp(0.05, 0.40);

                    return Transform.translate(
                      offset: Offset(0, dy),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer Concentric Pulse Ring 1 (Deep Outward Aura)
                          Transform.scale(
                            scale: pulseScale + 0.20,
                            child: Container(
                              width: 230,
                              height: 230,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: slide.accentColor.withValues(alpha: pulseOpacity * 0.35),
                                border: Border.all(
                                  color: slide.accentColor.withValues(alpha: pulseOpacity * 0.6),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),

                          // Outer Concentric Pulse Ring 2 (Mid Pulse)
                          Transform.scale(
                            scale: pulseScale + 0.10,
                            child: Container(
                              width: 195,
                              height: 195,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: slide.accentColor.withValues(alpha: pulseOpacity * 0.6),
                                border: Border.all(
                                  color: slide.accentColor.withValues(alpha: pulseOpacity * 0.8),
                                  width: 1.8,
                                ),
                              ),
                            ),
                          ),

                          // Outer Concentric Pulse Ring 3 (Inner Pulse)
                          Transform.scale(
                            scale: pulseScale,
                            child: Container(
                              width: 165,
                              height: 165,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: slide.accentColor.withValues(alpha: pulseOpacity * 0.9),
                                border: Border.all(
                                  color: slide.accentColor.withValues(alpha: 0.5),
                                  width: 2.0,
                                ),
                              ),
                            ),
                          ),

                          // Floating Hero Core Logo Badge (100% Concentric Center)
                          Container(
                            width: 145,
                            height: 145,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  slide.accentColor,
                                  slide.accentColor.withValues(alpha: 0.75),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: slide.accentColor.withValues(alpha: 0.4),
                                  blurRadius: 36,
                                  spreadRadius: 4,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 118,
                                height: 118,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? AppColors.darkBackground : Colors.white,
                                ),
                                child: Center(
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [slide.accentColor, AppColors.secondary],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds),
                                    child: Icon(
                                      slide.icon,
                                      size: 62,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Satellite Floating Feature Pills
                if (slide.featureChips.isNotEmpty) ...[
                  Positioned(
                    top: 22,
                    left: 12,
                    child: _buildSatelliteBadge(slide.featureChips[0], slide.accentColor, isDark),
                  ),
                  if (slide.featureChips.length > 1)
                    Positioned(
                      bottom: 24,
                      right: 12,
                      child: _buildSatelliteBadge(slide.featureChips[1], slide.accentColor, isDark),
                    ),
                  if (slide.featureChips.length > 2)
                    Positioned(
                      top: 130,
                      right: 4,
                      child: _buildSatelliteBadge(slide.featureChips[2], slide.accentColor, isDark),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Slide Category Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: slide.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: slide.accentColor.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Text(
              slide.badgeText,
              style: TextStyle(
                color: slide.accentColor,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Slide Title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          // Slide Description
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14.5,
              height: 1.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSatelliteBadge(String text, Color color, bool isDark) {
    return AnimatedBuilder(
      animation: floatController,
      builder: (context, child) {
        final val = floatController.value * 2 * math.pi;
        final dy = 6.0 * math.cos(val);
        return Transform.translate(
          offset: Offset(0, dy),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
