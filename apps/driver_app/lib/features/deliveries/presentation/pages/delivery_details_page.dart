import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryDetailsPage extends ConsumerWidget {
  const DeliveryDetailsPage({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(streamOrderByIdProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery #${orderId.substring(0, 8)}'),
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusCard(order: order, ref: ref),
                const SizedBox(height: AppSpacing.md),
                _VendorCard(vendorId: order.vendorId),
                const SizedBox(height: AppSpacing.md),
                _AddressCard(order: order),
                const SizedBox(height: AppSpacing.md),
                _ItemsCard(order: order),
                if (order.customerNotes != null && order.customerNotes!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _NotesCard(notes: order.customerNotes!),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.order, required this.ref});
  final OrderModel order;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
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
                  'Status',
                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
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
            if (order.createdAt != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Placed: ${DateFormat('MMM d, yyyy h:mm a').format(order.createdAt!)}',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _buildActionButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final orderRepo = ref.read(orderRepositoryProvider);

    switch (order.status) {
      case 'ready':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _updateStatus(context, orderRepo, 'out_for_delivery', 'Delivery started'),
            icon: const Icon(Icons.local_shipping),
            label: const Text('Start Delivery'),
          ),
        );
      case 'out_for_delivery':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showProofOfDeliveryDialog(context, orderRepo),
                icon: const Icon(Icons.check_circle),
                label: const Text('Complete with Photo'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _updateStatus(context, orderRepo, 'delivered', 'Delivery completed'),
                icon: const Icon(Icons.check),
                label: const Text('Complete without Photo'),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    OrderRepository orderRepo,
    String newStatus,
    String message,
  ) async {
    final result = await orderRepo.updateOrderStatus(order.id, newStatus);

    if (context.mounted) {
      result.fold(
        (failure) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${failure.message}'), backgroundColor: AppColors.error),
        ),
        (_) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.success),
        ),
      );
    }
  }

  Future<void> _showProofOfDeliveryDialog(
    BuildContext context,
    OrderRepository orderRepo,
  ) async {
    final picker = ImagePicker();
    File? photoFile;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Proof of Delivery'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (photoFile != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  child: Image.file(
                    photoFile!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ] else ...[
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Take a photo of delivery',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final image = await picker.pickImage(source: ImageSource.camera);
                        if (image != null) {
                          setState(() => photoFile = File(image.path));
                        }
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setState(() => photoFile = File(image.path));
                        }
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: photoFile == null
                  ? null
                  : () async {
                      Navigator.pop(dialogContext);
                      // TODO: Upload photo to Firebase Storage
                      // For now, just complete the delivery
                      await _updateStatus(context, orderRepo, 'delivered', 'Delivery completed with photo proof');
                    },
              child: const Text('Complete'),
            ),
          ],
        ),
      ),
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

class _VendorCard extends ConsumerWidget {
  const _VendorCard({required this.vendorId});
  final String vendorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorAsync = ref.watch(streamVendorByIdProvider(vendorId));

    return vendorAsync.when(
      data: (vendor) {
        if (vendor == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text('Vendor information not available'),
            ),
          );
        }

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
                      'Pickup Location',
                      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (vendor.logoUrl != null && vendor.logoUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.xs),
                        child: Image.network(
                          vendor.logoUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppSpacing.xs),
                              ),
                              child: const Icon(Icons.store, size: 20),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Vendor Name
                Row(
                  children: [
                    const Icon(Icons.store, size: 20, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor.businessName,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${vendor.marketSection} - Table ${vendor.tableNumber}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (vendor.phoneNumber != null && vendor.phoneNumber!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 20, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        vendor.phoneNumber!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _callVendor(vendor.phoneNumber!),
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text('Call Vendor'),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToVendor(vendor),
                    icon: const Icon(Icons.directions),
                    label: const Text('Navigate to Pickup Location'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text('Error loading vendor: $error'),
        ),
      ),
    );
  }

  Future<void> _callVendor(String phoneNumber) async {
    final phone = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(phone))) {
      await launchUrl(Uri.parse(phone));
    }
  }

  Future<void> _navigateToVendor(VendorModel vendor) async {
    // Use table location as search query
    final query = '${vendor.businessName}, ${vendor.marketSection}, Table ${vendor.tableNumber}, Mbare, Harare';
    final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final address = order.deliveryAddress;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Address',
              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(address.formattedAddress, style: AppTextStyles.bodyMedium),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openMaps(address),
                    icon: const Icon(Icons.map),
                    label: const Text('Navigate'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callCustomer(),
                    icon: const Icon(Icons.phone),
                    label: const Text('Call'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMaps(AddressModel address) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address.formattedAddress)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _callCustomer() async {
    // Placeholder - would need customer phone from order
    const phone = 'tel:+263771234567';
    if (await canLaunchUrl(Uri.parse(phone))) {
      await launchUrl(Uri.parse(phone));
    }
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items (${order.items.length})',
              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Text(
                    '${item.quantity}x',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(item.productName ?? 'Unknown', style: AppTextStyles.bodyMedium),
                  ),
                ],
              ),
            )),
            const Divider(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});
  final String notes;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Notes',
              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              notes,
              style: AppTextStyles.bodyMedium.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
