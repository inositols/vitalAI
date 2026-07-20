import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../plugin/module_registry.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/patients/presentation/pages/patients_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/vitals/presentation/pages/history_page.dart';
import '../../features/vitals/presentation/pages/add_vital_page.dart';
import '../../features/vitals/presentation/pages/charts_page.dart';
import '../../features/ai_assistant/presentation/pages/ai_chat_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/caregiver/presentation/pages/caregiver_page.dart';

// Global keys for navigation context
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

/// Configuration class for the app's GoRouter instance.
/// Automatically mounts paths for core features and dynamically attaches module routes.
class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildPageTransition(
          state: state,
          child: const LoginPage(),
          slideUp: false,
        ),
      ),
      GoRoute(
        path: '/patients',
        pageBuilder: (context, state) => _buildPageTransition(
          state: state,
          child: const PatientsPage(),
          slideUp: false,
        ),
      ),
      GoRoute(
        path: '/vitals/add',
        pageBuilder: (context, state) => _buildPageTransition(
          state: state,
          child: const AddVitalPage(),
          slideUp: true,
        ),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => _ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _buildPageTransition(
              state: state,
              child: const DashboardPage(),
              slideUp: true,
            ),
          ),
          GoRoute(
            path: '/history',
            pageBuilder: (context, state) => _buildPageTransition(
              state: state,
              child: const HistoryPage(),
              slideUp: true,
            ),
          ),
          GoRoute(
            path: '/charts',
            pageBuilder: (context, state) => _buildPageTransition(
              state: state,
              child: const ChartsPage(),
              slideUp: true,
            ),
          ),
          GoRoute(
            path: '/ai-chat',
            pageBuilder: (context, state) => _buildPageTransition(
              state: state,
              child: const AiChatPage(),
              slideUp: true,
            ),
          ),
          GoRoute(
            path: '/caregiver',
            pageBuilder: (context, state) => _buildPageTransition(
              state: state,
              child: const CaregiverPage(),
              slideUp: true,
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => _buildPageTransition(
              state: state,
              child: const SettingsPage(),
              slideUp: true,
            ),
          ),
          // Dynamically mount routes registered by other plugin modules
          ...ModuleRegistry.instance.allRoutes,
        ],
      ),
    ],
  );

  static GoRouter buildRouter(BuildContext context) => router;

  static Page<dynamic> _buildPageTransition({
    required GoRouterState state,
    required Widget child,
    required bool slideUp,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (slideUp) {
          // Premium slide up & fade
          final slideTween = Tween<Offset>(
            begin: const Offset(0.0, 0.06),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));

          return SlideTransition(
            position: animation.drive(slideTween),
            child: FadeTransition(
              opacity: CurveTween(curve: Curves.easeIn).animate(animation),
              child: child,
            ),
          );
        } else {
          // Premium subtle scale-fade for main context switches
          final scaleTween = Tween<double>(
            begin: 0.96,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeOutCubic));

          return ScaleTransition(
            scale: animation.drive(scaleTween),
            child: FadeTransition(
              opacity: CurveTween(curve: Curves.easeIn).animate(animation),
              child: child,
            ),
          );
        }
      },
    );
  }
}

/// Simple shell layout incorporating navigation bar with large touch targets.
class _ShellScaffold extends StatelessWidget {
  final Widget child;
  const _ShellScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    final GoRouterState state = GoRouterState.of(context);
    final String currentLoc = state.uri.path;

    // Map navigation destinations
    final destinations = [
      const NavigationDestination(
        icon: Icon(CupertinoIcons.square_grid_2x2, size: 26),
        selectedIcon: Icon(CupertinoIcons.square_grid_2x2_fill, size: 26),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(CupertinoIcons.clock, size: 26),
        selectedIcon: Icon(CupertinoIcons.clock_fill, size: 26),
        label: 'History',
      ),
      const NavigationDestination(
        icon: Icon(CupertinoIcons.waveform_path_ecg, size: 26),
        selectedIcon: Icon(CupertinoIcons.waveform_path_ecg, size: 26),
        label: 'Charts',
      ),
      const NavigationDestination(
        icon: Icon(CupertinoIcons.sparkles, size: 26),
        selectedIcon: Icon(CupertinoIcons.sparkles, size: 26),
        label: 'AI Chat',
      ),
      const NavigationDestination(
        icon: Icon(CupertinoIcons.gear_alt, size: 26),
        selectedIcon: Icon(CupertinoIcons.gear_alt_fill, size: 26),
        label: 'Settings',
      ),
    ];

    int getSelectedIndex() {
      if (currentLoc == '/') return 0;
      if (currentLoc.startsWith('/history')) return 1;
      if (currentLoc.startsWith('/charts')) return 2;
      if (currentLoc.startsWith('/ai-chat')) return 3;
      if (currentLoc.startsWith('/settings')) return 4;
      return 0;
    }

    void onItemTapped(int index) {
      switch (index) {
        case 0:
          context.go('/');
          break;
        case 1:
          context.go('/history');
          break;
        case 2:
          context.go('/charts');
          break;
        case 3:
          context.go('/ai-chat');
          break;
        case 4:
          context.go('/settings');
          break;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (currentLoc == '/') {
          context.go('/patients');
        } else {
          context.go('/');
        }
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: getSelectedIndex(),
          onDestinationSelected: onItemTapped,
          destinations: destinations,
        ),
      ),
    );
  }
}

/// Placeholder page to be replaced during feature development
class _DummyPage extends StatelessWidget {
  final String title;
  const _DummyPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title Content',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
