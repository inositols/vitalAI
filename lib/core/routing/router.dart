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

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
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
      path: '/add-vital',
      builder: (context, state) => const AddVitalPage(),
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

    final destinations = const [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.auto_awesome_outlined),
        selectedIcon: Icon(Icons.auto_awesome),
        label: 'AI Companion',
      ),
      NavigationDestination(
        icon: Icon(Icons.insert_chart_outlined),
        selectedIcon: Icon(Icons.insert_chart),
        label: 'Charts',
      ),
      NavigationDestination(
        icon: Icon(Icons.history_outlined),
        selectedIcon: Icon(Icons.history),
        label: 'History',
      ),
      NavigationDestination(
        icon: Icon(Icons.share_outlined),
        selectedIcon: Icon(Icons.share),
        label: 'Caregiver',
      ),
      NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
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
          return 2;
        case '/history':
          return 3;
        case '/caregiver':
          return 4;
        case '/settings':
          return 5;
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
          context.go('/history');
          break;
        case 4:
          context.go('/caregiver');
          break;
        case 5:
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
        bottomNavigationBar: NavigationBar(
          selectedIndex: getSelectedIndex(),
          onDestinationSelected: onItemTapped,
          destinations: destinations,
        ),
      ),
    );
  }
}
