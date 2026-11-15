import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/seeded_catalog.dart';
import '../../../core/di/injection.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/review.dart';
import '../../../domain/repositories/catalog_repository.dart';

enum CatalogSort {
  featured,
  priceLowHigh,
  priceHighLow,
  topRated,
  express15Min,
}

class CatalogState {
  final List<Product> allProducts;
  final List<Product> filteredProducts;
  final String selectedCategory;
  final String searchQuery;
  final CatalogSort selectedSort;
  final bool isLoading;

  const CatalogState({
    required this.allProducts,
    required this.filteredProducts,
    required this.selectedCategory,
    required this.searchQuery,
    required this.selectedSort,
    required this.isLoading,
  });

  factory CatalogState.initial() {
    return CatalogState(
      allProducts: List.from(SeededCatalog.initialProducts),
      filteredProducts: List.from(SeededCatalog.initialProducts),
      selectedCategory: 'All',
      searchQuery: '',
      selectedSort: CatalogSort.featured,
      isLoading: false,
    );
  }

  int get wishlistCount => allProducts.where((p) => p.isWishlisted).length;

  CatalogState copyWith({
    List<Product>? allProducts,
    List<Product>? filteredProducts,
    String? selectedCategory,
    String? searchQuery,
    CatalogSort? selectedSort,
    bool? isLoading,
  }) {
    return CatalogState(
      allProducts: allProducts ?? this.allProducts,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSort: selectedSort ?? this.selectedSort,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CatalogNotifier extends Notifier<CatalogState> {
  late final CatalogRepository _repository;

  @override
  CatalogState build() {
    _repository = sl<CatalogRepository>();
    return CatalogState.initial();
  }

  Future<void> loadCatalog() async {
    state = state.copyWith(isLoading: true);
    final products = await _repository.getProducts();
    final filtered = _applyFilters(
      products,
      state.selectedCategory,
      state.searchQuery,
      state.selectedSort,
    );
    state = state.copyWith(
      allProducts: products,
      filteredProducts: filtered,
      isLoading: false,
    );
  }

  void setCategory(String category) {
    final filtered = _applyFilters(
      state.allProducts,
      category,
      state.searchQuery,
      state.selectedSort,
    );
    state = state.copyWith(
      selectedCategory: category,
      filteredProducts: filtered,
    );
  }

  void setSearchQuery(String query) {
    final filtered = _applyFilters(
      state.allProducts,
      state.selectedCategory,
      query,
      state.selectedSort,
    );
    state = state.copyWith(searchQuery: query, filteredProducts: filtered);
  }

  void setSort(CatalogSort sort) {
    final filtered = _applyFilters(
      state.allProducts,
      state.selectedCategory,
      state.searchQuery,
      sort,
    );
    state = state.copyWith(selectedSort: sort, filteredProducts: filtered);
  }

  Future<void> toggleWishlist(String productId) async {
    final updatedList = state.allProducts.map((p) {
      if (p.id == productId) {
        final newWishlistStatus = !p.isWishlisted;
        return p.copyWith(isWishlisted: newWishlistStatus);
      }
      return p;
    }).toList();

    final filtered = _applyFilters(
      updatedList,
      state.selectedCategory,
      state.searchQuery,
      state.selectedSort,
    );

    state = state.copyWith(
      allProducts: updatedList,
      filteredProducts: filtered,
    );

    final target = updatedList.firstWhere((p) => p.id == productId);
    await _repository.toggleWishlist(productId, target.isWishlisted);
  }

  void updateProductVariant(String productId, {String? color, String? size}) {
    final updatedList = state.allProducts.map((p) {
      if (p.id == productId) {
        return p.copyWith(
          selectedColor: color ?? p.selectedColor,
          selectedSize: size ?? p.selectedSize,
        );
      }
      return p;
    }).toList();

    final filtered = _applyFilters(
      updatedList,
      state.selectedCategory,
      state.searchQuery,
      state.selectedSort,
    );

    state = state.copyWith(
      allProducts: updatedList,
      filteredProducts: filtered,
    );
  }

  Future<List<Review>> getReviews(String productId) async {
    return await _repository.getReviews(productId);
  }

  Future<void> addReview(Review review) async {
    await _repository.addReview(review);
    await loadCatalog();
  }

  List<Product> _applyFilters(
    List<Product> items,
    String category,
    String query,
    CatalogSort sort,
  ) {
    var result = items;

    // Filter by Category
    if (category != 'All') {
      result = result
          .where((p) => p.category.toLowerCase() == category.toLowerCase())
          .toList();
    }

    // Filter by Search Query
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.upcBarcode.contains(q);
      }).toList();
    }

    // Apply Sorting
    switch (sort) {
      case CatalogSort.featured:
        break; // Default order
      case CatalogSort.priceLowHigh:
        result.sort((a, b) => a.priceUsd.compareTo(b.priceUsd));
        break;
      case CatalogSort.priceHighLow:
        result.sort((a, b) => b.priceUsd.compareTo(a.priceUsd));
        break;
      case CatalogSort.topRated:
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case CatalogSort.express15Min:
        result = result.where((p) => p.isExpressDelivery).toList();
        break;
    }

    return result;
  }
}

final catalogProvider = NotifierProvider<CatalogNotifier, CatalogState>(
  CatalogNotifier.new,
);
