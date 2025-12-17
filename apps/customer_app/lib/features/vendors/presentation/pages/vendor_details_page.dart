import 'package:customer_app/features/cart/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';

/// Vendor details page showing vendor info and products
class VendorDetailsPage extends ConsumerStatefulWidget {
  const VendorDetailsPage({required this.vendorId, super.key});

  final String vendorId;

  @override
  ConsumerState<VendorDetailsPage> createState() => _VendorDetailsPageState();
}

class _VendorDetailsPageState extends ConsumerState<VendorDetailsPage> {
  Future<void> _toggleFavorite(String userId, String vendorId) async {
    final result = await ref.read(favoriteRepositoryProvider).toggleFavorite(
          userId: userId,
          itemId: vendorId,
          type: FavoriteType.vendor,
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
    final vendorAsync = ref.watch(streamVendorByIdProvider(widget.vendorId));
    final productsAsync = ref.watch(
      streamProductsByVendorIdProvider(widget.vendorId, limit: 50),
    );
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: vendorAsync.when(
        data: (vendor) {
          if (vendor == null) {
            return const Center(child: Text('Vendor not found'));
          }

          return CustomScrollView(
            slivers: [
              // App bar with vendor header
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                actions: [
                  // Favorite icon
                  currentUserAsync.when(
                    data: (user) {
                      if (user == null) return const SizedBox.shrink();
                      final isFavoriteAsync = ref.watch(
                        isFavoriteProvider(
                          user.id,
                          widget.vendorId,
                          FavoriteType.vendor,
                        ),
                      );
                      return isFavoriteAsync.when(
                        data: (isFav) => IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? AppColors.error : Colors.white,
                          ),
                          onPressed: () => _toggleFavorite(user.id, widget.vendorId),
                        ),
                        loading: () => const IconButton(
                          icon: Icon(Icons.favorite_border, color: Colors.white),
                          onPressed: null,
                        ),
                        error: (_, __) => const IconButton(
                          icon: Icon(Icons.favorite_border, color: Colors.white),
                          onPressed: null,
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    vendor.businessName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                  background:
                      vendor.logoUrl != null && vendor.logoUrl!.isNotEmpty
                          ? Image.network(
                            vendor.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                child: const Icon(
                                  Icons.store,
                                  size: 80,
                                  color: AppColors.primary,
                                ),
                              );
                            },
                          )
                          : Container(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.store,
                              size: 80,
                              color: AppColors.primary,
                            ),
                          ),
                ),
              ),

              // Vendor info section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rating and location
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            vendor.rating.toStringAsFixed(1),
                            style: AppTextStyles.titleMedium,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '(${vendor.totalReviews} reviews)',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            vendor.tableLocation,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      if (vendor.description != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text('About', style: AppTextStyles.titleMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          vendor.description!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],

                      if (vendor.phoneNumber != null ||
                          vendor.email != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text('Contact', style: AppTextStyles.titleMedium),
                        const SizedBox(height: AppSpacing.sm),
                        if (vendor.phoneNumber != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                vendor.phoneNumber!,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        if (vendor.email != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              const Icon(
                                Icons.email,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                vendor.email!,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ],

                      const SizedBox(height: AppSpacing.lg),
                      const Divider(),
                      const SizedBox(height: AppSpacing.md),

                      // Products section header
                      Text('Products', style: AppTextStyles.titleLarge),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),

              // Products grid
              productsAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xxl),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(height: AppSpacing.md),
                              Text(
                                'No products available yet',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = products[index];
                        return _ProductCard(product: product);
                      }, childCount: products.length),
                    ),
                  );
                },
                loading:
                    () => const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xxl),
                        child: Center(child: SmallLoadingIndicator()),
                      ),
                    ),
                error:
                    (error, stack) => SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Center(
                          child: Text(
                            'Error loading products: $error',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ),
                    ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          );
        },
        loading: () => const Center(child: SmallLoadingIndicator()),
        error:
            (error, stack) => Center(
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
                    'Error loading vendor',
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
}

/// Product card widget
class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider.notifier);
    final inCart = ref.watch(
      cartProvider.select((state) => state.items.containsKey(product.id)),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Expanded(
            child: Container(
              width: double.infinity,
              color: AppColors.background,
              child:
                  product.images.isNotEmpty && product.images.first.isNotEmpty
                      ? Image.network(
                        product.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: AppColors.textSecondary,
                          );
                        },
                      )
                      : const Icon(
                        Icons.shopping_basket,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
            ),
          ),

          // Product info
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppTextStyles.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                // Add to cart button or out of stock badge
                if (!product.isAvailable || product.stockQuantity <= 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Out of stock',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        cart.addItem(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} added to cart'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            inCart ? AppColors.success : AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                      ),
                      icon: Icon(
                        inCart ? Icons.check : Icons.add_shopping_cart,
                        size: 16,
                      ),
                      label: Text(
                        inCart ? 'In Cart' : 'Add',
                        style: const TextStyle(fontSize: 12),
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
