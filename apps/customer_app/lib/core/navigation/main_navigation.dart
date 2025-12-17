import 'package:customer_app/features/cart/presentation/pages/cart_page.dart';
import 'package:customer_app/features/cart/providers/cart_provider.dart';
import 'package:customer_app/features/discover/presentation/pages/discover_page.dart';
import 'package:customer_app/features/home/presentation/pages/home_page.dart';
import 'package:customer_app/features/profile/presentation/pages/profile_page.dart';
import 'package:customer_app/features/vendors/presentation/pages/vendors_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbare_ui/mbare_ui.dart';

/// State notifier to manage the current navigation tab index
class NavigationIndexNotifier extends StateNotifier<int> {
  NavigationIndexNotifier() : super(0); // Default to Home tab

  void setIndex(int index) => state = index;
  void goToHome() => state = 0;
  void goToDiscover() => state = 1;
  void goToVendors() => state = 2;
  void goToCart() => state = 3;
  void goToProfile() => state = 4;
}

/// Provider to manage the current navigation tab index
final navigationIndexProvider = StateNotifierProvider<NavigationIndexNotifier, int>(
  (ref) => NavigationIndexNotifier(),
);

/// Main navigation scaffold with bottom navigation bar
class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  final List<Widget> _pages = const [
    HomePage(),
    DiscoverPage(),
    VendorsPage(),
    CartPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    // Watch navigation index from provider
    final currentIndex = ref.watch(navigationIndexProvider);

    // Watch cart item count for badge
    final cartItemCount = ref.watch(
      cartProvider.select((state) => state.itemCount),
    );

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _pages,
      ),
      extendBody: true, // Extend body behind the nav bar for floating effect
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).setIndex(index);
        },
        cartItemCount: cartItemCount,
      ),
    );
  }
}

/// Floating pill-style navigation bar
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.cartItemCount,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartItemCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavBarItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavBarItem(
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore,
            label: 'Discover',
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavBarItem(
            icon: Icons.store_outlined,
            activeIcon: Icons.store,
            label: 'Vendors',
            isActive: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavBarItem(
            icon: Icons.shopping_cart_outlined,
            activeIcon: Icons.shopping_cart,
            label: 'Cart',
            isActive: currentIndex == 3,
            onTap: () => onTap(3),
            badgeCount: cartItemCount,
          ),
          _NavBarItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
            isActive: currentIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

/// Individual navigation bar item with smooth animations
class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.all(isActive ? AppSpacing.xs : 0),
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isDark ? AppColors.primaryLight : AppColors.primary).withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        isActive ? activeIcon : icon,
                        color: isActive
                            ? (isDark ? AppColors.primaryLight : AppColors.primary)
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                        size: 24,
                      ),
                      if (badgeCount != null && badgeCount! > 0)
                        Positioned(
                          right: -8,
                          top: -8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              badgeCount! > 99 ? '99+' : '$badgeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Label
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isActive
                        ? (isDark ? AppColors.primaryLight : AppColors.primary)
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textSecondary),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 11,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
