import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(streamAllOrdersProvider);
    final usersAsync = ref.watch(streamAllUsersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome back! Here\'s what\'s happening.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Content
            ordersAsync.when(
              data: (orders) {
                final users = usersAsync.valueOrNull ?? [];
                return _buildDashboardContent(context, orders, users);
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(100),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading data',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    List<OrderModel> orders,
    List<UserModel> users,
  ) {
    final today = DateTime.now();
    final todayOrders = orders.where((o) {
      if (o.createdAt == null) return false;
      return o.createdAt!.year == today.year &&
          o.createdAt!.month == today.month &&
          o.createdAt!.day == today.day;
    }).toList();

    final totalRevenue = orders.fold<double>(0, (sum, o) => sum + o.total);
    final todayRevenue = todayOrders.fold<double>(0, (sum, o) => sum + o.total);
    final pendingOrders = orders.where((o) =>
        o.status == 'pending' || o.status == 'confirmed').length;

    final vendors = users.where((u) => u.role == 'vendor').length;
    final drivers = users.where((u) => u.role == 'driver').length;
    final customers = users.where((u) => u.role == 'customer').length;

    return Column(
      children: [
        // Stats cards - First row
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Orders',
                value: '${orders.length}',
                subtitle: '+${todayOrders.length} today',
                icon: Icons.shopping_cart_outlined,
                color: const Color(0xFF6366F1),
                bgColor: const Color(0xFFEEF2FF),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Total Revenue',
                value: '\$${totalRevenue.toStringAsFixed(0)}',
                subtitle: '+\$${todayRevenue.toStringAsFixed(0)} today',
                icon: Icons.attach_money,
                color: const Color(0xFF10B981),
                bgColor: const Color(0xFFD1FAE5),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Pending Orders',
                value: '$pendingOrders',
                subtitle: 'Needs attention',
                icon: Icons.pending_actions_outlined,
                color: const Color(0xFFF59E0B),
                bgColor: const Color(0xFFFEF3C7),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Total Users',
                value: '${users.length}',
                subtitle: '$vendors vendors, $drivers drivers',
                icon: Icons.people_outline,
                color: const Color(0xFF8B5CF6),
                bgColor: const Color(0xFFF3E8FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Charts row
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: _RevenueChart(orders: orders),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _OrderStatusChart(orders: orders),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Bottom row - Recent orders and user breakdown
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: _RecentOrdersTable(orders: orders),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _UserBreakdown(
                  vendors: vendors,
                  drivers: drivers,
                  customers: customers,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final spots = <FlSpot>[];
    final labels = <String>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayOrders = orders.where((o) {
        if (o.createdAt == null) return false;
        return o.createdAt!.year == date.year &&
            o.createdAt!.month == date.month &&
            o.createdAt!.day == date.day;
      });

      final revenue = dayOrders.fold<double>(0, (sum, o) => sum + o.total);
      spots.add(FlSpot((6 - i).toDouble(), revenue));
      labels.add(DateFormat('E').format(date));
    }

    final maxY = spots.map((s) => s.y).fold<double>(0, (a, b) => a > b ? a : b);
    final interval = maxY > 0 ? (maxY / 4).ceilToDouble() : 50.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Overview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Last 7 days',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval > 0 ? interval : 50,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '\$${value.toInt()}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[index],
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF6366F1),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: const Color(0xFF6366F1),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusChart extends StatelessWidget {
  const _OrderStatusChart({required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final statusCounts = <String, int>{};
    for (final order in orders) {
      statusCounts[order.status] = (statusCounts[order.status] ?? 0) + 1;
    }

    final colors = {
      'pending': const Color(0xFFF59E0B),
      'confirmed': const Color(0xFF3B82F6),
      'preparing': const Color(0xFF8B5CF6),
      'ready': const Color(0xFF10B981),
      'out_for_delivery': const Color(0xFFF97316),
      'delivered': const Color(0xFF22C55E),
      'cancelled': const Color(0xFFEF4444),
    };

    final sections = statusCounts.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.value}',
        color: colors[entry.key] ?? Colors.grey,
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Distribution',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: sections.isEmpty
                ? Center(
                    child: Text(
                      'No orders yet',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 35,
                      sectionsSpace: 2,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: statusCounts.entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[entry.key] ?? Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.key.replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RecentOrdersTable extends StatelessWidget {
  const _RecentOrdersTable({required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final recentOrders = orders.take(8).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Orders',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentOrders.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'No orders yet',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 400),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
                  columns: const [
                    DataColumn(label: Text('Order ID', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.w600))),
                  ],
                  rows: recentOrders.map((order) {
                    return DataRow(
                      cells: [
                        DataCell(Text('#${order.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.w500))),
                        DataCell(_StatusBadge(status: order.status)),
                        DataCell(Text('\$${order.total.toStringAsFixed(2)}')),
                        DataCell(
                          Text(
                            order.createdAt != null
                                ? DateFormat('MMM d, h:mm a').format(order.createdAt!)
                                : 'N/A',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = {
      'pending': (const Color(0xFFFEF3C7), const Color(0xFFF59E0B)),
      'confirmed': (const Color(0xFFDBEAFE), const Color(0xFF3B82F6)),
      'preparing': (const Color(0xFFF3E8FF), const Color(0xFF8B5CF6)),
      'ready': (const Color(0xFFD1FAE5), const Color(0xFF10B981)),
      'out_for_delivery': (const Color(0xFFFFEDD5), const Color(0xFFF97316)),
      'delivered': (const Color(0xFFDCFCE7), const Color(0xFF22C55E)),
      'cancelled': (const Color(0xFFFEE2E2), const Color(0xFFEF4444)),
    };

    final colorPair = colors[status] ?? (Colors.grey[100]!, Colors.grey);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorPair.$1,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colorPair.$2,
        ),
      ),
    );
  }
}

class _UserBreakdown extends StatelessWidget {
  const _UserBreakdown({
    required this.vendors,
    required this.drivers,
    required this.customers,
  });

  final int vendors;
  final int drivers;
  final int customers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Breakdown',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'By role',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          _UserTypeRow(
            icon: Icons.store_outlined,
            label: 'Vendors',
            count: vendors,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 16),
          _UserTypeRow(
            icon: Icons.delivery_dining_outlined,
            label: 'Drivers',
            count: drivers,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 16),
          _UserTypeRow(
            icon: Icons.person_outline,
            label: 'Customers',
            count: customers,
            color: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }
}

class _UserTypeRow extends StatelessWidget {
  const _UserTypeRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          '$count',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
