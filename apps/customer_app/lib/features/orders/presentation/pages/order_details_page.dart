import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';

/// Order details page showing full order information
class OrderDetailsPage extends ConsumerWidget {
  const OrderDetailsPage({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(streamOrderByIdProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return const Center(
              child: Text('Order not found'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order header
                _OrderHeader(order: order),

                const SizedBox(height: AppSpacing.xl),

                // Order status timeline
                _OrderTimeline(order: order),

                const SizedBox(height: AppSpacing.xl),

                // Vendor info
                _VendorInfo(vendorId: order.vendorId),

                const SizedBox(height: AppSpacing.xl),

                // Driver info (if order is out for delivery or delivered)
                if (order.driverId != null &&
                    (order.isOutForDelivery || order.isInTransit || order.isDelivered)) ...[
                  _DriverInfo(driverId: order.driverId!),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // Order items
                Text('Order Items', style: AppTextStyles.titleLarge),
                const SizedBox(height: AppSpacing.md),
                ...order.items.map((item) => _OrderItemTile(item: item)),

                const Divider(height: AppSpacing.xl),

                // Order summary
                _OrderSummary(order: order),

                const SizedBox(height: AppSpacing.xl),

                // Delivery address
                Text('Delivery Address', style: AppTextStyles.titleLarge),
                const SizedBox(height: AppSpacing.md),
                _AddressCard(address: order.deliveryAddress),

                if (order.customerNotes != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text('Notes', style: AppTextStyles.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    order.customerNotes!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],

                // Reviews section (only for delivered orders)
                if (order.isDelivered) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const Divider(),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Your Feedback', style: AppTextStyles.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  _ReviewCard(
                    orderId: order.id!,
                    vendorId: order.vendorId,
                    title: 'Rate Vendor',
                    type: ReviewType.vendor,
                  ),
                  if (order.driverId != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ReviewCard(
                      orderId: order.id!,
                      vendorId: order.driverId!,
                      title: 'Rate Driver',
                      type: ReviewType.driver,
                    ),
                  ],
                ],

                const SizedBox(height: AppSpacing.xxl),

                // Cancel order button (if allowed)
                if (order.canBeCancelled)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showCancelDialog(context, ref, order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: const Text('Cancel Order'),
                    ),
                  ),
              ],
            ),
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
                'Error loading order',
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

  void _showCancelDialog(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Cancel the order
              final result = await ref
                  .read(orderRepositoryProvider)
                  .cancelOrder(order.id, 'Cancelled by customer');

              if (!context.mounted) return;

              result.fold(
                (failure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel order: ${failure.message}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                },
                (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order cancelled successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              );
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}

/// Order header with ID and status
class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.order});

  final OrderModel order;

  Color _getStatusColor() {
    if (order.isDelivered) return AppColors.success;
    if (order.isCancelled) return AppColors.error;
    if (order.isOutForDelivery || order.isInTransit || order.isPickedUp) return AppColors.info;
    if (order.isPreparing || order.isReady) return AppColors.warning;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order #${order.id.substring(0, 8)}',
            style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
            child: Text(
              order.statusDisplay,
              style: AppTextStyles.bodyMedium.copyWith(
                color: _getStatusColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (order.createdAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Placed on ${_formatDate(order.createdAt!)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Order timeline showing status progression
class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TimelineStep(
        title: 'Order Placed',
        time: order.createdAt,
        isCompleted: true,
      ),
      _TimelineStep(
        title: 'Confirmed',
        time: order.confirmedAt,
        isCompleted: order.isConfirmed ||
            order.isPreparing ||
            order.isReady ||
            order.isOutForDelivery ||
            order.isPickedUp ||
            order.isInTransit ||
            order.isDelivered,
      ),
      _TimelineStep(
        title: 'Preparing',
        time: order.preparingAt,
        isCompleted: order.isPreparing ||
            order.isReady ||
            order.isOutForDelivery ||
            order.isPickedUp ||
            order.isInTransit ||
            order.isDelivered,
      ),
      _TimelineStep(
        title: 'Ready for Pickup',
        time: order.readyAt,
        isCompleted: order.isReady ||
            order.isOutForDelivery ||
            order.isPickedUp ||
            order.isInTransit ||
            order.isDelivered,
      ),
      _TimelineStep(
        title: 'Out for Delivery',
        time: order.pickedUpAt,
        isCompleted:
            order.isOutForDelivery || order.isPickedUp || order.isInTransit || order.isDelivered,
      ),
      _TimelineStep(
        title: 'Delivered',
        time: order.deliveredAt,
        isCompleted: order.isDelivered,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Status', style: AppTextStyles.titleLarge),
        const SizedBox(height: AppSpacing.md),
        ...steps.asMap().entries.map((entry) {
          final isLast = entry.key == steps.length - 1;
          return _TimelineItem(
            step: entry.value,
            isLast: isLast,
            isCancelled: order.isCancelled,
          );
        }),
      ],
    );
  }
}

class _TimelineStep {
  const _TimelineStep({
    required this.title,
    required this.time,
    required this.isCompleted,
  });

  final String title;
  final DateTime? time;
  final bool isCompleted;
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.step,
    required this.isLast,
    required this.isCancelled,
  });

  final _TimelineStep step;
  final bool isLast;
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    final color = isCancelled
        ? AppColors.textSecondary
        : step.isCompleted
            ? AppColors.success
            : AppColors.textSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: step.isCompleted && !isCancelled
                    ? AppColors.success
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
              ),
              child: step.isCompleted && !isCancelled
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: color.withValues(alpha: 0.3),
              ),
          ],
        ),

        const SizedBox(width: AppSpacing.md),

        // Step info
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: step.isCompleted && !isCancelled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                if (step.time != null)
                  Text(
                    _formatTime(step.time!),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Vendor information card
class _VendorInfo extends ConsumerWidget {
  const _VendorInfo({required this.vendorId});

  final String vendorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorAsync = ref.watch(streamVendorByIdProvider(vendorId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vendor', style: AppTextStyles.titleLarge),
        const SizedBox(height: AppSpacing.md),
        vendorAsync.when(
          data: (vendor) {
            if (vendor == null) {
              return const Text('Vendor not found');
            }

            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  if (vendor.logoUrl != null && vendor.logoUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                      child: Image.network(
                        vendor.logoUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 48,
                            height: 48,
                            color: AppColors.background,
                            child: const Icon(Icons.store, size: 24),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppSpacing.xs),
                      ),
                      child: const Icon(Icons.store, size: 24),
                    ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.businessName,
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          vendor.tableLocation,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const SmallLoadingIndicator(),
          error: (_, __) => const Text('Error loading vendor'),
        ),
      ],
    );
  }
}

/// Driver information card
class _DriverInfo extends ConsumerWidget {
  const _DriverInfo({required this.driverId});

  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverAsync = ref.watch(streamUserByIdProvider(driverId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Driver', style: AppTextStyles.titleLarge),
        const SizedBox(height: AppSpacing.md),
        driverAsync.when(
          data: (driver) {
            if (driver == null) {
              return const Text('Driver information not available');
            }

            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      driver.displayName?.substring(0, 1).toUpperCase() ?? 'D',
                      style: AppTextStyles.titleMedium.copyWith(
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
                          driver.displayName ?? 'Driver',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            const Icon(
                              Icons.local_shipping,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Delivery Driver',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const SmallLoadingIndicator(),
          error: (_, __) => const Text('Error loading driver information'),
        ),
      ],
    );
  }
}

/// Order item tile
class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});

  final CartItemModel item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          if (item.productImage != null && item.productImage!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.xs),
              child: Image.network(
                item.productImage!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: AppColors.background,
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSpacing.xs),
              ),
              child: const Icon(Icons.shopping_basket),
            ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? 'Unknown Product',
                  style: AppTextStyles.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${item.formattedUnitPrice} x ${item.quantity}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.formattedTotal,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Order summary with totals
