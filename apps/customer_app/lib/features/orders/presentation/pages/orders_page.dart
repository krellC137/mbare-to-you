import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';

/// Filter options for orders
enum OrderFilter {
  all('All Orders'),
  active('Active'),
  completed('Completed'),
  cancelled('Cancelled');

  const OrderFilter(this.label);
  final String label;
}

/// Orders list page showing customer's order history with filters
class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  OrderFilter _selectedFilter = OrderFilter.all;

  // Cache filter counts to avoid recalculating on every build
  Map<OrderFilter, int> _filterCounts = {};

  Map<OrderFilter, int> _calculateFilterCounts(List<OrderModel> orders) {
    final activeCount = orders
        .where((order) => !order.isDelivered && !order.isCancelled)
        .length;
    final completedCount = orders.where((order) => order.isDelivered).length;
    final cancelledCount = orders.where((order) => order.isCancelled).length;

    return {
      OrderFilter.all: orders.length,
      OrderFilter.active: activeCount,
      OrderFilter.completed: completedCount,
      OrderFilter.cancelled: cancelledCount,
    };
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    switch (_selectedFilter) {
      case OrderFilter.all:
        return orders;
      case OrderFilter.active:
        return orders
            .where((order) => !order.isDelivered && !order.isCancelled)
            .toList();
      case OrderFilter.completed:
        return orders.where((order) => order.isDelivered).toList();
      case OrderFilter.cancelled:
        return orders.where((order) => order.isCancelled).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateChangesProvider).value;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: const Center(
          child: Text('Please log in to view your orders'),
        ),
      );
    }

    final ordersAsync = ref.watch(
      streamOrdersByCustomerIdProvider(currentUser.uid, limit: 50),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          // Filter menu
          PopupMenuButton<OrderFilter>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter orders',
            onSelected: (filter) {
              setState(() => _selectedFilter = filter);
            },
            itemBuilder: (context) => OrderFilter.values.map((filter) {
              return PopupMenuItem<OrderFilter>(
                value: filter,
                child: Row(
                  children: [
                    if (_selectedFilter == filter)
                      const Icon(Icons.check, size: 18, color: AppColors.primary)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(filter.label),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) {
          // Calculate filter counts once per data update
          _filterCounts = _calculateFilterCounts(orders);
          final filteredOrders = _filterOrders(orders);

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'No orders yet',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your order history will appear here',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Start Shopping'),
                  ),
                ],
              ),
            );
          }

          if (filteredOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.filter_alt_off,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No ${_selectedFilter.label.toLowerCase()}',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedFilter = OrderFilter.all);
                    },
                    child: const Text('Show all orders'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Filter chips
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: OrderFilter.values.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      final count = _filterCounts[filter] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text('${filter.label} ($count)'),
                          onSelected: (selected) {
                            setState(() => _selectedFilter = filter);
                          },
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Orders list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    top: AppSpacing.md,
                    bottom: 100, // Extra space for any bottom UI
                  ),
                  itemCount: filteredOrders.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return _OrderCard(order: order);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: SmallLoadingIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Error loading orders',
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
      ),
    );
  }
}

/// Order card widget
class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});

  final OrderModel order;

  Color _getStatusColor() {
    if (order.isDelivered) return AppColors.success;
    if (order.isCancelled) return AppColors.error;
    if (order.isInTransit || order.isPickedUp) return AppColors.info;
    if (order.isPreparing || order.isReady) return AppColors.warning;
    return AppColors.textSecondary;
  }

  IconData _getStatusIcon() {
    if (order.isDelivered) return Icons.check_circle;
    if (order.isCancelled) return Icons.cancel;
    if (order.isInTransit) return Icons.local_shipping;
    if (order.isPickedUp) return Icons.inventory_2;
    if (order.isReady) return Icons.shopping_bag;
    if (order.isPreparing) return Icons.restaurant;
    return Icons.hourglass_empty;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get vendor info
    final vendorAsync = ref.watch(streamVendorByIdProvider(order.vendorId));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/order/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with order number and status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id.substring(0, 8)}',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        vendorAsync.when(
                          data: (vendor) => Text(
                            vendor?.businessName ?? 'Unknown Vendor',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(),
                          size: 16,
                          color: _getStatusColor(),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          order.statusDisplay,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _getStatusColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Order items preview
              ...order.items.take(2).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      children: [
                        Text(
                          '${item.quantity}x',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            item.productName ?? 'Unknown Product',
                            style: AppTextStyles.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),

              if (order.items.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '+${order.items.length - 2} more items',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              const Divider(height: AppSpacing.lg),

              // Footer with date and total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.createdAt != null
                        ? _formatDate(order.createdAt!)
                        : 'Unknown date',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    order.formattedTotal,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
