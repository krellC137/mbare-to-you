import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';
import 'package:vendor_app/core/router/app_router.dart';
import 'package:vendor_app/core/services/notification_service.dart';

/// Main dashboard for vendors
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final Set<String> _knownOrderIds = {};
  bool _notificationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.initialize();
    setState(() => _notificationsInitialized = true);
  }

  void _checkForNewOrders(List<dynamic> orders, String vendorId) {
    if (!_notificationsInitialized) return;

    for (final order in orders) {
      if (!_knownOrderIds.contains(order.id)) {
        if (_knownOrderIds.isNotEmpty && order.status == 'pending') {
          // Show snackbar for new order
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('New order received! #${order.id.substring(0, 8)}'),
                  backgroundColor: AppColors.success,
                  action: SnackBarAction(
                    label: 'View',
                    textColor: Colors.white,
                    onPressed: () {
                      context.push(AppRoutes.orderDetails.replaceFirst(':id', order.id));
                    },
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
    final currentUser = ref.watch(authStateChangesProvider).value;
    final vendorId = currentUser?.uid ?? '';

    // Listen for orders to detect new ones
    if (vendorId.isNotEmpty) {
      ref.listen(streamOrdersByVendorIdProvider(vendorId), (previous, next) {
        next.whenData((orders) => _checkForNewOrders(orders, vendorId));
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: vendorId.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _VendorDashboardContent(vendorId: vendorId, userName: currentUser?.displayName),
    );
  }
}

class _VendorDashboardContent extends ConsumerWidget {
  const _VendorDashboardContent({required this.vendorId, this.userName});
  final String vendorId;
  final String? userName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorAsync = ref.watch(streamVendorByIdProvider(vendorId));

    return vendorAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (vendor) {
        // Check if vendor profile exists and is approved
        if (vendor == null) {
          return _PendingApprovalView(
            title: 'Profile Not Found',
            message: 'Your vendor profile could not be found. Please contact support.',
            icon: Icons.error_outline,
            color: AppColors.error,
          );
        }

        if (!vendor.isApproved) {
          return _PendingApprovalView(
            title: 'Pending Approval',
            message: 'Your vendor registration is under review. You will be notified once an admin approves your account.',
            icon: Icons.hourglass_empty,
            color: AppColors.warning,
          );
        }

        // Vendor is approved - show full dashboard
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Text(
                'Welcome back${userName != null ? ', $userName' : ''}!',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Stats cards
              _DashboardStats(vendorId: vendorId),
              const SizedBox(height: AppSpacing.xl),

              // Quick actions
              Text(
                'Quick Actions',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Orders',
                      icon: Icons.list_alt,
                      onTap: () => context.push(AppRoutes.orders),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ActionButton(
                      label: 'Products',
                      icon: Icons.inventory,
                      onTap: () => context.push(AppRoutes.products),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ActionButton(
                      label: 'Analytics',
                      icon: Icons.analytics,
                      onTap: () => context.push(AppRoutes.analytics),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Recent orders
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Orders',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.orders),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              _RecentOrders(vendorId: vendorId),
            ],
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

class _DashboardStats extends ConsumerWidget {
  const _DashboardStats({required this.vendorId});

  final String vendorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(streamOrdersByVendorIdProvider(vendorId));
    final productsAsync = ref.watch(streamProductsByVendorIdProvider(vendorId));

    return ordersAsync.when(
      data: (orders) {
        final today = DateTime.now();
        final todayOrders = orders.where((o) {
          if (o.createdAt == null) return false;
          return o.createdAt!.year == today.year &&
              o.createdAt!.month == today.month &&
              o.createdAt!.day == today.day;
        }).toList();

        final pendingOrders = orders.where((o) =>
          o.status == 'pending' || o.status == 'confirmed'
        ).length;

        final todayRevenue = todayOrders.fold<double>(
          0, (sum, o) => sum + o.total,
        );

        final productCount = productsAsync.when(
          data: (products) => products.length,
          loading: () => 0,
          error: (_, __) => 0,
        );

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Today\'s Orders',
                    value: '${todayOrders.length}',
                    icon: Icons.shopping_bag_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatCard(
                    title: 'Revenue',
                    value: '\$${todayRevenue.toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Pending',
                    value: '$pendingOrders',
                    icon: Icons.pending_actions,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatCard(
                    title: 'Products',
                    value: '$productCount',
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.secondary,
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
      error: (error, _) => Center(
        child: Text('Error loading stats: $error'),
      ),
    );
  }
}

class _RecentOrders extends ConsumerWidget {
  const _RecentOrders({required this.vendorId});

  final String vendorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(streamOrdersByVendorIdProvider(vendorId));

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No orders yet',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
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
                  '${order.items.length} items • \$${order.total.toStringAsFixed(2)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      order.status.toUpperCase(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (order.createdAt != null)
                      Text(
                        _formatTime(order.createdAt!),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  context.push(AppRoutes.orderDetails.replaceFirst(':id', order.id));
                },
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
          child: Text('Error loading orders: $error'),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.info;
      case 'preparing':
        return AppColors.primary;
      case 'ready':
        return AppColors.success;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.check_circle;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
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
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
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
