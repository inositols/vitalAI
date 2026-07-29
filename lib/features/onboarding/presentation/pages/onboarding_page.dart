import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_button.dart';

class OnboardingSlide {
  final String title;
  final String description;
  final String imagePath;
  final IconData fallbackIcon;
  final String badgeText;

  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.fallbackIcon,
    required this.badgeText,
  });
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  late AnimationController _floatController;

  static const List<OnboardingSlide> _slides = [
    OnboardingSlide(
      badgeText: 'PRECISION TRACKING',
      title: 'Real-Time Vitals Monitoring',
      description:
          'Track Blood Pressure, Glucose, Heart Rate, SpO₂, and Weight with precision color-coded indicators.',
      imagePath: 'assets/images/onboarding_vitals.png',
      fallbackIcon: Icons.monitor_heart_rounded,
    ),
    OnboardingSlide(
      badgeText: 'GEMINI AI INSIGHTS',
      title: 'Clinical AI Companion',
      description:
          'Get instant, personalized health insights and proactive advice powered by Google Gemini AI.',
      imagePath: 'assets/images/onboarding_ai.png',
      fallbackIcon: Icons.auto_awesome_rounded,
    ),
    OnboardingSlide(
      badgeText: 'FAMILY & CAREGIVER SYNC',
      title: 'Caregiver Remote Sharing',
      description:
          'Seamlessly share real-time health updates and emergency notifications with doctors and caregivers.',
      imagePath: 'assets/images/onboarding_caregiver.png',
      fallbackIcon: Icons.people_alt_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Brand Logo & Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/vitalai_logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, stack) => const Icon(
                              Icons.favorite_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'VitalAI',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page Content Carousel with Wide Edge-to-Edge Motion (Up -> Right -> Down -> Left)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),

                        // Dynamic Wide Motion Container (Reaches outer edges of parent widget)
                        SizedBox(
                          height: 270,
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _floatController,
                              builder: (context, child) {
                                final angle = _floatController.value * 2 * math.pi;
                                // 60px horizontal travel and 30px vertical travel to reach edges
                                final dx = 60.0 * math.sin(angle);
                                final dy = -30.0 * math.cos(angle);
                                return Transform.translate(
                                  offset: Offset(dx, dy),
                                  child: child,
                                );
                              },
                              child: AnimatedSwitcher(
                                duration: AppDurations.normal,
                                transitionBuilder: (child, anim) {
                                  return ScaleTransition(
                                    scale: CurvedAnimation(
                                      parent: anim,
                                      curve: Curves.easeOutBack,
                                    ),
                                    child: FadeTransition(opacity: anim, child: child),
                                  );
                                },
                                child: Container(
                                  key: ValueKey(slide.imagePath),
                                  height: 200,
                                  constraints: const BoxConstraints(maxWidth: 240),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.22),
                                        blurRadius: 36,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                                    child: Image.asset(
                                      slide.imagePath,
                                      fit: BoxFit.contain,
                                      errorBuilder: (ctx, err, stack) {
                                        return Container(
                                          width: 120,
                                          height: 120,
                                          decoration: const BoxDecoration(
                                            gradient: AppColors.primaryGradient,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(slide.fallbackIcon, size: 54, color: Colors.white),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Badge Pill
                        AnimatedSwitcher(
                          duration: AppDurations.fast,
                          child: Container(
                            key: ValueKey(slide.badgeText),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              slide.badgeText,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Title with Animated Switcher
                        AnimatedSwitcher(
                          duration: AppDurations.normal,
                          child: Text(
                            slide.title,
                            key: ValueKey(slide.title),
                            style: context.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 23,
                              letterSpacing: -0.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Description
                        AnimatedSwitcher(
                          duration: AppDurations.normal,
                          child: Text(
                            slide.description,
                            key: ValueKey(slide.description),
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontSize: 13.5,
                              height: 1.45,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Dots & Action Controls
            Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                children: [
                  // Dynamic Stretching Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final isActive = index == _currentIndex;
                      return AnimatedContainer(
                        duration: AppDurations.normal,
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 32 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Next / Get Started Action Button
                  AppButton(
                    label: _currentIndex == _slides.length - 1 ? 'Get Started' : 'Next',
                    icon: _currentIndex == _slides.length - 1
                        ? Icons.check_circle_outline_rounded
                        : Icons.arrow_forward_rounded,
                    onPressed: () {
                      if (_currentIndex == _slides.length - 1) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: AppDurations.normal,
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
