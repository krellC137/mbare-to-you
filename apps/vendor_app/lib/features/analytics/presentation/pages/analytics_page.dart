import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';

/// Analytics page showing revenue and order statistics
class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateChangesProvider).value;
    final vendorId = currentUser?.uid ?? '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Statistics', icon: Icon(Icons.bar_chart)),
              Tab(text: 'Reviews', icon: Icon(Icons.star)),
            ],
          ),
        ),
        body: vendorId.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _StatisticsTab(vendorId: vendorId),
                  _ReviewsTab(vendorId: vendorId),
                ],
              ),
      ),
    );
  }
}

/// Statistics tab showing revenue and order analytics
class _StatisticsTab extends ConsumerWidget {
  const _StatisticsTab({required this.vendorId});

  final String vendorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(streamOrdersByVendorIdProvider(vendorId));

    return ordersAsync.when(
      data: (orders) {
        final stats = _calculateStats(orders);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              _SummaryCards(stats: stats),
              const SizedBox(height: AppSpacing.lg),

              // Revenue chart
              Text(
                'Revenue (Last 7 Days)',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _RevenueChart(orders: orders),
              const SizedBox(height: AppSpacing.lg),

              // Order status breakdown
              Text(
                'Order Status',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _OrderStatusChart(stats: stats),
              const SizedBox(height: AppSpacing.lg),

              // Top products
              Text(
                'Top Products',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _TopProducts(orders: orders),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Map<String, dynamic> _calculateStats(List<OrderModel> orders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = today.subtract(const Duration(days: 7));
    final thisMonth = DateTime(now.year, now.month, 1);

    final deliveredOrders = orders.where((o) => o.status == 'delivered').toList();

    final todayOrders = deliveredOrders.where((o) {
      if (o.createdAt == null) return false;
      final orderDate = DateTime(o.createdAt!.year, o.createdAt!.month, o.createdAt!.day);
      return orderDate == today;
    }).toList();

    final weekOrders = deliveredOrders.where((o) {
      if (o.createdAt == null) return false;
      return o.createdAt!.isAfter(thisWeek);
    }).toList();

    final monthOrders = deliveredOrders.where((o) {
      if (o.createdAt == null) return false;
      return o.createdAt!.isAfter(thisMonth);
    }).toList();

    return {
      'totalOrders': orders.length,
      'deliveredOrders': deliveredOrders.length,
      'pendingOrders': orders.where((o) => o.status == 'pending').length,
      'confirmedOrders': orders.where((o) => o.status == 'confirmed').length,
      'preparingOrders': orders.where((o) => o.status == 'preparing').length,
      'readyOrders': orders.where((o) => o.status == 'ready').length,
      'cancelledOrders': orders.where((o) => o.status == 'cancelled').length,
      'todayRevenue': todayOrders.fold<double>(0, (sum, o) => sum + o.total),
      'weekRevenue': weekOrders.fold<double>(0, (sum, o) => sum + o.total),
      'monthRevenue': monthOrders.fold<double>(0, (sum, o) => sum + o.total),
      'totalRevenue': deliveredOrders.fold<double>(0, (sum, o) => sum + o.total),
      'avgOrderValue': deliveredOrders.isNotEmpty
          ? deliveredOrders.fold<double>(0, (sum, o) => sum + o.total) / deliveredOrders.length
          : 0.0,
    };
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: "Today's Revenue",
                value: '\$${(stats['todayRevenue'] as double).toStringAsFixed(2)}',
                icon: Icons.today,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                title: 'This Week',
                value: '\$${(stats['weekRevenue'] as double).toStringAsFixed(2)}',
                icon: Icons.date_range,
                color: AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'This Month',
                value: '\$${(stats['monthRevenue'] as double).toStringAsFixed(2)}',
                icon: Icons.calendar_month,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                title: 'Avg Order',
                value: '\$${(stats['avgOrderValue'] as double).toStringAsFixed(2)}',
                icon: Icons.trending_up,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
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
            Icon(icon, color: color, size: 20),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: AppTextStyles.titleLarge.copyWith(
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

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final dailyRevenue = _getDailyRevenue();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: dailyRevenue.map((e) => e['revenue'] as double).fold(0.0, (a, b) => a > b ? a : b) * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '\$${rod.toY.toStringAsFixed(2)}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < dailyRevenue.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            dailyRevenue[index]['day'] as String,
                            style: AppTextStyles.labelSmall,
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: dailyRevenue.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value['revenue'] as double,
                      color: AppColors.primary,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getDailyRevenue() {
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayOrders = orders.where((o) {
        if (o.createdAt == null || o.status != 'delivered') return false;
        return o.createdAt!.isAfter(dayStart) && o.createdAt!.isBefore(dayEnd);
      });

      final revenue = dayOrders.fold<double>(0, (sum, o) => sum + o.total);

      result.add({
        'day': DateFormat('E').format(date),
        'revenue': revenue,
      });
    }

    return result;
  }
}

class _OrderStatusChart extends StatelessWidget {
  const _OrderStatusChart({required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final total = stats['totalOrders'] as int;
    if (total == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: Text('No orders yet')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _StatusBar(
              label: 'Delivered',
              count: stats['deliveredOrders'] as int,
              total: total,
              color: AppColors.success,
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatusBar(
              label: 'Pending',
              count: stats['pendingOrders'] as int,
              total: total,
              color: AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatusBar(
              label: 'Preparing',
              count: stats['preparingOrders'] as int,
              total: total,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatusBar(
              label: 'Ready',
              count: stats['readyOrders'] as int,
              total: total,
              color: AppColors.info,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? count / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodySmall),
            Text('$count', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: AppColors.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
}

class _TopProducts extends StatelessWidget {
  const _TopProducts({required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final productSales = <String, int>{};

    for (final order in orders.where((o) => o.status == 'delivered')) {
      for (final item in order.items) {
        final name = item.productName ?? 'Unknown';
        productSales[name] = (productSales[name] ?? 0) + item.quantity;
      }
    }

    if (productSales.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: Text('No sales data yet')),
        ),
      );
    }

    final sortedProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Column(
        children: sortedProducts.take(5).map((entry) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                '${sortedProducts.indexOf(entry) + 1}',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
              ),
            ),
            title: Text(entry.key),
            trailing: Text(
              '${entry.value} sold',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Reviews tab showing customer feedback
class _ReviewsTab extends ConsumerWidget {
  const _ReviewsTab({required this.vendorId});

  final String vendorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(streamVendorReviewsProvider(vendorId));

    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_outline,
                  size: 64,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No reviews yet',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Customer reviews will appear here',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        // Calculate average rating
        final avgRating = reviews.fold<int>(
          0,
          (sum, review) => sum + review.rating,
        ) / reviews.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              // Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: AppTextStyles.displayLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) => Icon(
                          index < avgRating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: AppColors.warning,
                          size: 24,
                        )),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${reviews.length} ${reviews.length == 1 ? 'review' : 'reviews'}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Reviews List
              ...reviews.map((review) => _ReviewListItem(review: review)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Error loading reviews',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error.toString(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual review list item
class _ReviewListItem extends StatelessWidget {
  const _ReviewListItem({required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: review.userPhoto != null
                      ? NetworkImage(review.userPhoto!)
                      : null,
                  child: review.userPhoto == null
                      ? Text(
                          review.userName.isNotEmpty
                              ? review.userName[0].toUpperCase()
                              : 'C',
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: List.generate(5, (index) => Icon(
                          index < review.rating
                              ? Icons.star
                              : Icons.star_border,
                          color: AppColors.warning,
                          size: 16,
                        )),
                      ),
                    ],
                  ),
                ),
                if (review.createdAt != null)
                  Text(
                    _formatDate(review.createdAt!),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            if (review.hasComment) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                review.comment!,
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, y').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
