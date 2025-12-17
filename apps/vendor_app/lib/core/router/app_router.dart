import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vendor_app/features/analytics/presentation/pages/analytics_page.dart';
import 'package:vendor_app/features/auth/presentation/pages/login_page.dart';
import 'package:vendor_app/features/auth/presentation/pages/register_page.dart';
import 'package:vendor_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:vendor_app/features/orders/presentation/pages/orders_page.dart';
import 'package:vendor_app/features/orders/presentation/pages/order_details_page.dart';
import 'package:vendor_app/features/products/presentation/pages/products_page.dart';
import 'package:vendor_app/features/products/presentation/pages/product_form_page.dart';
import 'package:vendor_app/features/profile/presentation/pages/profile_page.dart';
import 'package:vendor_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:vendor_app/features/profile/presentation/pages/business_hours_page.dart';
import 'package:vendor_app/features/splash/presentation/pages/splash_page.dart';

part 'app_router.g.dart';

/// Routes
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const orders = '/orders';
  static const orderDetails = '/order/:id';
  static const products = '/products';
  static const addProduct = '/products/add';
  static const editProduct = '/products/edit/:id';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const businessHours = '/profile/business-hours';
  static const analytics = '/analytics';
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

      // If still loading auth state, stay on splash
      if (authState.isLoading && authState.hasValue == false) {
        return isSplash ? null : AppRoutes.splash;
      }

      // If not authenticated, redirect to login (except register page)
      if (!isAuthenticated && !isLogin && !isRegister) {
        return AppRoutes.login;
      }

      // If authenticated and on auth pages or splash, redirect to dashboard
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
        path: AppRoutes.orders,
        builder: (context, state) => const OrdersPage(),
      ),
      GoRoute(
        path: AppRoutes.orderDetails,
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return OrderDetailsPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: AppRoutes.products,
        builder: (context, state) => const ProductsPage(),
      ),
      GoRoute(
        path: AppRoutes.addProduct,
        builder: (context, state) => const ProductFormPage(),
      ),
      GoRoute(
        path: AppRoutes.editProduct,
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          return ProductFormPage(productId: productId);
        },
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
        path: AppRoutes.businessHours,
        builder: (context, state) => const BusinessHoursPage(),
      ),
      GoRoute(
        path: AppRoutes.analytics,
        builder: (context, state) => const AnalyticsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.matchedLocation}')),
    ),
  );
}
