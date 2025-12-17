import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';

/// User profile page
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the Firebase Auth user for ID
    final authUser = ref.watch(authStateChangesProvider).value;

    if (authUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Please log in to view your profile')),
      );
    }

    // Stream the full UserModel from Firestore for real-time updates
    final userModelAsync = ref.watch(streamUserByIdProvider(authUser.uid));

    return userModelAsync.when(
      data: (userModel) {
        if (userModel == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const Center(child: Text('User profile not found')),
          );
        }

        return _buildProfileScaffold(context, ref, userModel);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: SmallLoadingIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Text(
            'Error loading profile: $error',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.error,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileScaffold(
    BuildContext context,
    WidgetRef ref,
    UserModel userModel,
  ) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // User info card
          _UserInfoCard(user: userModel),

          const SizedBox(height: AppSpacing.xl),

          // Edit profile
          _MenuItem(
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            onTap: () => context.push('/profile/edit'),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Menu items
          _MenuItem(
            icon: Icons.receipt_long_outlined,
            title: 'My Orders',
            subtitle: 'View your order history',
            onTap: () => context.push('/orders'),
          ),

          const SizedBox(height: AppSpacing.sm),

          _MenuItem(
            icon: Icons.shopping_cart_outlined,
            title: 'Shopping Cart',
            subtitle: 'View items in your cart',
            onTap: () => context.push('/cart'),
          ),

          const SizedBox(height: AppSpacing.sm),

          _MenuItem(
            icon: Icons.location_on_outlined,
            title: 'Saved Addresses',
            subtitle: 'Manage delivery addresses',
            onTap: () => context.push('/addresses'),
          ),

          const SizedBox(height: AppSpacing.sm),

          _MenuItem(
            icon: Icons.payment_outlined,
            title: 'Payment Methods',
            subtitle: 'Manage payment options',
            onTap: () => context.push('/payment-methods'),
          ),

          const SizedBox(height: AppSpacing.sm),

          _MenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () => context.push('/notification-settings'),
          ),

          const SizedBox(height: AppSpacing.sm),

          _ThemeSwitcherMenuItem(ref: ref),

          const SizedBox(height: AppSpacing.sm),

          _MenuItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help with your orders',
            onTap: () => context.push('/help-support'),
          ),

          const SizedBox(height: AppSpacing.sm),

          _MenuItem(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Learn more about MbareToYou',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'MbareToYou',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.shopping_bag,
                  size: 48,
                  color: AppColors.primary,
                ),
                children: [
                  const Text(
                    'Your trusted marketplace for fresh produce and quality goods from Mbare Market.',
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ),

          // Extra bottom padding to prevent content being hidden by bottom nav bar
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }
}

/// User info card widget
class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.info],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(Icons.person, size: 40, color: AppColors.primary),
          ),

          const SizedBox(height: AppSpacing.md),

          // Name
          Text(
            user.displayName ?? 'User',
            style: AppTextStyles.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Email
          Text(
            user.email,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

/// Menu item widget
class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSwitcherMenuItem extends StatelessWidget {
  const _ThemeSwitcherMenuItem({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeNotifierProvider);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            builder:
                (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          'Choose Theme',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...AppThemeMode.values.map(
                        (mode) => ListTile(
                          leading: Icon(mode.icon),
                          title: Text(mode.displayName),
                          trailing:
                              themeMode == mode
                                  ? const Icon(
                                    Icons.check,
                                    color: AppColors.primary,
                                  )
                                  : null,
                          onTap: () {
                            ref
                                .read(themeModeNotifierProvider.notifier)
                                .setThemeMode(mode);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(themeMode.icon, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Theme', style: AppTextStyles.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      themeMode.displayName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
