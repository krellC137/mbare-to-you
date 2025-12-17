import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';

class EarningsPage extends ConsumerWidget {
  const EarningsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    final ordersAsync = ref.watch(streamOrdersByDriverIdProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
      ),
      body: ordersAsync.when(
        data: (orders) {
          final completedOrders = orders.where((o) => o.status == 'delivered').toList();
          final totalEarnings = _calculateEarnings(completedOrders);
          final todayEarnings = _calculateTodayEarnings(completedOrders);
          final weekEarnings = _calculateWeekEarnings(completedOrders);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                _EarningsSummaryCard(
                  title: 'Total Earnings',
                  amount: totalEarnings,
                  icon: Icons.account_balance_wallet,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _EarningsSummaryCard(
                        title: 'Today',
                        amount: todayEarnings,
                        icon: Icons.today,
                        color: AppColors.success,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _EarningsSummaryCard(
                        title: 'This Week',
                        amount: weekEarnings,
                        icon: Icons.date_range,
                        color: AppColors.info,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Stats
                Text(
                  'Statistics',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _StatsRow(
                  label: 'Total Deliveries',
                  value: '${completedOrders.length}',
                  icon: Icons.local_shipping,
                ),
                _StatsRow(
                  label: 'Average per Delivery',
                  value: completedOrders.isEmpty
                      ? '\$0.00'
                      : '\$${(totalEarnings / completedOrders.length).toStringAsFixed(2)}',
                  icon: Icons.trending_up,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Recent Earnings
                Text(
                  'Recent Earnings',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (completedOrders.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        children: [
                          Icon(
                            Icons.money_off,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No earnings yet',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...completedOrders.take(10).map((order) => _EarningItem(order: order)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  double _calculateEarnings(List<OrderModel> orders) {
    // Assume driver gets 15% of delivery fee
    return orders.fold(0.0, (sum, order) => sum + (order.deliveryFee * 0.85));
  }

  double _calculateTodayEarnings(List<OrderModel> orders) {
    final today = DateTime.now();
    final todayOrders = orders.where((o) {
      if (o.deliveredAt == null) return false;
      return o.deliveredAt!.year == today.year &&
          o.deliveredAt!.month == today.month &&
          o.deliveredAt!.day == today.day;
    }).toList();
    return _calculateEarnings(todayOrders);
  }

  double _calculateWeekEarnings(List<OrderModel> orders) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekOrders = orders.where((o) {
      if (o.deliveredAt == null) return false;
      return o.deliveredAt!.isAfter(weekStart);
    }).toList();
    return _calculateEarnings(weekOrders);
  }
}

class _EarningsSummaryCard extends StatelessWidget {
  const _EarningsSummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    this.compact = false,
  });

  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: compact ? 20 : 24),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: (compact ? AppTextStyles.labelMedium : AppTextStyles.bodyMedium).copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: (compact ? AppTextStyles.titleLarge : AppTextStyles.headlineMedium).copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningItem extends StatelessWidget {
  const _EarningItem({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final earning = order.deliveryFee * 0.85;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (order.deliveredAt != null)
                    Text(
                      DateFormat('MMM d, h:mm a').format(order.deliveredAt!),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '+\$${earning.toStringAsFixed(2)}',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
