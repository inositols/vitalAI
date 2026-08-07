import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vitalai/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:vitalai/features/ai_assistant/presentation/pages/ai_chat_page.dart';
import 'package:vitalai/features/vitals/presentation/pages/charts_page.dart';
import 'package:vitalai/features/vitals/presentation/pages/history_page.dart';
import 'package:vitalai/features/settings/presentation/pages/settings_page.dart';
import 'package:vitalai/features/vitals/presentation/pages/add_vital_page.dart';
import 'package:vitalai/features/patients/presentation/pages/patients_page.dart';
import 'package:vitalai/features/caregiver/presentation/pages/caregiver_page.dart';
import 'package:vitalai/features/auth/presentation/pages/login_page.dart';
import 'package:vitalai/features/onboarding/presentation/pages/splash_page.dart';
import 'package:vitalai/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:vitalai/core/theme/design_tokens.dart';

import 'package:vitalai/features/reminders/presentation/pages/reminders_page.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/patients',
      builder: (context, state) => const PatientsPage(),
    ),
    GoRoute(
      path: '/add-vital',
      builder: (context, state) => const AddVitalPage(),
    ),
    GoRoute(
      path: '/reminders',
      builder: (context, state) => const RemindersPage(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainShellScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardPage(),
          ),
        ),
        GoRoute(
          path: '/charts',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ChartsPage(),
          ),
        ),
        GoRoute(
          path: '/history',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HistoryPage(),
          ),
        ),
        GoRoute(
          path: '/ai-chat',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AiChatPage(),
          ),
        ),
        GoRoute(
          path: '/caregiver',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CaregiverPage(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsPage(),
          ),
        ),
      ],
    ),
  ],
);

class AppRouter {
  static GoRouter get router => appRouter;
}

class MainShellScaffold extends StatelessWidget {
  final Widget child;
  const MainShellScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final String currentLoc = GoRouterState.of(context).uri.path;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final destinations = const [
      NavigationDestination(
        icon: Icon(AppIcons.dashboard),
        selectedIcon: Icon(AppIcons.dashboard, color: AppColors.primary),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(AppIcons.aiAssistant),
        selectedIcon: Icon(AppIcons.aiAssistant, color: AppColors.tertiary),
        label: 'Ask VitalAI',
      ),
      NavigationDestination(
        icon: Icon(AppIcons.chart),
        selectedIcon: Icon(AppIcons.chart, color: AppColors.primary),
        label: 'Analytics',
      ),
      NavigationDestination(
        icon: Icon(AppIcons.settings),
        selectedIcon: Icon(AppIcons.settings, color: AppColors.primary),
        label: 'Settings',
      ),
    ];

    int getSelectedIndex() {
      switch (currentLoc) {
        case '/':
          return 0;
        case '/ai-chat':
          return 1;
        case '/charts':
        case '/history':
          return 2;
        case '/settings':
        case '/caregiver':
          return 3;
        default:
          return 0;
      }
    }

    void onItemTapped(int index) {
      switch (index) {
        case 0:
          context.go('/');
          break;
        case 1:
          context.go('/ai-chat');
          break;
        case 2:
          context.go('/charts');
          break;
        case 3:
          context.go('/settings');
          break;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (currentLoc == '/') {
          context.go('/patients');
        } else {
          context.go('/');
        }
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : const Color(0xFF64748B).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: NavigationBar(
            height: 68,
            elevation: 0,
            backgroundColor: Colors.transparent,
            indicatorColor: getSelectedIndex() == 1
                ? AppColors.tertiary.withValues(alpha: 0.15)
                : AppColors.primary.withValues(alpha: 0.15),
            selectedIndex: getSelectedIndex(),
            onDestinationSelected: onItemTapped,
            destinations: destinations,
          ),
        ),
      ),
    );
  }
}