class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Subtotal', style: AppTextStyles.bodyLarge),
            Text(
              order.formattedSubtotal,
              style: AppTextStyles.bodyLarge,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Delivery Fee',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              order.formattedDeliveryFee,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const Divider(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: AppTextStyles.titleLarge),
            Text(
              order.formattedTotal,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Address card
class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address});

  final AddressModel address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_on,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              address.formattedAddress,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Review card for rating vendor or driver
class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({
    required this.orderId,
    required this.vendorId,
    required this.title,
    required this.type,
  });

  final String orderId;
  final String vendorId;
  final String title;
  final ReviewType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox.shrink();

    // Get target name (vendor or driver)
    final targetAsync = type == ReviewType.vendor
        ? ref.watch(streamVendorByIdProvider(vendorId))
        : ref.watch(streamUserByIdProvider(vendorId));

    // Watch existing review
    final reviewAsync = ref.watch(
      streamUserReviewForTargetProvider(user.id, vendorId, orderId, type),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: targetAsync.when(
          data: (target) {
            if (target == null) return const SizedBox.shrink();

            final targetName = type == ReviewType.vendor
                ? (target as VendorModel).businessName
                : (target as UserModel).displayName ?? 'Driver';

            return reviewAsync.when(
              data: (review) {
                if (review != null) {
                  // Show existing review
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _editReview(context, ref, user, targetName, review),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < review.rating ? Icons.star : Icons.star_border,
                            color: AppColors.warning,
                            size: 20,
                          ),
                        ),
                      ),
                      if (review.hasComment) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          review.comment!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  );
                }

                // Show "Leave a Review" button
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      targetName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _addReview(context, ref, user, targetName),
                        icon: const Icon(Icons.star_outline),
                        label: const Text('Leave a Review'),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const SmallLoadingIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
          loading: () => const SmallLoadingIndicator(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Future<void> _addReview(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
    String targetName,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RatingDialog(
        targetName: targetName,
        targetType: type == ReviewType.vendor ? 'vendor' : 'driver',
        onSubmit: (rating, comment) async {
          final review = ReviewModel(
            orderId: orderId,
            userId: user.id,
            userName: user.displayName ?? 'Customer',
            userPhoto: user.photoUrl,
            targetId: vendorId,
            type: type,
            rating: rating,
            comment: comment,
            createdAt: DateTime.now(),
          );

          final reviewRepo = ref.read(reviewRepositoryProvider);
          final addResult = await reviewRepo.addReview(review);

          return addResult.fold(
            (failure) => false,
            (success) => true,
          );
        },
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your feedback!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _editReview(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
    String targetName,
    ReviewModel existingReview,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RatingDialog(
        targetName: targetName,
        targetType: type == ReviewType.vendor ? 'vendor' : 'driver',
        existingRating: existingReview.rating,
        existingComment: existingReview.comment,
        onSubmit: (rating, comment) async {
          final updatedReview = existingReview.copyWith(
            rating: rating,
            comment: comment,
            updatedAt: DateTime.now(),
          );

          final reviewRepo = ref.read(reviewRepositoryProvider);
          final updateResult = await reviewRepo.updateReview(updatedReview);

          return updateResult.fold(
            (failure) => false,
            (success) => true,
          );
        },
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
