import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_ui/mbare_ui.dart';

/// Vendors list page - Browse all vendors
class VendorsPage extends ConsumerStatefulWidget {
  const VendorsPage({super.key});

  @override
  ConsumerState<VendorsPage> createState() => _VendorsPageState();
}

class _VendorsPageState extends ConsumerState<VendorsPage>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';

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
    final vendorsAsync = ref.watch(streamApprovedVendorsProvider(limit: 100));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendors'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search vendors...',
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

          // Vendors list
          Expanded(
            child: vendorsAsync.when(
              data: (vendors) {
                // Filter by search query
                final filteredVendors =
                    _searchQuery.isEmpty
                        ? vendors
                        : vendors.where((vendor) {
                          return vendor.businessName.toLowerCase().contains(
                                _searchQuery,
                              ) ||
                              vendor.marketSection.toLowerCase().contains(
                                _searchQuery,
                              );
                        }).toList();

                if (filteredVendors.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'No vendors found for "$_searchQuery"'
                          : 'No vendors available',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: 100, // Extra space for bottom nav bar
                  ),
                  itemCount: filteredVendors.length,
                  itemBuilder: (context, index) {
                    final vendor = filteredVendors[index];
                    return _VendorCard(vendor: vendor);
                  },
                );
              },
              loading: () => const Center(child: SmallLoadingIndicator()),
              error:
                  (error, stack) => Center(
                    child: Text(
                      'Error loading vendors: $error',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
            ),
          ),
        ],
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
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => context.push('/vendor/${vendor.id}'),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Vendor logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child:
                    vendor.logoUrl != null && vendor.logoUrl!.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                          child: Image.network(
                            vendor.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.store,
                                  size: 40,
                                  color: AppColors.textSecondary,
                                ),
                              );
                            },
                          ),
                        )
                        : const Center(
                          child: Icon(
                            Icons.store,
                            size: 40,
                            color: AppColors.textSecondary,
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
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                        Expanded(
                          child: Text(
                            '${vendor.marketSection} - Table ${vendor.tableNumber}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
                          vendor.rating.toStringAsFixed(1),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '(${vendor.totalReviews} reviews)',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow icon
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
