import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer_app/features/cart/providers/cart_provider.dart';
import 'package:customer_app/features/products/presentation/widgets/product_reviews_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';

/// Product details page
class ProductDetailsPage extends ConsumerStatefulWidget {
  const ProductDetailsPage({required this.productId, super.key});

  final String productId;

  @override
  ConsumerState<ProductDetailsPage> createState() =>
      _ProductDetailsPageState();
}

class _ProductDetailsPageState extends ConsumerState<ProductDetailsPage> {
  int _quantity = 1;

  void _incrementQuantity(int maxStock) {
    if (_quantity < maxStock) {
      setState(() {
        _quantity++;
      });
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _addToCart(ProductModel product) {
    ref.read(cartProvider.notifier).addItem(product, quantity: _quantity);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${product.name} to cart'),
        backgroundColor: AppColors.success,
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            context.push('/cart');
          },
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(String userId, String productId) async {
    final result = await ref.read(favoriteRepositoryProvider).toggleFavorite(
          userId: userId,
          itemId: productId,
          type: FavoriteType.product,
        );

    if (!mounted) return;

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
        // Success - no need to show message as the UI will update reactively
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productByIdProvider(widget.productId));
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          // Favorite icon
          currentUserAsync.when(
            data: (user) {
              if (user == null) return const SizedBox.shrink();
              return Consumer(
                builder: (context, ref, child) {
                  final isFavoriteAsync = ref.watch(
                    isFavoriteProvider(
                      user.id,
                      widget.productId,
                      FavoriteType.product,
                    ),
                  );
                  return isFavoriteAsync.when(
                    data: (isFav) => IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? AppColors.error : null,
                      ),
                      onPressed: () => _toggleFavorite(user.id, widget.productId),
                    ),
                    loading: () => const IconButton(
                      icon: Icon(Icons.favorite_border),
                      onPressed: null,
                    ),
                    error: (_, __) => const IconButton(
                      icon: Icon(Icons.favorite_border),
                      onPressed: null,
                    ),
                  );
                },
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Cart icon
          Consumer(
            builder: (context, ref, child) {
              final cartItemCount = ref.watch(
                cartProvider.select((state) => state.itemCount),
              );
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      context.push('/cart');
                    },
                  ),
                  if (cartItemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          cartItemCount > 99 ? '99+' : '$cartItemCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return const Center(
              child: Text('Product not found'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                Container(
                  height: 300,
                  width: double.infinity,
                  color: AppColors.background,
                  child: product.images.isNotEmpty && product.images.first.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.images.first,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) {
                            return const Center(
                              child: Icon(
                                Icons.shopping_bag,
                                size: 100,
                                color: AppColors.textSecondary,
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.shopping_bag,
                            size: 100,
                            color: AppColors.textSecondary,
                          ),
                        ),
                ),

                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name and category
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product.category,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Price
                      Row(
                        children: [
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: AppTextStyles.headlineLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (product.unit != null) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '/ ${product.unit}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Stock status
                      Row(
                        children: [
                          Icon(
                            product.stockQuantity > 10
                                ? Icons.check_circle
                                : product.stockQuantity > 0
                                    ? Icons.warning
                                    : Icons.cancel,
                            color: product.stockQuantity > 10
                                ? AppColors.success
                                : product.stockQuantity > 0
                                    ? AppColors.warning
                                    : AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            product.stockStatus,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: product.stockQuantity > 10
                                  ? AppColors.success
                                  : product.stockQuantity > 0
                                      ? AppColors.warning
                                      : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '(${product.stockQuantity} ${product.unit ?? 'units'} available)',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Description
                      if (product.description != null) ...[
                        Text(
                          'Description',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          product.description!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      // Vendor info
                      FutureBuilder<VendorModel?>(
                        future: ref
                            .read(vendorRepositoryProvider)
                            .getVendorById(product.vendorId)
                            .then(
                              (result) => result.fold(
                                (failure) => null,
                                (vendor) => vendor,
                              ),
                            ),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            final vendor = snapshot.data!;
                            return Card(
                              child: InkWell(
                                onTap: () {
                                  context.push('/vendor/${vendor.id}');
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Row(
                                    children: [
                                      // Vendor icon (avoid loading empty image URLs)
                                      vendor.logoUrl != null &&
                                              vendor.logoUrl!.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: CachedNetworkImage(
                                                imageUrl: vendor.logoUrl!,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    const SizedBox(
                                                      width: 40,
                                                      height: 40,
                                                      child: Center(
                                                        child: SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                errorWidget: (
                                                  context,
                                                  url,
                                                  error,
                                                ) {
                                                  return const Icon(
                                                    Icons.store,
                                                    size: 40,
                                                    color: AppColors.primary,
                                                  );
                                                },
                                              ),
                                            )
                                          : const Icon(
                                              Icons.store,
                                              size: 40,
                                              color: AppColors.primary,
                                            ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Sold by',
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            Text(
                                              vendor.businessName,
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.star,
                                                  size: 16,
                                                  color: AppColors.warning,
                                                ),
                                                const SizedBox(
                                                  width: AppSpacing.xs,
                                                ),
                                                Text(
                                                  vendor.ratingDisplay,
                                                  style: AppTextStyles.bodySmall,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Reviews section
                      ProductReviewsSection(productId: product.id),

                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: SmallLoadingIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Error loading product: $error',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: productAsync.maybeWhen(
        data: (product) {
          if (product == null || !product.isAvailable || product.stockQuantity <= 0) {
            return null;
          }

          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Quantity selector
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _decrementQuantity,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Text(
                            '$_quantity',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _incrementQuantity(product.stockQuantity),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // Add to cart button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _addToCart(product),
                      icon: const Icon(Icons.shopping_cart),
                      label: Text(
                        'Add to Cart - \$${(product.price * _quantity).toStringAsFixed(2)}',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }
}
