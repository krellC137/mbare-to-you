import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _darkMode = false;
  double _deliveryFeePercent = 10.0;
  double _platformFeePercent = 5.0;
  PlatformSettingsModel? _currentSettings;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(platformSettingsProvider);

    return settingsAsync.when(
      data: (result) {
        return result.fold(
          (failure) => _buildError(failure.message),
          (settings) {
            // Update local state from Firestore
            if (_currentSettings == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _currentSettings = settings;
                    _deliveryFeePercent = settings.deliveryFeePercentage;
                    _platformFeePercent = settings.platformFeePercentage;
                  });
                }
              });
            }
            return _buildContent(context);
          },
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF5F6FA),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _buildError(error.toString()),
    );
  }

  Widget _buildError(String message) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $message'),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage platform settings and configuration',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Two column layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column
                Expanded(
                  child: Column(
                    children: [
                      // Notifications
                      _SettingsCard(
                        title: 'Notifications',
                        icon: Icons.notifications_outlined,
                        children: [
                          _SwitchTile(
                            title: 'Email Notifications',
                            subtitle: 'Receive order updates via email',
                            value: _emailNotifications,
                            onChanged: (v) => setState(() => _emailNotifications = v),
                          ),
                          _SwitchTile(
                            title: 'Push Notifications',
                            subtitle: 'Receive instant push notifications',
                            value: _pushNotifications,
                            onChanged: (v) => setState(() => _pushNotifications = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Appearance
                      _SettingsCard(
                        title: 'Appearance',
                        icon: Icons.palette_outlined,
                        children: [
                          _SwitchTile(
                            title: 'Dark Mode',
                            subtitle: 'Use dark theme',
                            value: _darkMode,
                            onChanged: (v) => setState(() => _darkMode = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Right column
                Expanded(
                  child: Column(
                    children: [
                      // Platform Fees
                      _SettingsCard(
                        title: 'Platform Fees',
                        icon: Icons.attach_money,
                        children: [
                          _SliderTile(
                            title: 'Delivery Fee',
                            value: _deliveryFeePercent,
                            suffix: '% of order total',
                            min: 0,
                            max: 25,
                            onChanged: (v) => setState(() => _deliveryFeePercent = v),
                          ),
                          const Divider(height: 1),
                          _SliderTile(
                            title: 'Platform Fee',
                            value: _platformFeePercent,
                            suffix: '% commission',
                            min: 0,
                            max: 20,
                            onChanged: (v) => setState(() => _platformFeePercent = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Data Management
                      _SettingsCard(
                        title: 'Data Management',
                        icon: Icons.storage_outlined,
                        children: [
                          _ActionTile(
                            icon: Icons.download_outlined,
                            title: 'Export Data',
                            subtitle: 'Download all platform data as CSV',
                            onTap: () => _showSnackBar('Export feature coming soon'),
                          ),
                          const Divider(height: 1),
                          _ActionTile(
                            icon: Icons.backup_outlined,
                            title: 'Backup Database',
                            subtitle: 'Create a backup of all data',
                            onTap: () => _showSnackBar('Backup feature coming soon'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Save button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveSettings() async {
    if (_currentSettings == null) return;

    final repository = ref.read(settingsRepositoryProvider);
    final authRepo = ref.read(authRepositoryProvider);

    // Get current user ID
    final userId = authRepo.currentUser?.uid ?? 'unknown';

    // Update settings
    final updatedSettings = _currentSettings!.copyWith(
      deliveryFeePercentage: _deliveryFeePercent,
      platformFeePercentage: _platformFeePercent,
      updatedAt: DateTime.now(),
      updatedBy: userId,
    );

    final result = await repository.updatePlatformSettings(updatedSettings);

    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: ${failure.message}'),
            backgroundColor: Colors.red[600],
          ),
        );
      },
      (_) {
        setState(() => _currentSettings = updatedSettings);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Settings saved successfully'),
            backgroundColor: Colors.green[600],
          ),
        );
      },
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.title,
    required this.value,
    required this.suffix,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String title;
  final double value;
  final String suffix;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${value.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6366F1),
              inactiveTrackColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
              thumbColor: const Color(0xFF6366F1),
              overlayColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
          Text(
            suffix,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
