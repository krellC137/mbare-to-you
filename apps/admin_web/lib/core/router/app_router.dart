import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:admin_web/features/auth/presentation/pages/login_page.dart';
import 'package:admin_web/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:admin_web/features/users/presentation/pages/users_page.dart';
import 'package:admin_web/features/orders/presentation/pages/orders_page.dart';
import 'package:admin_web/features/analytics/presentation/pages/analytics_page.dart';
import 'package:admin_web/features/settings/presentation/pages/settings_page.dart';
import 'package:admin_web/features/approvals/presentation/pages/approvals_page.dart';
import 'package:admin_web/shared/widgets/admin_shell.dart';

part 'app_router.g.dart';

/// Routes
class AppRoutes {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const users = '/users';
  static const orders = '/orders';
  static const approvals = '/approvals';
  static const analytics = '/analytics';
  static const settings = '/settings';
}

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isLogin = state.matchedLocation == AppRoutes.login;

      if (!isAuthenticated && !isLogin) {
        return AppRoutes.login;
      }

      if (isAuthenticated && isLogin) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.users,
            builder: (context, state) => const UsersPage(),
          ),
          GoRoute(
            path: AppRoutes.orders,
            builder: (context, state) => const OrdersPage(),
          ),
          GoRoute(
            path: AppRoutes.approvals,
            builder: (context, state) => const ApprovalsPage(),
          ),
          GoRoute(
            path: AppRoutes.analytics,
            builder: (context, state) => const AnalyticsPage(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.matchedLocation}')),
    ),
  );
}
