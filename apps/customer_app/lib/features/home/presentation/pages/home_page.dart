import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';

/// Home page for customer app
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  final List<String> _categories = [
    'All',
    'Vegetables',
    'Fruits',
    'Meat',
    'Poultry',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MbareToYou'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not authenticated'));
          }

          return CustomScrollView(
            slivers: [
              // Welcome section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${user.displayName ?? "Customer"}!',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'What would you like to order today?',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon:
                          _searchQuery.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
              ),

              // Category filter
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected =
                          _selectedCategory == category ||
                          (_selectedCategory == null && category == 'All');
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory =
                                  selected && category != 'All'
                                      ? category
                                      : null;
                            });
                          },
                          backgroundColor: AppColors.surface,
                          selectedColor: AppColors.primary.withValues(
                            alpha: 0.2,
                          ),
                          checkmarkColor: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              // Quick actions
              SliverToBoxAdapter(child: _QuickActionsSection(userId: user.id)),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

              // Featured vendors section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Text(
                    'Featured Vendors',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              // Vendors horizontal list
              SliverToBoxAdapter(child: _FeaturedVendorsList()),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

              // Products section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Text(
                    _selectedCategory != null
                        ? '$_selectedCategory Products'
                        : 'All Products',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              // Products grid - using SliverGrid for lazy loading
              _ProductsGridSection(
                selectedCategory: _selectedCategory,
                searchQuery: _searchQuery,
              ),

              // Bottom padding to prevent content being hidden by bottom nav bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 100), // Extra space for nav bar
              ),
            ],
          );
        },
        loading: () => const Center(child: SmallLoadingIndicator()),
        error:
            (error, stack) => Center(
              child: Text(
                'Error: $error',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
      ),
    );
  }
}

/// Quick actions section with active orders badge
class _QuickActionsSection extends ConsumerWidget {
  const _QuickActionsSection({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only watch active orders count, not the entire stream
    final activeOrdersCount = ref.watch(
      streamOrdersByCustomerIdProvider(userId, limit: 10).select(
        (ordersAsync) => ordersAsync.when(
          data:
              (orders) =>
                  orders
                      .where(
                        (order) => !order.isDelivered && !order.isCancelled,
                      )
                      .length,
          loading: () => 0,
          error: (_, __) => 0,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionCard(
              icon: Icons.receipt_long,
              label: 'My Orders',
              badgeCount: activeOrdersCount,
              onTap: () => context.push('/orders'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.favorite_border,
              label: 'Favorites',
              onTap: () => context.push('/favorites'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Featured vendors horizontal list
class _FeaturedVendorsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsAsync = ref.watch(streamApprovedVendorsProvider(limit: 10));

    return vendorsAsync.when(
      data: (vendors) {
        if (vendors.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: Text('No vendors available yet')),
          );
        }

        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: vendors.length,
            itemBuilder: (context, index) {
              final vendor = vendors[index];
              return _VendorCard(vendor: vendor);
            },
          ),
        );
      },
      loading:
          () => const SizedBox(
            height: 200,
            child: Center(child: SmallLoadingIndicator()),
          ),
      error:
          (error, stack) => Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: Text(
                'Error loading vendors: $error',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ),
    );
  }
}

/// Products grid section using SliverGrid for better performance
class _ProductsGridSection extends ConsumerWidget {
  const _ProductsGridSection({
    this.selectedCategory,
    required this.searchQuery,
  });

  final String? selectedCategory;
  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(
      selectedCategory != null
          ? productsByCategoryProvider(selectedCategory!)
          : availableProductsProvider(limit: 30), // Reduced from 50 to 30
    );

    return productsAsync.when(
      data: (products) {
        // Filter by search query
        final filteredProducts =
            searchQuery.isEmpty
                ? products
                : products.where((product) {
                  return product.name.toLowerCase().contains(searchQuery) ||
                      (product.description?.toLowerCase().contains(
                            searchQuery,
                          ) ??
                          false);
                }).toList();

        if (filteredProducts.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Text(
                  searchQuery.isNotEmpty
                      ? 'No products found for "$searchQuery"'
                      : 'No products available',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }

        // Use SliverPadding + SliverGrid for proper lazy loading
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = filteredProducts[index];
              return _ProductCard(product: product);
            }, childCount: filteredProducts.length),
          ),
        );
      },
      loading:
          () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
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
    );
  }
}

/// Vendor card widget
class _VendorCard extends StatelessWidget {
  const _VendorCard({required this.vendor});

  final VendorModel vendor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: AppSpacing.md),
      child: Card(
        child: InkWell(
          onTap: () => context.push('/vendor/${vendor.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vendor logo
              Container(
                height: 100,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child:
                    vendor.logoUrl != null
                        ? CachedNetworkImage(
                          imageUrl: vendor.logoUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          memCacheWidth: 320, // Reduce memory usage
                          maxHeightDiskCache: 200,
                          placeholder:
                              (context, url) => const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => const Icon(
                                Icons.store,
                                size: 48,
                                color: AppColors.textSecondary,
                              ),
                        )
                        : const Center(
                          child: Icon(
                            Icons.store,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                        ),
              ),
              // Vendor info
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.businessName,
                      style: AppTextStyles.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          vendor.rating.toStringAsFixed(1),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '(${vendor.totalReviews})',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Product card widget
class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Container(
              height: 120,
              decoration: const BoxDecoration(color: AppColors.background),
              child:
                  product.images.isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: product.images.first,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        memCacheWidth: 240, // Reduce memory usage
                        maxHeightDiskCache: 240,
                        placeholder:
                            (context, url) => const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => const Center(
                              child: Icon(
                                Icons.shopping_bag,
                                size: 48,
                                color: AppColors.textSecondary,
                              ),
                            ),
                      )
                      : const Center(
                        child: Icon(
                          Icons.shopping_bag,
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
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}${product.unit != null ? '/${product.unit}' : ''}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (product.stockQuantity < 10)
                    Text(
                      'Low stock',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick action card widget
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 32, color: AppColors.primary),
                  if (badgeCount != null && badgeCount! > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          badgeCount! > 99 ? '99+' : '$badgeCount',
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
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
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
