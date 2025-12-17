import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';

/// Search page for products and vendors
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query.toLowerCase().trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search products or vendors...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  autofocus: true,
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: const [
                  Tab(text: 'Products', icon: Icon(Icons.shopping_bag)),
                  Tab(text: 'Vendors', icon: Icon(Icons.store)),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProductSearchResults(searchQuery: _searchQuery),
          _VendorSearchResults(searchQuery: _searchQuery),
        ],
      ),
    );
  }
}

/// Product search results widget
class _ProductSearchResults extends ConsumerWidget {
  const _ProductSearchResults({required this.searchQuery});

  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(availableProductsProvider());

    return productsAsync.when(
      data: (List<ProductModel> products) {
        if (searchQuery.isEmpty) {
          return const _EmptySearchState(
            icon: Icons.search,
            message: 'Search for products',
            subtitle: 'Enter a search term to find products',
          );
        }

        final filteredProducts = products.where((ProductModel product) {
          return product.name.toLowerCase().contains(searchQuery) ||
              (product.description?.toLowerCase().contains(searchQuery) ?? false) ||
              product.category.toLowerCase().contains(searchQuery);
        }).toList();

        if (filteredProducts.isEmpty) {
          return const _EmptySearchState(
            icon: Icons.search_off,
            message: 'No products found',
            subtitle: 'Try a different search term',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/product/${product.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      // Product image placeholder
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                        ),
                        child: product.primaryImage != null
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.sm),
                                child: Image.network(
                                  product.primaryImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.shopping_bag,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.shopping_bag,
                                color: AppColors.primary,
                              ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              product.category,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
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
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) => Center(
        child: Text('Error loading products: $error'),
      ),
    );
  }
}

/// Vendor search results widget
class _VendorSearchResults extends ConsumerWidget {
  const _VendorSearchResults({required this.searchQuery});

  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsAsync = ref.watch(approvedVendorsProvider());

    return vendorsAsync.when(
      data: (List<VendorModel> vendors) {
        if (searchQuery.isEmpty) {
          return const _EmptySearchState(
            icon: Icons.search,
            message: 'Search for vendors',
            subtitle: 'Enter a search term to find vendors',
          );
        }

        final filteredVendors = vendors.where((VendorModel vendor) {
          return vendor.businessName.toLowerCase().contains(searchQuery) ||
              (vendor.description?.toLowerCase().contains(searchQuery) ??
                  false);
        }).toList();

        if (filteredVendors.isEmpty) {
          return const _EmptySearchState(
            icon: Icons.search_off,
            message: 'No vendors found',
            subtitle: 'Try a different search term',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: filteredVendors.length,
          itemBuilder: (context, index) {
            final vendor = filteredVendors[index];
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/vendor/${vendor.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      // Vendor image placeholder
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                        ),
                        child: vendor.logoUrl != null
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.sm),
                                child: Image.network(
                                  vendor.logoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.store,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.store,
                                color: AppColors.primary,
                              ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vendor.businessName,
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (vendor.description != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                vendor.description!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                Icon(
                                  vendor.isActive
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: 14,
                                  color: vendor.isActive
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  vendor.isActive ? 'Active' : 'Inactive',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: vendor.isActive
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
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
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) => Center(
        child: Text('Error loading vendors: $error'),
      ),
    );
  }
}

/// Empty search state widget
class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  final IconData icon;
  final String message;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
