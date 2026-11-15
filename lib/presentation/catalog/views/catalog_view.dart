import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/catalog_notifier.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/product_card.dart';

class CatalogView extends ConsumerStatefulWidget {
  const CatalogView({super.key});

  @override
  ConsumerState<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends ConsumerState<CatalogView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final catalogState = ref.watch(catalogProvider);

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'fab_catalog_filter',
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        tooltip: 'Sort & Filter Catalog',
        onPressed: () {
          _showSortDialog(context, ref);
        },
        child: const Icon(Icons.sort),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products, SKU or UPC barcode...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(catalogProvider.notifier)
                                      .setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (val) {
                        ref.read(catalogProvider.notifier).setSearchQuery(val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.tune, size: 20),
                    tooltip: 'Sort Options',
                    onPressed: () => _showSortDialog(context, ref),
                  ),
                ],
              ),
            ),

            // Horizontal Categories
            const CategoryFilterBar(),
            const SizedBox(height: 8),

            // Live Catalog Status Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${catalogState.filteredProducts.length} items in Dark-Store A1',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite, color: colorScheme.error, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${catalogState.wishlistCount} Saved',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Product Grid
            Expanded(
              child: catalogState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : catalogState.filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No matching products found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(catalogProvider.notifier)
                                  .setCategory('All');
                              ref
                                  .read(catalogProvider.notifier)
                                  .setSearchQuery('');
                            },
                            child: const Text('Reset All Filters'),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isLandscape ? 4 : 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: 250,
                      ),
                      itemCount: catalogState.filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = catalogState.filteredProducts[index];
                        return ProductCard(product: product);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentSort = ref.read(catalogProvider).selectedSort;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Sort Catalog By',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Divider(color: colorScheme.outlineVariant),
              RadioListTile<CatalogSort>(
                title: const Text('Featured Highlights'),
                value: CatalogSort.featured,
                groupValue: currentSort,
                onChanged: (val) {
                  ref.read(catalogProvider.notifier).setSort(val!);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<CatalogSort>(
                title: const Text('Price: Low to High'),
                value: CatalogSort.priceLowHigh,
                groupValue: currentSort,
                onChanged: (val) {
                  ref.read(catalogProvider.notifier).setSort(val!);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<CatalogSort>(
                title: const Text('Price: High to Low'),
                value: CatalogSort.priceHighLow,
                groupValue: currentSort,
                onChanged: (val) {
                  ref.read(catalogProvider.notifier).setSort(val!);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<CatalogSort>(
                title: const Text('Top Customer Rating'),
                value: CatalogSort.topRated,
                groupValue: currentSort,
                onChanged: (val) {
                  ref.read(catalogProvider.notifier).setSort(val!);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<CatalogSort>(
                title: const Text('15-Min Express Delivery Only'),
                value: CatalogSort.express15Min,
                groupValue: currentSort,
                onChanged: (val) {
                  ref.read(catalogProvider.notifier).setSort(val!);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
