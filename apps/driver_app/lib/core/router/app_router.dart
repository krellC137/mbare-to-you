import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:driver_app/features/auth/presentation/pages/login_page.dart';
import 'package:driver_app/features/auth/presentation/pages/register_page.dart';
import 'package:driver_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:driver_app/features/deliveries/presentation/pages/deliveries_page.dart';
import 'package:driver_app/features/deliveries/presentation/pages/delivery_details_page.dart';
import 'package:driver_app/features/profile/presentation/pages/profile_page.dart';
import 'package:driver_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:driver_app/features/splash/presentation/pages/splash_page.dart';
import 'package:driver_app/features/earnings/presentation/pages/earnings_page.dart';
import 'package:driver_app/features/reviews/presentation/pages/reviews_page.dart';

part 'app_router.g.dart';

/// Routes
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const deliveries = '/deliveries';
  static const deliveryDetails = '/delivery/:id';
  static const earnings = '/earnings';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const reviews = '/reviews';
}

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isLogin = state.matchedLocation == AppRoutes.login;
      final isRegister = state.matchedLocation == AppRoutes.register;

      if (authState.isLoading && authState.hasValue == false) {
        return isSplash ? null : AppRoutes.splash;
      }

      if (!isAuthenticated && !isLogin && !isRegister) {
        return AppRoutes.login;
      }

      if (isAuthenticated && (isLogin || isSplash || isRegister)) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.deliveries,
        builder: (context, state) => const DeliveriesPage(),
      ),
      GoRoute(
        path: AppRoutes.deliveryDetails,
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return DeliveryDetailsPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: AppRoutes.earnings,
        builder: (context, state) => const EarningsPage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.reviews,
        builder: (context, state) => const ReviewsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.matchedLocation}')),
    ),
  );
}
