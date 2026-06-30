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
  static GoRouter buildRouter(BuildContext context) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/patients',
          builder: (context, state) => const PatientsPage(),
        ),
        GoRoute(
          path: '/vitals/add',
          builder: (context, state) => const AddVitalPage(),
        ),
        ShellRoute(
          navigatorKey: shellNavigatorKey,
          builder: (context, state, child) => _ShellScaffold(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardPage(),
            ),
            GoRoute(
              path: '/history',
              builder: (context, state) => const HistoryPage(),
            ),
            GoRoute(
              path: '/charts',
              builder: (context, state) => const ChartsPage(),
            ),
            GoRoute(
              path: '/ai-chat',
              builder: (context, state) => const AiChatPage(),
            ),
            GoRoute(
              path: '/caregiver',
              builder: (context, state) => const CaregiverPage(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
            // Dynamically mount routes registered by other plugin modules
            ...ModuleRegistry.instance.allRoutes,
          ],
        ),
      ],
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
        icon: Icon(Icons.dashboard_outlined, size: 28),
        selectedIcon: Icon(Icons.dashboard, size: 28),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.history_outlined, size: 28),
        selectedIcon: Icon(Icons.history, size: 28),
        label: 'History',
      ),
      const NavigationDestination(
        icon: Icon(Icons.bar_chart_outlined, size: 28),
        selectedIcon: Icon(Icons.bar_chart, size: 28),
        label: 'Charts',
      ),
      const NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline, size: 28),
        selectedIcon: Icon(Icons.chat_bubble, size: 28),
        label: 'AI Chat',
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined, size: 28),
        selectedIcon: Icon(Icons.settings, size: 28),
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

    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: getSelectedIndex(),
        onDestinationSelected: onItemTapped,
        destinations: destinations,
        height: 80, // Large height for senior-friendly visual target
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
