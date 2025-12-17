import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbare_ui/mbare_ui.dart';

/// Notification settings management page
class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  // TODO: Replace with actual state management/persistence
  bool _orderUpdates = true;
  bool _promotions = true;
  bool _newProducts = false;
  bool _vendorUpdates = false;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Order Notifications Section
          Text(
            'Order Notifications',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _orderUpdates,
                  onChanged: (value) {
                    setState(() => _orderUpdates = value);
                  },
                  title: const Text('Order Updates'),
                  subtitle: const Text(
                    'Get notified about order status changes',
                  ),
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _vendorUpdates,
                  onChanged: (value) {
                    setState(() => _vendorUpdates = value);
                  },
                  title: const Text('Vendor Updates'),
                  subtitle: const Text(
                    'Updates from vendors you follow',
                  ),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Marketing Notifications Section
          Text(
            'Marketing',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _promotions,
                  onChanged: (value) {
                    setState(() => _promotions = value);
                  },
                  title: const Text('Promotions & Deals'),
                  subtitle: const Text(
                    'Special offers and discounts',
                  ),
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _newProducts,
                  onChanged: (value) {
                    setState(() => _newProducts = value);
                  },
                  title: const Text('New Products'),
                  subtitle: const Text(
                    'Get notified when new products are available',
                  ),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Notification Channels Section
          Text(
            'Notification Channels',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() => _pushNotifications = value);
                  },
                  title: const Text('Push Notifications'),
                  subtitle: const Text(
                    'Receive notifications on this device',
                  ),
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() => _emailNotifications = value);
                  },
                  title: const Text('Email Notifications'),
                  subtitle: const Text(
                    'Receive notifications via email',
                  ),
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _smsNotifications,
                  onChanged: (value) {
                    setState(() => _smsNotifications = value);
                  },
                  title: const Text('SMS Notifications'),
                  subtitle: const Text(
                    'Receive notifications via SMS',
                  ),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Save button
          ElevatedButton(
            onPressed: () {
              // TODO: Implement saving preferences to backend
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings saved successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Save Settings'),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Info message
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.info,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'You can manage your notification preferences at any time. '
                    'Some critical notifications like order confirmations cannot be disabled.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
