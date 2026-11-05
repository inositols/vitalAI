import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vitalai/core/di/injection.dart';
import 'package:vitalai/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitalai/features/assistant/presentation/pages/assistant_page.dart';
import 'package:vitalai/features/patients/presentation/pages/patients_page.dart';
import 'package:vitalai/features/activity/presentation/pages/activity_page.dart';
import 'package:vitalai/features/vitals/presentation/pages/confirm_vital_page.dart';
import 'package:vitalai/features/vitals/presentation/pages/charts_page.dart';
import 'package:vitalai/features/vitals/presentation/pages/history_page.dart';
import 'package:vitalai/features/settings/presentation/pages/settings_page.dart';
import 'package:vitalai/features/vitals/presentation/pages/add_vital_page.dart';
import 'package:vitalai/features/caregiver/presentation/pages/caregiver_page.dart';
import 'package:vitalai/features/auth/presentation/pages/login_page.dart';
import 'package:vitalai/features/onboarding/presentation/pages/splash_page.dart';
import 'package:vitalai/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:vitalai/core/theme/design_tokens.dart';
import 'package:vitalai/features/reminders/presentation/pages/reminders_page.dart';
import 'package:vitalai/features/ai_assistant/presentation/pages/ai_chat_page.dart';
import 'package:vitalai/features/ai_model_test/presentation/pages/ai_model_test_page.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Listenable that notifies GoRouter to re-evaluate route guards whenever auth status changes.
class AuthChangeNotifier extends ChangeNotifier {
  static final AuthChangeNotifier instance = AuthChangeNotifier._();
  AuthChangeNotifier._();

  void notify() => notifyListeners();
}

bool _isUserAuthenticated() {
  if (locator.isRegistered<AuthRepository>()) {
    return locator<AuthRepository>().currentUser != null;
  }
  return false;
}

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  refreshListenable: AuthChangeNotifier.instance,
  redirect: (BuildContext context, GoRouterState state) {
    final isAuth = _isUserAuthenticated();
    final loc = state.uri.path;
    final isAuthPath = loc == '/login' ||
        loc == '/signup' ||
        loc == '/splash' ||
        loc == '/onboarding';

    // Unauthenticated user trying to access protected shell/app routes
    if (!isAuth && !isAuthPath) {
      return '/login';
    }

    // Authenticated user trying to access login/signup
    if (isAuth && (loc == '/login' || loc == '/signup')) {
      return '/';
    }

    return null;
  },
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
      path: '/signup',
      builder: (context, state) => const LoginPage(isSignUp: true),
    ),
    GoRoute(
      path: '/add-vital',
      builder: (context, state) => const AddVitalPage(),
    ),
    GoRoute(
      path: '/confirm-vital',
      builder: (context, state) => const ConfirmVitalPage(),
    ),
    GoRoute(
      path: '/ai-model-test',
      builder: (context, state) => const AiModelTestPage(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainShellScaffold(child: child);
      },
      routes: [
        // 1. Assistant (Home)
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AssistantPage(),
          ),
        ),
        GoRoute(
          path: '/assistant',
          redirect: (context, state) => '/',
        ),
        // 2. Patients
        GoRoute(
          path: '/patients',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PatientsPage(),
          ),
        ),
        // 3. Activity
        GoRoute(
          path: '/activity',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ActivityPage(),
          ),
        ),

        // Preserved Sub-routes for deep navigation and backwards compatibility
        GoRoute(
          path: '/charts',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ChartsPage(),
          ),
        ),
        GoRoute(
          path: '/vitals',
          redirect: (context, state) => '/charts',
        ),
        GoRoute(
          path: '/ai-chat',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AiChatPage(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsPage(),
          ),
        ),
        GoRoute(
          path: '/reminders',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: RemindersPage(),
          ),
        ),
        GoRoute(
          path: '/history',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HistoryPage(),
          ),
        ),
        GoRoute(
          path: '/caregiver',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CaregiverPage(),
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

    // 3 Primary Destinations matching VoiceVitals specifications
    final destinations = const [
      NavigationDestination(
        icon: Icon(Icons.mic_none_rounded),
        selectedIcon: Icon(Icons.mic_rounded, color: AppColors.primary),
        label: 'Assistant',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
        label: 'Patients',
      ),
      NavigationDestination(
        icon: Icon(Icons.schedule_rounded),
        selectedIcon: Icon(Icons.schedule_rounded, color: AppColors.primary),
        label: 'Activity',
      ),
    ];

    int getSelectedIndex() {
      switch (currentLoc) {
        case '/':
        case '/assistant':
        case '/ai-chat':
          return 0;
        case '/patients':
        case '/caregiver':
          return 1;
        case '/activity':
        case '/history':
        case '/charts':
        case '/reminders':
          return 2;
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
          context.go('/patients');
          break;
        case 2:
          context.go('/activity');
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
                    : const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: NavigationBar(
            height: 64,
            elevation: 0,
            backgroundColor: Colors.transparent,
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            selectedIndex: getSelectedIndex(),
            onDestinationSelected: onItemTapped,
            destinations: destinations,
          ),
        ),
      ),
    );
  }
}
