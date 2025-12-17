import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';
import 'package:driver_app/core/router/app_router.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  // Profile header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: Text(
                              currentUser.displayName?.isNotEmpty == true
                                  ? currentUser.displayName![0].toUpperCase()
                                  : 'D',
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            currentUser.displayName ?? 'Driver',
                            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            currentUser.email,
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                          ),
                          if (currentUser.phoneNumber != null && currentUser.phoneNumber!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              currentUser.phoneNumber!,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Stats with real data
                  _PerformanceStats(driverId: currentUser.id),
                  const SizedBox(height: AppSpacing.md),

                  // Vehicle Info - from driver profile
                  _VehicleInfoCard(userId: currentUser.id),
                  const SizedBox(height: AppSpacing.md),

                  // Settings
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.star_outlined),
                          title: const Text('My Reviews'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(AppRoutes.reviews),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.notifications_outlined),
                          title: const Text('Notifications'),
                          trailing: Switch(
                            value: true,
                            onChanged: (value) {},
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.edit_outlined),
                          title: const Text('Edit Profile'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(AppRoutes.editProfile),
                        ),
                        const Divider(height: 1),
                        _ThemeSwitcherTile(),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: const Text('Help & Support'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Help & support coming soon')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Logout
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: AppColors.error),
                      title: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Sign Out'),
                            content: const Text('Are you sure you want to sign out?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Sign Out'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await ref.read(authRepositoryProvider).signOut();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PerformanceStats extends ConsumerWidget {
  const _PerformanceStats({required this.driverId});
  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(streamOrdersByDriverIdProvider(driverId));

    return ordersAsync.when(
      data: (orders) {
        final completedOrders = orders.where((o) => o.status == 'delivered').toList();
        final totalEarnings = completedOrders.fold(0.0, (sum, order) => sum + (order.deliveryFee * 0.85));

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance',
                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Deliveries',
                        value: '${completedOrders.length}',
                        icon: Icons.local_shipping,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Rating',
                        value: '5.0',
                        icon: Icons.star,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Earnings',
                        value: '\$${totalEarnings.toStringAsFixed(0)}',
                        icon: Icons.attach_money,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(child: _StatItem(label: 'Deliveries', value: '-', icon: Icons.local_shipping)),
              Expanded(child: _StatItem(label: 'Rating', value: '-', icon: Icons.star)),
              Expanded(child: _StatItem(label: 'Earnings', value: '-', icon: Icons.attach_money)),
            ],
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _VehicleInfoCard extends ConsumerWidget {
  const _VehicleInfoCard({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverProfileAsync = ref.watch(streamDriverProfileByUserIdProvider(userId));

    return driverProfileAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Vehicle Information',
                      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (!profile.isApproved)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                        ),
                        child: Text(
                          'Pending Approval',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _InfoRow(
                  icon: _getVehicleIcon(profile.vehicleType),
                  label: 'Type',
                  value: profile.vehicleType.toUpperCase(),
                ),
                if (profile.vehiclePlateNumber != null)
                  _InfoRow(
                    icon: Icons.confirmation_number,
                    label: 'Plate',
                    value: profile.vehiclePlateNumber!,
                  ),
                if (profile.licenseNumber != null)
                  _InfoRow(
                    icon: Icons.badge,
                    label: 'License',
                    value: profile.licenseNumber!,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'bicycle':
        return Icons.pedal_bike;
      case 'car':
        return Icons.directions_car;
      default:
        return Icons.local_shipping;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _ThemeSwitcherTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider);

    return ListTile(
      leading: Icon(themeMode.icon),
      title: const Text('Theme'),
      subtitle: Text(themeMode.displayName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => SafeArea(
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
                ...AppThemeMode.values.map((mode) => ListTile(
                  leading: Icon(mode.icon),
                  title: Text(mode.displayName),
                  trailing: themeMode == mode
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    ref.read(themeModeNotifierProvider.notifier).setThemeMode(mode);
                    Navigator.pop(context);
                  },
                )),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }
}
