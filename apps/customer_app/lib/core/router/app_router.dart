import 'package:customer_app/core/navigation/main_navigation.dart';
import 'package:customer_app/features/addresses/presentation/pages/address_form_page.dart';
import 'package:customer_app/features/addresses/presentation/pages/saved_addresses_page.dart';
import 'package:customer_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:customer_app/features/auth/presentation/pages/login_page.dart';
import 'package:customer_app/features/auth/presentation/pages/register_page.dart';
import 'package:customer_app/features/cart/presentation/pages/cart_page.dart';
import 'package:customer_app/features/checkout/presentation/pages/checkout_page.dart';
import 'package:customer_app/features/favorites/presentation/pages/favorites_page.dart';
import 'package:customer_app/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:customer_app/features/orders/presentation/pages/order_details_page.dart';
import 'package:customer_app/features/orders/presentation/pages/orders_page.dart';
import 'package:customer_app/features/payment_methods/presentation/pages/payment_methods_page.dart';
import 'package:customer_app/features/products/presentation/pages/product_details_page.dart';
import 'package:customer_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:customer_app/features/profile/presentation/pages/profile_page.dart';
import 'package:customer_app/features/search/presentation/pages/search_page.dart';
import 'package:customer_app/features/splash/presentation/pages/splash_page.dart';
import 'package:customer_app/features/support/presentation/pages/help_support_page.dart';
import 'package:customer_app/features/vendors/presentation/pages/vendor_details_page.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Routes
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const vendorDetails = '/vendor/:id';
  static const productDetails = '/product/:id';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const orders = '/orders';
  static const orderDetails = '/order/:id';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const favorites = '/favorites';
  static const addresses = '/addresses';
  static const addAddress = '/addresses/add';
  static const editAddress = '/addresses/edit';
  static const paymentMethods = '/payment-methods';
  static const notificationSettings = '/notification-settings';
  static const helpSupport = '/help-support';
  static const search = '/search';
}

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  // Watch authentication state
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isLogin = state.matchedLocation == AppRoutes.login;
      final isRegister = state.matchedLocation == AppRoutes.register;
      final isForgotPassword = state.matchedLocation == AppRoutes.forgotPassword;

      // If still loading auth state on first load, stay on splash
      if (authState.isLoading && authState.hasValue == false) {
        return isSplash ? null : AppRoutes.splash;
      }

      // If not authenticated, redirect to login (except for register and forgot password)
      if (!isAuthenticated && !isLogin && !isRegister && !isForgotPassword) {
        return AppRoutes.login;
      }

      // If authenticated and on auth pages or splash, redirect to home
      if (isAuthenticated && (isLogin || isRegister || isSplash || isForgotPassword)) {
        return AppRoutes.home;
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
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const MainNavigation(),
      ),
      GoRoute(
        path: AppRoutes.vendorDetails,
        builder: (context, state) {
          final vendorId = state.pathParameters['id']!;
          return VendorDetailsPage(vendorId: vendorId);
        },
      ),
      GoRoute(
        path: AppRoutes.productDetails,
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          return ProductDetailsPage(productId: productId);
        },
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const CartPage(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) => const CheckoutPage(),
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
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        builder: (context, state) => const FavoritesPage(),
      ),
      GoRoute(
        path: AppRoutes.addresses,
        builder: (context, state) => const SavedAddressesPage(),
      ),
      GoRoute(
        path: AppRoutes.addAddress,
        builder: (context, state) {
          final userId = state.extra as String;
          return AddressFormPage(userId: userId);
        },
      ),
      GoRoute(
        path: AppRoutes.editAddress,
        builder: (context, state) {
          final address = state.extra as AddressModel;
          return AddressFormPage(
            userId: address.userId,
            address: address,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.paymentMethods,
        builder: (context, state) => const PaymentMethodsPage(),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.helpSupport,
        builder: (context, state) => const HelpSupportPage(),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchPage(),
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          body: Center(child: Text('Page not found: ${state.matchedLocation}')),
        ),
  );
}
