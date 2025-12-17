import 'package:customer_app/core/navigation/main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';

/// Favorites page showing favorited vendors and products
class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage>
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
        title: const Text('My Favorites'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Products', icon: Icon(Icons.shopping_bag)),
            Tab(text: 'Vendors', icon: Icon(Icons.store)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FavoriteProductsTab(),
          _FavoriteVendorsTab(),
        ],
      ),
    );
  }
}

/// Tab showing favorite products
class _FavoriteProductsTab extends ConsumerWidget {
  const _FavoriteProductsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Please log in to view favorites'));
        }

        final favoritesAsync = ref.watch(
          userFavoritesByTypeProvider(user.id, FavoriteType.product),
        );

        return favoritesAsync.when(
          data: (favorites) {
            if (favorites.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No favorite products yet',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Start adding products to your favorites',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton(
                      onPressed: () {
                        // Pop the favorites page and navigate to Discover tab
                        context.pop();
                        ref.read(navigationIndexProvider.notifier).goToDiscover();
                      },
                      child: const Text('Browse Products'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final favorite = favorites[index];
                return _FavoriteProductCard(
                  productId: favorite.itemId,
                  userId: user.id,
                );
              },
            );
          },
          loading: () => const Center(child: SmallLoadingIndicator()),
          error: (error, stack) => Center(
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
                  'Error loading favorites',
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
        );
      },
      loading: () => const Center(child: SmallLoadingIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

/// Tab showing favorite vendors
class _FavoriteVendorsTab extends ConsumerWidget {
  const _FavoriteVendorsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Please log in to view favorites'));
        }

        final favoritesAsync = ref.watch(
          userFavoritesByTypeProvider(user.id, FavoriteType.vendor),
        );

        return favoritesAsync.when(
          data: (favorites) {
            if (favorites.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.store_outlined,
                      size: 80,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No favorite vendors yet',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Start adding vendors to your favorites',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton(
                      onPressed: () {
                        // Pop the favorites page and navigate to Vendors tab
                        context.pop();
                        ref.read(navigationIndexProvider.notifier).goToVendors();
                      },
                      child: const Text('Browse Vendors'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final favorite = favorites[index];
                return _FavoriteVendorCard(
                  vendorId: favorite.itemId,
                  userId: user.id,
                );
              },
            );
          },
          loading: () => const Center(child: SmallLoadingIndicator()),
          error: (error, stack) => Center(
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
                  'Error loading favorites',
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
        );
      },
      loading: () => const Center(child: SmallLoadingIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

/// Card for displaying a favorite product
class _FavoriteProductCard extends ConsumerWidget {
  const _FavoriteProductCard({
    required this.productId,
    required this.userId,
  });

  final String productId;
  final String userId;

  Future<void> _removeFavorite(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(favoriteRepositoryProvider).removeFavorite(
          userId: userId,
          itemId: productId,
          type: FavoriteType.product,
        );

    if (!context.mounted) return;

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
          const SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 1),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(streamProductByIdProvider(productId));

    return productAsync.when(
      data: (product) {
        if (product == null) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: InkWell(
            onTap: () => context.push('/product/$productId'),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: AppColors.background,
                      child: product.images.isNotEmpty &&
                              product.images.first.isNotEmpty
                          ? Image.network(
                              product.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.shopping_bag,
                                  size: 40,
                                  color: AppColors.textSecondary,
                                );
                              },
                            )
                          : const Icon(
                              Icons.shopping_bag,
                              size: 40,
                              color: AppColors.textSecondary,
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Product info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTextStyles.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          product.stockStatus,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: product.stockQuantity > 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Remove button
                  IconButton(
                    icon: const Icon(Icons.favorite, color: AppColors.error),
                    onPressed: () => _removeFavorite(context, ref),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: SmallLoadingIndicator(),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

/// Card for displaying a favorite vendor
class _FavoriteVendorCard extends ConsumerWidget {
  const _FavoriteVendorCard({
    required this.vendorId,
    required this.userId,
  });

  final String vendorId;
  final String userId;

  Future<void> _removeFavorite(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(favoriteRepositoryProvider).removeFavorite(
          userId: userId,
          itemId: vendorId,
          type: FavoriteType.vendor,
        );

    if (!context.mounted) return;

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
          const SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 1),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorAsync = ref.watch(streamVendorByIdProvider(vendorId));

    return vendorAsync.when(
      data: (vendor) {
        if (vendor == null) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: InkWell(
            onTap: () => context.push('/vendor/$vendorId'),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Vendor logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: AppColors.background,
                      child: vendor.logoUrl != null && vendor.logoUrl!.isNotEmpty
                          ? Image.network(
                              vendor.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.store,
                                  size: 40,
                                  color: AppColors.primary,
                                );
                              },
                            )
                          : const Icon(
                              Icons.store,
                              size: 40,
                              color: AppColors.primary,
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Vendor info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.businessName,
                          style: AppTextStyles.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              vendor.ratingDisplay,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
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
                      ],
                    ),
                  ),

                  // Remove button
                  IconButton(
                    icon: const Icon(Icons.favorite, color: AppColors.error),
                    onPressed: () => _removeFavorite(context, ref),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Card(
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: SmallLoadingIndicator(),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
