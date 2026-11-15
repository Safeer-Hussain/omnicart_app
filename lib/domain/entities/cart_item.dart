import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  final String selectedColor;
  final String selectedSize;
  final int quantity;
  final bool isSavedForLater;

  const CartItem({
    required this.id,
    required this.product,
    required this.selectedColor,
    required this.selectedSize,
    required this.quantity,
    this.isSavedForLater = false,
  });

  double get totalPriceUsd => product.priceUsd * quantity;

  CartItem copyWith({
    String? id,
    Product? product,
    String? selectedColor,
    String? selectedSize,
    int? quantity,
    bool? isSavedForLater,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedSize: selectedSize ?? this.selectedSize,
      quantity: quantity ?? this.quantity,
      isSavedForLater: isSavedForLater ?? this.isSavedForLater,
    );
  }
}
