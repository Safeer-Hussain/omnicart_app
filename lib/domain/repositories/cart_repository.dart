import '../entities/cart_item.dart';

abstract class CartRepository {
  Future<List<CartItem>> getCartItems();
  Future<void> saveCartItem(CartItem item);
  Future<void> removeCartItem(String id);
  Future<void> clearCart();
}
