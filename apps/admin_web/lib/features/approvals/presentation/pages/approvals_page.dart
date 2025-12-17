import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';

class ApprovalsPage extends ConsumerStatefulWidget {
  const ApprovalsPage({super.key});

  @override
  ConsumerState<ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends ConsumerState<ApprovalsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Approvals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending Vendors'),
            Tab(text: 'Pending Drivers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PendingVendorsTab(),
          _PendingDriversTab(),
        ],
      ),
    );
  }
}

class _PendingVendorsTab extends ConsumerWidget {
  const _PendingVendorsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsAsync = ref.watch(streamAllVendorsProvider);

    return vendorsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (vendors) {
        final pendingVendors =
            vendors.where((v) => !v.isApproved).toList();

        if (pendingVendors.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: AppSpacing.md),
                Text('No pending vendor approvals'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: pendingVendors.length,
          itemBuilder: (context, index) {
            final vendor = pendingVendors[index];
            return _VendorApprovalCard(vendor: vendor);
          },
        );
      },
    );
  }
}

class _VendorApprovalCard extends ConsumerWidget {
  const _VendorApprovalCard({required this.vendor});
  final VendorModel vendor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            vendor.businessName.isNotEmpty
                ? vendor.businessName[0].toUpperCase()
                : 'V',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          vendor.businessName,
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vendor.tableLocation, style: AppTextStyles.bodySmall),
            if (vendor.description != null && vendor.description!.isNotEmpty)
              Text(
                vendor.description!,
                style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${vendor.email ?? ''}${vendor.phoneNumber != null ? ' • ${vendor.phoneNumber}' : ''}',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _rejectVendor(context, ref, vendor),
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: 'Reject',
            ),
            IconButton(
              onPressed: () => _approveVendor(context, ref, vendor),
              icon: const Icon(Icons.check, color: Colors.green),
              tooltip: 'Approve',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveVendor(
      BuildContext context, WidgetRef ref, VendorModel vendor) async {
    // Get repository references before any async gap
    final vendorRepo = ref.read(vendorRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Vendor'),
        content: Text('Approve "${vendor.businessName}" as a vendor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Update vendor to approved and active
      await vendorRepo.updateVendor(
        vendor.id,
        {'isApproved': true, 'isActive': true},
      );

      // Update user to active
      await userRepo.updateUser(
        vendor.ownerId,
        {'isActive': true},
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${vendor.businessName} has been approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _rejectVendor(
      BuildContext context, WidgetRef ref, VendorModel vendor) async {
    // Get repository references before any async gap
    final vendorRepo = ref.read(vendorRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Vendor'),
        content: Text(
            'Reject "${vendor.businessName}"? This will delete their account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Delete vendor profile
      await vendorRepo.deleteVendor(vendor.id);

      // Deactivate user account
      await userRepo.deactivateUser(vendor.ownerId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${vendor.businessName} has been rejected'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _PendingDriversTab extends ConsumerWidget {
  const _PendingDriversTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(streamAllDriverProfilesProvider());

    return driversAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error\n$stack')),
      data: (drivers) {
        debugPrint('Total drivers loaded: ${drivers.length}');
        final pendingDrivers =
            drivers.where((d) => !d.isApproved).toList();
        debugPrint('Pending drivers: ${pendingDrivers.length}');

        if (pendingDrivers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: AppSpacing.md),
                Text('No pending driver approvals'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: pendingDrivers.length,
          itemBuilder: (context, index) {
            final driver = pendingDrivers[index];
            return _DriverApprovalCard(driver: driver);
          },
        );
      },
    );
  }
}

class _DriverApprovalCard extends ConsumerWidget {
  const _DriverApprovalCard({required this.driver});
  final DriverProfileModel driver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get user details for this driver
    final userAsync = ref.watch(streamUserByIdProvider(driver.userId));

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: CircleAvatar(
          backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
          child: Icon(
            _getVehicleIcon(driver.vehicleType),
            color: AppColors.secondary,
          ),
        ),
        title: userAsync.when(
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Unknown Driver'),
          data: (user) => Text(
            user?.displayNameOrEmail ?? 'Unknown',
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            userAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (user) => user?.phoneNumber != null
                  ? Text(user!.phoneNumber!, style: AppTextStyles.bodySmall)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Vehicle: ${driver.vehicleType.toUpperCase()}${driver.vehiclePlateNumber != null ? ' • Plate: ${driver.vehiclePlateNumber}' : ''}${driver.licenseNumber != null ? ' • License: ${driver.licenseNumber}' : ''}',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _rejectDriver(context, ref, driver),
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: 'Reject',
            ),
            IconButton(
              onPressed: () => _approveDriver(context, ref, driver),
              icon: const Icon(Icons.check, color: Colors.green),
              tooltip: 'Approve',
            ),
          ],
        ),
      ),
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

  Future<void> _approveDriver(
      BuildContext context, WidgetRef ref, DriverProfileModel driver) async {
    // Get repository references before any async gap
    final driverRepo = ref.read(driverProfileRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Driver'),
        content: const Text('Approve this driver?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Update driver profile to approved and active
      await driverRepo.updateDriverProfile(
        driver.id,
        {'isApproved': true, 'isActive': true},
      );

      // Update user to active
      await userRepo.updateUser(
        driver.userId,
        {'isActive': true},
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver has been approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _rejectDriver(
      BuildContext context, WidgetRef ref, DriverProfileModel driver) async {
    // Get repository references before any async gap
    final driverRepo = ref.read(driverProfileRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Driver'),
        content:
            const Text('Reject this driver? This will delete their account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Delete driver profile
      await driverRepo.deleteDriverProfile(driver.id);

      // Deactivate user account
      await userRepo.deactivateUser(driver.userId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver has been rejected'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

