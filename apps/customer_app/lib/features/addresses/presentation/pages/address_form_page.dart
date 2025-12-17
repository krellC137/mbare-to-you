import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';

/// Page for adding or editing an address
class AddressFormPage extends ConsumerStatefulWidget {
  const AddressFormPage({
    required this.userId,
    this.address,
    super.key,
  });

  final String userId;
  final AddressModel? address;

  @override
  ConsumerState<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends ConsumerState<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _suburbController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _additionalInfoController = TextEditingController();

  bool _isDefault = false;
  bool _isLoading = false;
  bool _isGettingLocation = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _streetController.text = widget.address!.street;
      _suburbController.text = widget.address!.suburb;
      _cityController.text = widget.address!.city;
      _provinceController.text = widget.address!.province ?? '';
      _postalCodeController.text = widget.address!.postalCode ?? '';
      _additionalInfoController.text = widget.address!.additionalInfo ?? '';
      _isDefault = widget.address!.isDefault;
      _latitude = widget.address!.latitude;
      _longitude = widget.address!.longitude;
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    _suburbController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are denied'),
              backgroundColor: AppColors.warning,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location captured successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final address = AddressModel(
      id: widget.address?.id,
      userId: widget.userId,
      street: _streetController.text.trim(),
      suburb: _suburbController.text.trim(),
      city: _cityController.text.trim(),
      province: _provinceController.text.trim().isEmpty
          ? null
          : _provinceController.text.trim(),
      postalCode: _postalCodeController.text.trim().isEmpty
          ? null
          : _postalCodeController.text.trim(),
      country: 'Zimbabwe',
      latitude: _latitude,
      longitude: _longitude,
      additionalInfo: _additionalInfoController.text.trim().isEmpty
          ? null
          : _additionalInfoController.text.trim(),
      isDefault: _isDefault,
      createdAt: widget.address?.createdAt,
    );

    final result = widget.address == null
        ? await ref.read(addressRepositoryProvider).addAddress(address)
        : await ref.read(addressRepositoryProvider).updateAddress(address);

    if (!mounted) return;

    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.address == null
                  ? 'Address added successfully'
                  : 'Address updated successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? 'Add Address' : 'Edit Address'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(
                  labelText: 'Street Address',
                  hintText: 'e.g., 123 Main Street',
                  prefixIcon: Icon(Icons.home),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter street address';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _suburbController,
                decoration: const InputDecoration(
                  labelText: 'Suburb',
                  hintText: 'e.g., Avondale',
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter suburb';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  hintText: 'e.g., Harare',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter city';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _provinceController,
                decoration: const InputDecoration(
                  labelText: 'Province (Optional)',
                  hintText: 'e.g., Harare Province',
                  prefixIcon: Icon(Icons.map),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _postalCodeController,
                decoration: const InputDecoration(
                  labelText: 'Postal Code (Optional)',
                  hintText: 'e.g., 00263',
                  prefixIcon: Icon(Icons.markunread_mailbox),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _additionalInfoController,
                decoration: const InputDecoration(
                  labelText: 'Additional Info (Optional)',
                  hintText: 'e.g., Gate code, apartment number',
                  prefixIcon: Icon(Icons.info_outline),
                ),
                maxLines: 2,
                enabled: !_isLoading,
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.my_location,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Location Coordinates',
                            style: AppTextStyles.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (_latitude != null && _longitude != null)
                        Text(
                          'Lat: ${_latitude!.toStringAsFixed(6)}, '
                          'Lng: ${_longitude!.toStringAsFixed(6)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        Text(
                          'No location set',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading || _isGettingLocation
                              ? null
                              : _getCurrentLocation,
                          icon: _isGettingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location),
                          label: Text(
                            _isGettingLocation
                                ? 'Getting Location...'
                                : 'Get Current Location',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                value: _isDefault,
                onChanged: _isLoading ? null : (value) {
                  setState(() => _isDefault = value);
                },
                title: const Text('Set as default address'),
                subtitle: const Text(
                  'This address will be used by default for deliveries',
                ),
                activeColor: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveAddress,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(widget.address == null ? 'Add Address' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
