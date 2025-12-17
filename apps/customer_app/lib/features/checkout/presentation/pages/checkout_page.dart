import 'package:customer_app/features/cart/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';

/// Checkout page for placing orders
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _suburbController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedPaymentMethod = 'cash';
  bool _isPlacingOrder = false;
  AddressModel? _selectedAddress;
  bool _useNewAddress = false;
  bool _hasLoadedDefaultAddress = false;

  @override
  void dispose() {
    _streetController.dispose();
    _suburbController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadAddressIntoForm(AddressModel address) {
    _streetController.text = address.street;
    _suburbController.text = address.suburb;
    _cityController.text = address.city;
    setState(() {
      _selectedAddress = address;
      _useNewAddress = false;
    });
  }

  void _clearAddressForm() {
    _streetController.clear();
    _suburbController.clear();
    _cityController.clear();
    setState(() {
      _selectedAddress = null;
      _useNewAddress = true;
    });
  }

  /// Get current location coordinates
  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, return null
      return null;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      return null;
    }

    // Get current position
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      // Failed to get location
      return null;
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final cartState = ref.read(cartProvider);
      final currentUser = ref.read(authStateChangesProvider).value;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get platform settings for fee calculations
      final settingsRepository = ref.read(settingsRepositoryProvider);
      final settingsResult = await settingsRepository.getPlatformSettings();
      final settings = settingsResult.fold(
        (failure) => const PlatformSettingsModel(
          id: 'default',
          deliveryFeePercentage: 10.0,
          platformFeePercentage: 5.0,
        ),
        (settings) => settings,
      );

      // Get current location
      final position = await _getCurrentLocation();
      final latitude = position?.latitude ?? 0.0;
      final longitude = position?.longitude ?? 0.0;

      // Create delivery address
      final deliveryAddress = AddressModel(
        userId: currentUser.uid,
        street: _streetController.text.trim(),
        suburb: _suburbController.text.trim(),
        city: _cityController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        createdAt: DateTime.now(),
      );

      // Group items by vendor
      final itemsByVendor = <String, List<CartItemModel>>{};
      for (final cartItem in cartState.itemsList) {
        final vendorId = cartItem.product.vendorId;
        if (!itemsByVendor.containsKey(vendorId)) {
          itemsByVendor[vendorId] = [];
        }

        itemsByVendor[vendorId]!.add(
          CartItemModel(
            productId: cartItem.product.id,
            vendorId: vendorId,
            productName: cartItem.product.name,
            productImage: cartItem.product.images.isNotEmpty
                ? cartItem.product.images.first
                : null,
            quantity: cartItem.quantity,
            unitPrice: cartItem.product.price,
          ),
        );
      }

      // Create order for each vendor
      final orderRepository = ref.read(orderRepositoryProvider);

      for (final entry in itemsByVendor.entries) {
        final vendorId = entry.key;
        final items = entry.value;

        final subtotal = items.fold<double>(
          0,
          (sum, item) => sum + (item.unitPrice * item.quantity),
        );

        // Calculate fees using platform settings
        final deliveryFee = settings.calculateDeliveryFee(subtotal);
        final platformFee = settings.calculatePlatformFee(subtotal);
        final total = subtotal + deliveryFee;

        final order = OrderModel(
          id: '', // Will be generated by Firestore
          customerId: currentUser.uid,
          vendorId: vendorId,
          items: items,
          subtotal: subtotal,
          deliveryFee: deliveryFee,
          platformFee: platformFee,
          total: total,
          status: 'pending',
          paymentMethod: _selectedPaymentMethod,
          deliveryAddress: deliveryAddress,
          customerNotes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: DateTime.now(),
        );

        await orderRepository.createOrder(order);
      }

      // Clear cart after successful order
      ref.read(cartProvider.notifier).clear();

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate to home
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final settingsAsync = ref.watch(platformSettingsProvider);
    final currentUser = ref.watch(authStateChangesProvider).value;

    // Watch default address and load it automatically
    final defaultAddressAsync = currentUser != null
        ? ref.watch(defaultAddressProvider(currentUser.uid))
        : null;

    // Watch all user addresses for selection
    final userAddressesAsync = currentUser != null
        ? ref.watch(userAddressesProvider(currentUser.uid))
        : null;

    // Auto-load default address once
    defaultAddressAsync?.whenData((defaultAddress) {
      if (defaultAddress != null && !_hasLoadedDefaultAddress && !_useNewAddress) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadAddressIntoForm(defaultAddress);
            setState(() => _hasLoadedDefaultAddress = true);
          }
        });
      }
    });

    if (cartState.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Your cart is empty',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                onPressed: () => context.go('/home'),
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Saved Addresses Section
            if (userAddressesAsync != null)
              userAddressesAsync.when(
                data: (addresses) {
                  if (addresses.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Delivery Address',
                              style: AppTextStyles.titleLarge,
                            ),
                            if (_selectedAddress != null && !_useNewAddress)
                              TextButton.icon(
                                onPressed: _clearAddressForm,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('New Address'),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (!_useNewAddress && addresses.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(AppSpacing.sm),
                            ),
                            child: Column(
                              children: [
                                if (_selectedAddress != null)
                                  ListTile(
                                    leading: const Icon(
                                      Icons.location_on,
                                      color: AppColors.primary,
                                    ),
                                    title: Text(_selectedAddress!.street),
                                    subtitle: Text(_selectedAddress!.formattedAddress),
                                    trailing: PopupMenuButton<AddressModel>(
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: _loadAddressIntoForm,
                                      itemBuilder: (context) => addresses
                                          .map((address) => PopupMenuItem(
                                                value: address,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      address.street,
                                                      style: AppTextStyles.bodyMedium,
                                                    ),
                                                    Text(
                                                      address.shortAddress,
                                                      style: AppTextStyles.bodySmall
                                                          .copyWith(
                                                        color: AppColors.textSecondary,
                                                      ),
                                                    ),
                                                    if (address.isDefault)
                                                      Text(
                                                        'Default',
                                                        style: AppTextStyles.bodySmall
                                                            .copyWith(
                                                          color: AppColors.primary,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delivery Address', style: AppTextStyles.titleLarge),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery Address', style: AppTextStyles.titleLarge),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery Address', style: AppTextStyles.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),

            // Address Form (always shown, but pre-filled if address is selected)
            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(
                labelText: 'Street Address',
                hintText: 'Enter your street address',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your street address';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _suburbController,
              decoration: const InputDecoration(
                labelText: 'Suburb',
                hintText: 'Enter your suburb',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your suburb';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                hintText: 'Enter your city',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your city';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Delivery Notes (Optional)',
                hintText: 'Any special instructions',
                prefixIcon: Icon(Icons.note_outlined),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Payment Method Section
            Text('Payment Method', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            _PaymentMethodTile(
              value: 'cash',
              groupValue: _selectedPaymentMethod,
              title: 'Cash on Delivery',
              icon: Icons.money,
              onChanged: (value) {
                setState(() => _selectedPaymentMethod = value!);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _PaymentMethodTile(
              value: 'mobile_money',
              groupValue: _selectedPaymentMethod,
              title: 'Mobile Money',
              icon: Icons.phone_android,
              onChanged: (value) {
                setState(() => _selectedPaymentMethod = value!);
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // Order Summary Section
            Text('Order Summary', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items (${cartState.itemCount})',
                        style: AppTextStyles.bodyLarge,
                      ),
                      Text(
                        '\$${cartState.totalPrice.toStringAsFixed(2)}',
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
                        '\$5.00',
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
                        '\$${(cartState.totalPrice + 5.00).toStringAsFixed(2)}',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Place Order Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: PrimaryButton(
                onPressed: _isPlacingOrder ? null : _placeOrder,
                child: _isPlacingOrder
                    ? const SmallLoadingIndicator()
                    : const Text('Place Order'),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

/// Payment method selection tile
class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.icon,
    required this.onChanged,
  });

  final String value;
  final String groupValue;
  final String title;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
