import '../../domain/entities/product.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/local_database.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final AppDatabase database;

  CatalogRepositoryImpl({required this.database});

  @override
  Future<List<Product>> getProducts() async {
    return await database.getProducts();
  }

  @override
  Future<Product?> getProductById(String id) async {
    return await database.getProductById(id);
  }

  @override
  Future<Product?> getProductByUpc(String barcode) async {
    return await database.getProductByUpc(barcode);
  }

  @override
  Future<void> toggleWishlist(String id, bool isWishlisted) async {
    await database.updateWishlistStatus(id, isWishlisted);
  }

  @override
  Future<List<Review>> getReviews(String productId) async {
    return await database.getReviewsForProduct(productId);
  }

  @override
  Future<void> addReview(Review review) async {
    await database.insertReview(review);
  }
}
