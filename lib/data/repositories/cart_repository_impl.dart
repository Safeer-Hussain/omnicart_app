import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/local_database.dart';

class CartRepositoryImpl implements CartRepository {
  final AppDatabase database;

  CartRepositoryImpl({required this.database});

  @override
  Future<List<CartItem>> getCartItems() async {
    return await database.getCartItems();
  }

  @override
  Future<void> saveCartItem(CartItem item) async {
    await database.saveCartItem(item);
  }

  @override
  Future<void> removeCartItem(String id) async {
    await database.removeCartItem(id);
  }

  @override
  Future<void> clearCart() async {
    await database.clearCart();
  }
}
