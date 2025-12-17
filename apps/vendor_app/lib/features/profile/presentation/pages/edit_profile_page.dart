import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';

/// Edit profile page for vendors
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

  // Business info
  final _businessNameController = TextEditingController();
  final _tableNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _marketSection = 'Section A';

  bool _isLoading = false;
  bool _isInitialized = false;

  final _marketSections = [
    'Section A',
    'Section B',
    'Section C',
    'Section D',
    'Section E',
  ];

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _tableNumberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeData(UserModel user, VendorModel vendor) {
    if (_isInitialized) return;

    _displayNameController.text = user.displayName ?? '';
    _phoneController.text = user.phoneNumber ?? '';
    _businessNameController.text = vendor.businessName;
    _tableNumberController.text = vendor.tableNumber;
    _descriptionController.text = vendor.description ?? '';
    _marketSection = vendor.marketSection;

    _isInitialized = true;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(authStateChangesProvider).value;
      if (currentUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userRepo = ref.read(userRepositoryProvider);
      final vendorRepo = ref.read(vendorRepositoryProvider);

      // Update user profile
      await userRepo.updateUser(currentUser.uid, {
        'displayName': _displayNameController.text.trim(),
        'phoneNumber': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update vendor profile
      await vendorRepo.updateVendor(currentUser.uid, {
        'businessName': _businessNameController.text.trim(),
        'tableNumber': _tableNumberController.text.trim(),
        'marketSection': _marketSection,
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
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
    final currentUser = ref.watch(authStateChangesProvider).value;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final userAsync = ref.watch(streamUserByIdProvider(currentUser.uid));
    final vendorAsync = ref.watch(streamVendorByIdProvider(currentUser.uid));

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

          return vendorAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
            data: (vendor) {
              if (vendor == null) {
                return const Center(child: Text('Vendor profile not found'));
              }

              _initializeData(user, vendor);

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

                      // Business Information Section
                      Text(
                        'Business Information',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      TextFormField(
                        controller: _businessNameController,
                        decoration: const InputDecoration(
                          labelText: 'Business Name *',
                          prefixIcon: Icon(Icons.store_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your business name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      TextFormField(
                        controller: _tableNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Table Number *',
                          prefixIcon: Icon(Icons.table_restaurant_outlined),
                          hintText: 'e.g., 12, A5',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your table number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      DropdownButtonFormField<String>(
                        value: _marketSection,
                        decoration: const InputDecoration(
                          labelText: 'Market Section *',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        items: _marketSections.map((section) {
                          return DropdownMenuItem(
                            value: section,
                            child: Text(section),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _marketSection = value);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description_outlined),
                          hintText: 'Describe what you sell...',
                          alignLabelWithHint: true,
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
