import '../entities/product.dart';
import '../entities/review.dart';

abstract class CatalogRepository {
  Future<List<Product>> getProducts();
  Future<Product?> getProductById(String id);
  Future<Product?> getProductByUpc(String barcode);
  Future<void> toggleWishlist(String id, bool isWishlisted);
  Future<List<Review>> getReviews(String productId);
  Future<void> addReview(Review review);
}
