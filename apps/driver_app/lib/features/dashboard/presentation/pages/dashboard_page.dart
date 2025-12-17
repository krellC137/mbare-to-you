import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';
import 'package:driver_app/core/router/app_router.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final Set<String> _knownOrderIds = {};

  void _checkForNewOrders(List<OrderModel> orders) {
    for (final order in orders) {
      if (!_knownOrderIds.contains(order.id)) {
        if (_knownOrderIds.isNotEmpty && order.status == 'ready') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('New delivery available! #${order.id.substring(0, 8)}'),
                  backgroundColor: AppColors.success,
                  action: SnackBarAction(
                    label: 'View',
                    textColor: Colors.white,
                    onPressed: () => context.push(AppRoutes.deliveries),
                  ),
                ),
              );
            }
          });
        }
        _knownOrderIds.add(order.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;

    // Listen for available orders
    ref.listen(streamOrdersByStatusProvider('ready'), (previous, next) {
      next.whenData((orders) => _checkForNewOrders(orders));
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : _DriverDashboardContent(user: currentUser),
    );
  }
}

class _DriverDashboardContent extends ConsumerWidget {
  const _DriverDashboardContent({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverProfileAsync = ref.watch(streamDriverProfileByUserIdProvider(user.id));

    return driverProfileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (driverProfile) {
        // Check if driver profile exists and is approved
        if (driverProfile == null) {
          return _PendingApprovalView(
            title: 'Profile Not Found',
            message: 'Your driver profile could not be found. Please contact support.',
            icon: Icons.error_outline,
            color: AppColors.error,
          );
        }

        if (!driverProfile.isApproved) {
          return _PendingApprovalView(
            title: 'Pending Approval',
            message: 'Your driver registration is under review. You will be notified once an admin approves your account.',
            icon: Icons.hourglass_empty,
            color: AppColors.warning,
          );
        }

        // Driver is approved - show full dashboard
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(streamOrdersByDriverIdProvider(user.id));
            ref.invalidate(streamOrdersByStatusProvider('ready'));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome and availability
                _WelcomeSection(user: user, driverProfile: driverProfile),
                const SizedBox(height: AppSpacing.lg),

                    // Stats cards (2x2 grid like vendor)
                _DashboardStats(driverId: user.id),
                const SizedBox(height: AppSpacing.xl),

                // Quick actions
                Text(
                  'Quick Actions',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Deliveries',
                        icon: Icons.list_alt,
                        onTap: () => context.push(AppRoutes.deliveries),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _ActionButton(
                        label: 'Earnings',
                        icon: Icons.account_balance_wallet,
                        onTap: () => context.push(AppRoutes.earnings),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _ActionButton(
                        label: 'Profile',
                        icon: Icons.person,
                        onTap: () => context.push(AppRoutes.profile),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Available deliveries
                _AvailableDeliveriesSection(),
                const SizedBox(height: AppSpacing.xl),

                // Recent deliveries
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.deliveries),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _RecentDeliveries(driverId: user.id),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PendingApprovalView extends StatelessWidget {
  const _PendingApprovalView({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: color),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: () {
                // Refresh to check status
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Check Status'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeSection extends ConsumerStatefulWidget {
  const _WelcomeSection({required this.user, required this.driverProfile});
  final UserModel user;
  final DriverProfileModel driverProfile;

  @override
  ConsumerState<_WelcomeSection> createState() => _WelcomeSectionState();
}

class _WelcomeSectionState extends ConsumerState<_WelcomeSection> {
  bool _isAvailable = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                widget.user.displayName?.isNotEmpty == true
                    ? widget.user.displayName![0].toUpperCase()
                    : 'D',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  Text(
                    widget.user.displayName ?? 'Driver',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _isAvailable ? 'Online' : 'Offline',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _isAvailable ? AppColors.success : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _isAvailable,
                  onChanged: (value) {
                    setState(() => _isAvailable = value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value ? 'You are now online' : 'You are now offline'),
                        backgroundColor: value ? AppColors.success : AppColors.textSecondary,
                      ),
                    );
                  },
                  activeColor: AppColors.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardStats extends ConsumerWidget {
  const _DashboardStats({required this.driverId});
  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(streamOrdersByDriverIdProvider(driverId));
    final availableAsync = ref.watch(streamOrdersByStatusProvider('ready'));

    return ordersAsync.when(
      data: (orders) {
        final today = DateTime.now();
        final todayOrders = orders.where((o) {
          if (o.createdAt == null) return false;
          return o.createdAt!.year == today.year &&
              o.createdAt!.month == today.month &&
              o.createdAt!.day == today.day;
        }).toList();

        final activeOrders = orders.where((o) => o.status == 'out_for_delivery').length;
        final completedOrders = orders.where((o) => o.status == 'delivered').toList();
        final todayEarnings = todayOrders
            .where((o) => o.status == 'delivered')
            .fold(0.0, (sum, o) => sum + (o.deliveryFee * 0.85));

        final availableCount = availableAsync.when(
          data: (available) => available.length,
          loading: () => 0,
          error: (_, __) => 0,
        );

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Today\'s Earnings',
                    value: '\$${todayEarnings.toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatCard(
                    title: 'Available',
                    value: '$availableCount',
                    icon: Icons.local_shipping_outlined,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Active',
                    value: '$activeOrders',
                    icon: Icons.pending_actions,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatCard(
                    title: 'Completed',
                    value: '${completedOrders.length}',
                    icon: Icons.check_circle_outline,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _AvailableDeliveriesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableAsync = ref.watch(streamOrdersByStatusProvider('ready'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Deliveries',
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            availableAsync.when(
              data: (orders) => orders.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      ),
                      child: Text(
                        '${orders.length} new',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        availableAsync.when(
          data: (orders) {
            if (orders.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined, size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'No deliveries available',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Check back later for new orders',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: orders.take(2).map((order) => _AvailableDeliveryCard(order: order)).toList(),
            );
          },
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text('Error: $error'),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvailableDeliveryCard extends ConsumerWidget {
  const _AvailableDeliveryCard({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => context.push(AppRoutes.deliveryDetails.replaceFirst(':id', order.id)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${(order.deliveryFee * 0.85).toStringAsFixed(2)}',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      order.deliveryAddress.formattedAddress,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final user = ref.read(currentUserProvider).value;
                    if (user == null) return;

                    final orderRepo = ref.read(orderRepositoryProvider);
                    await orderRepo.assignDriver(order.id, user.id);
                    await orderRepo.updateOrderStatus(order.id, 'out_for_delivery');

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Delivery accepted!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  child: const Text('Accept Delivery'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentDeliveries extends ConsumerWidget {
  const _RecentDeliveries({required this.driverId});
  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(streamOrdersByDriverIdProvider(driverId));

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No delivery history',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final recentOrders = orders.take(5).toList();

        return Column(
          children: recentOrders.map((order) {
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(order.status).withValues(alpha: 0.1),
                  child: Icon(
                    _getStatusIcon(order.status),
                    color: _getStatusColor(order.status),
                    size: 20,
                  ),
                ),
                title: Text('Order #${order.id.substring(0, 8)}'),
                subtitle: Text(
                  '${order.items.length} items • \$${(order.deliveryFee * 0.85).toStringAsFixed(2)}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      order.statusDisplay,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (order.createdAt != null)
                      Text(
                        _formatTime(order.createdAt!),
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                  ],
                ),
                onTap: () => context.push(AppRoutes.deliveryDetails.replaceFirst(':id', order.id)),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'out_for_delivery':
        return AppColors.warning;
      case 'delivered':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'out_for_delivery':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.labelSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
