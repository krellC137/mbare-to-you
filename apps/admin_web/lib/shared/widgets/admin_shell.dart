import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';
import 'package:admin_web/core/router/app_router.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: AppColors.primary,
            child: Column(
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'MbareToYou',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Nav items
                _NavItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  route: AppRoutes.dashboard,
                  isSelected: currentRoute == AppRoutes.dashboard,
                ),
                _NavItem(
                  icon: Icons.people,
                  label: 'Users',
                  route: AppRoutes.users,
                  isSelected: currentRoute == AppRoutes.users,
                ),
                _NavItem(
                  icon: Icons.shopping_bag,
                  label: 'Orders',
                  route: AppRoutes.orders,
                  isSelected: currentRoute == AppRoutes.orders,
                ),
                _NavItem(
                  icon: Icons.approval,
                  label: 'Approvals',
                  route: AppRoutes.approvals,
                  isSelected: currentRoute == AppRoutes.approvals,
                ),
                _NavItem(
                  icon: Icons.analytics,
                  label: 'Analytics',
                  route: AppRoutes.analytics,
                  isSelected: currentRoute == AppRoutes.analytics,
                ),
                _NavItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  route: AppRoutes.settings,
                  isSelected: currentRoute == AppRoutes.settings,
                ),
                const Spacer(),
                // Logout
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white70),
                  title: const Text('Logout', style: TextStyle(color: Colors.white70)),
                  onTap: () async {
                    await ref.read(authRepositoryProvider).signOut();
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isSelected,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        onTap: () => context.go(route),
      ),
    );
  }
}
