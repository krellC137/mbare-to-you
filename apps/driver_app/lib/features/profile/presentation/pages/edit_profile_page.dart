import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';

/// Edit profile page for drivers
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Personal info
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Vehicle info
  final _vehiclePlateController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  String _vehicleType = 'motorcycle';

  bool _isLoading = false;
  bool _isInitialized = false;

  final _vehicleTypes = [
    {'value': 'motorcycle', 'label': 'Motorcycle'},
    {'value': 'bicycle', 'label': 'Bicycle'},
    {'value': 'car', 'label': 'Car'},
  ];

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _vehiclePlateController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  void _initializeData(UserModel user, DriverProfileModel driver) {
    if (_isInitialized) return;

    _displayNameController.text = user.displayName ?? '';
    _phoneController.text = user.phoneNumber ?? '';
    _vehicleType = driver.vehicleType;
    _vehiclePlateController.text = driver.vehiclePlateNumber ?? '';
    _licenseNumberController.text = driver.licenseNumber ?? '';

    _isInitialized = true;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userRepo = ref.read(userRepositoryProvider);
      final driverRepo = ref.read(driverProfileRepositoryProvider);

      // Update user profile
      await userRepo.updateUser(currentUser.id, {
        'displayName': _displayNameController.text.trim(),
        'phoneNumber': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update driver profile
      await driverRepo.updateDriverProfile(currentUser.id, {
        'vehicleType': _vehicleType,
        'vehiclePlateNumber': _vehiclePlateController.text.trim().isNotEmpty
            ? _vehiclePlateController.text.trim()
            : null,
        'licenseNumber': _licenseNumberController.text.trim().isNotEmpty
            ? _licenseNumberController.text.trim()
            : null,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );

      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final userAsync = ref.watch(streamUserByIdProvider(currentUser.id));
    final driverAsync = ref.watch(streamDriverProfileByUserIdProvider(currentUser.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return driverAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
            data: (driver) {
              if (driver == null) {
                return const Center(child: Text('Driver profile not found'));
              }

              _initializeData(user, driver);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information Section
                      Text(
                        'Personal Information',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      TextFormField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Your Name *',
                          prefixIcon: Icon(Icons.person_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Vehicle Information Section
                      Text(
                        'Vehicle Information',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      DropdownButtonFormField<String>(
                        value: _vehicleType,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Type *',
                          prefixIcon: Icon(Icons.two_wheeler),
                        ),
                        items: _vehicleTypes.map((type) {
                          return DropdownMenuItem(
                            value: type['value'],
                            child: Text(type['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _vehicleType = value);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      TextFormField(
                        controller: _vehiclePlateController,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Plate Number',
                          prefixIcon: Icon(Icons.confirmation_number_outlined),
                          hintText: 'e.g., ABC 1234',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      TextFormField(
                        controller: _licenseNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Driver License Number',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
