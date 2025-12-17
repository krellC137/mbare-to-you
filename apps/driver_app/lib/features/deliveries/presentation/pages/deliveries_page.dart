import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';
import 'package:driver_app/core/router/app_router.dart';

class DeliveriesPage extends ConsumerStatefulWidget {
  const DeliveriesPage({super.key});

  @override
  ConsumerState<DeliveriesPage> createState() => _DeliveriesPageState();
}

class _DeliveriesPageState extends ConsumerState<DeliveriesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deliveries'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AvailableDeliveryList(),
          _ActiveDeliveryList(),
          _CompletedDeliveryList(),
        ],
      ),
    );
  }
}

class _AvailableDeliveryList extends ConsumerWidget {
  const _AvailableDeliveryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(streamOrdersByStatusProvider('ready'));

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return _EmptyState(
            icon: Icons.inbox_outlined,
            message: 'No available deliveries',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: orders.length,
          itemBuilder: (context, index) => _DeliveryCard(
            order: orders[index],
            showAcceptButton: true,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _ActiveDeliveryList extends ConsumerWidget {
  const _ActiveDeliveryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      return const Center(child: Text('Please log in'));
    }

    final ordersAsync = ref.watch(streamOrdersByDriverIdProvider(user.id));

    return ordersAsync.when(
      data: (orders) {
        final activeOrders = orders.where((o) => o.status == 'out_for_delivery').toList();
        if (activeOrders.isEmpty) {
          return _EmptyState(
            icon: Icons.local_shipping_outlined,
            message: 'No active deliveries',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: activeOrders.length,
          itemBuilder: (context, index) => _DeliveryCard(
            order: activeOrders[index],
            showStatusActions: true,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _CompletedDeliveryList extends ConsumerWidget {
  const _CompletedDeliveryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      return const Center(child: Text('Please log in'));
    }

    final ordersAsync = ref.watch(streamOrdersByDriverIdProvider(user.id));

    return ordersAsync.when(
      data: (orders) {
        final completedOrders = orders.where((o) => o.status == 'delivered').toList();
        if (completedOrders.isEmpty) {
          return _EmptyState(
            icon: Icons.check_circle_outline,
            message: 'No completed deliveries',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: completedOrders.length,
          itemBuilder: (context, index) => _DeliveryCard(
            order: completedOrders[index],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends ConsumerWidget {
  const _DeliveryCard({
    required this.order,
    this.showAcceptButton = false,
    this.showStatusActions = false,
  });
  final OrderModel order;
  final bool showAcceptButton;
  final bool showStatusActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () {
          context.push(AppRoutes.deliveryDetails.replaceFirst(':id', order.id));
        },
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
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                    child: Text(
                      order.statusDisplay,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      order.deliveryAddress.formattedAddress,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.items.length} items',
                    style: AppTextStyles.bodySmall,
                  ),
                  Text(
                    '\$${order.total.toStringAsFixed(2)}',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (order.createdAt != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  DateFormat('MMM d, h:mm a').format(order.createdAt!),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (showAcceptButton) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptOrder(context, ref),
                    icon: const Icon(Icons.check),
                    label: const Text('Accept Delivery'),
                  ),
                ),
              ],
              if (showStatusActions) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openMaps(context),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Navigate'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _completeDelivery(context, ref),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Complete'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acceptOrder(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final orderRepo = ref.read(orderRepositoryProvider);

    // Accept delivery - atomic update that assigns driver, updates status, and sets pickedUpAt
    final result = await orderRepo.acceptDelivery(order.id, user.id);

    if (context.mounted) {
      result.fold(
        (failure) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept delivery: ${failure.message}'),
            backgroundColor: AppColors.error,
          ),
        ),
        (_) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery accepted!'),
            backgroundColor: AppColors.success,
          ),
        ),
      );
    }
  }

  Future<void> _completeDelivery(BuildContext context, WidgetRef ref) async {
    final orderRepo = ref.read(orderRepositoryProvider);
    await orderRepo.completeOrder(order.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery completed!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _openMaps(BuildContext context) {
    // TODO: Implement maps navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening maps...')),
    );
  }

  Color _getStatusColor() {
    switch (order.status) {
      case 'ready':
        return AppColors.success;
      case 'out_for_delivery':
        return AppColors.warning;
      case 'delivered':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }
}
