import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_cart_app/presentation/catalog/notifiers/catalog_notifier.dart';

import '../helpers/mock_repositories.dart';

void main() {
  setUp(() {
    registerMockServices();
  });

  test('CatalogNotifier loads initial products cleanly', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(catalogProvider.notifier);
    await notifier.loadCatalog();

    final state = container.read(catalogProvider);
    expect(state.isLoading, isFalse);
    expect(state.allProducts.length, greaterThanOrEqualTo(24));
    expect(state.filteredProducts.length, greaterThanOrEqualTo(24));
  });

  test('CatalogNotifier filters products by category', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(catalogProvider.notifier);
    await notifier.loadCatalog();

    notifier.setCategory('Smart Home');
    final state = container.read(catalogProvider);
    expect(state.selectedCategory, 'Smart Home');
    expect(
      state.filteredProducts.every((p) => p.category == 'Smart Home'),
      isTrue,
    );
    expect(state.filteredProducts.isNotEmpty, isTrue);
  });

  test('CatalogNotifier searches by product name and UPC barcode', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(catalogProvider.notifier);
    await notifier.loadCatalog();

    notifier.setSearchQuery('OmniBuds');
    var state = container.read(catalogProvider);
    expect(state.filteredProducts.length, 1);
    expect(state.filteredProducts.first.name, contains('OmniBuds'));

    notifier.setSearchQuery('079452389104');
    state = container.read(catalogProvider);
    expect(state.filteredProducts.length, 1);
    expect(state.filteredProducts.first.upcBarcode, '079452389104');
  });

  test(
    'CatalogNotifier sorts products by price low-to-high and high-to-low',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(catalogProvider.notifier);
      await notifier.loadCatalog();

      notifier.setSort(CatalogSort.priceLowHigh);
      var state = container.read(catalogProvider);
      for (var i = 0; i < state.filteredProducts.length - 1; i++) {
        expect(
          state.filteredProducts[i].priceUsd <=
              state.filteredProducts[i + 1].priceUsd,
          isTrue,
        );
      }

      notifier.setSort(CatalogSort.priceHighLow);
      state = container.read(catalogProvider);
      for (var i = 0; i < state.filteredProducts.length - 1; i++) {
        expect(
          state.filteredProducts[i].priceUsd >=
              state.filteredProducts[i + 1].priceUsd,
          isTrue,
        );
      }
    },
  );

  test(
    'CatalogNotifier instantly toggles wishlist and updates count',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(catalogProvider.notifier);
      await notifier.loadCatalog();

      final product = container.read(catalogProvider).allProducts.first;
      expect(product.isWishlisted, isFalse);

      await notifier.toggleWishlist(product.id);
      var state = container.read(catalogProvider);
      expect(
        state.allProducts.firstWhere((p) => p.id == product.id).isWishlisted,
        isTrue,
      );
      expect(state.wishlistCount, 1);

      await notifier.toggleWishlist(product.id);
      state = container.read(catalogProvider);
      expect(
        state.allProducts.firstWhere((p) => p.id == product.id).isWishlisted,
        isFalse,
      );
      expect(state.wishlistCount, 0);
    },
  );
}
