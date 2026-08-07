import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_brand_logo.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/onboarding_slide_widget.dart';

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
      icon: AppIcons.pulse,
      accentColor: AppColors.primary,
      featureChips: ['BP: 120/80 mmHg', 'Glucose: 95 mg/dL', 'SpO₂: 98%'],
    ),
    OnboardingSlide(
      badgeText: 'GEMINI AI INSIGHTS',
      title: 'Clinical AI Companion',
      description:
          'Get instant, personalized health insights and proactive advice powered by Google Gemini AI.',
      icon: AppIcons.aiAssistant,
      accentColor: AppColors.tertiary,
      featureChips: ['Gemini 1.5 Pro', 'GenUI Cards', 'Instant Analysis'],
    ),
    OnboardingSlide(
      badgeText: 'FAMILY & CAREGIVER SYNC',
      title: 'Caregiver Remote Sharing',
      description:
          'Seamlessly share real-time health updates and emergency notifications with doctors and caregivers.',
      icon: AppIcons.patients,
      accentColor: AppColors.secondary,
      featureChips: ['Emergency Sync', 'Doctor PDF Reports', 'Family Access'],
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      AppBrandLogo(
                        size: 34,
                        iconSize: 18,
                      ),
                      SizedBox(width: 10),
                      Text(
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
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  return OnboardingSlideWidget(
                    slide: _slides[index],
                    floatController: _floatController,
                    isDark: isDark,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 10,
                        width: _currentIndex == index ? 36 : 10,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? _slides[_currentIndex].accentColor
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: _currentIndex == index
                              ? [
                                  BoxShadow(
                                    color: _slides[_currentIndex].accentColor.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: _currentIndex == _slides.length - 1 ? 'Get Started' : 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () {
                      if (_currentIndex < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeOnboarding();
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
