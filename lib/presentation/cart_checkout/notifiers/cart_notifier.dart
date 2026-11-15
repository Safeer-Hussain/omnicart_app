import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../domain/entities/cart_item.dart';
import '../../../domain/entities/delivery_address.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/promo_code.dart';
import '../../../domain/repositories/cart_repository.dart';
import '../../../domain/repositories/order_repository.dart';

class CartState {
  final List<CartItem> items;
  final PromoCode? appliedPromo;
  final String? promoError;
  final bool isCheckingOut;
  final String? checkoutError;

  const CartState({
    required this.items,
    this.appliedPromo,
    this.promoError,
    this.isCheckingOut = false,
    this.checkoutError,
  });

  factory CartState.initial() {
    return const CartState(items: []);
  }

  List<CartItem> get activeItems =>
      items.where((i) => !i.isSavedForLater).toList();
  List<CartItem> get savedForLaterItems =>
      items.where((i) => i.isSavedForLater).toList();

  int get totalItemCount =>
      activeItems.fold(0, (sum, item) => sum + item.quantity);

  double get subtotalUsd =>
      activeItems.fold(0.0, (sum, item) => sum + item.totalPriceUsd);

  double get discountUsd {
    if (appliedPromo == null) return 0.0;
    if (appliedPromo!.discountPercent > 0) {
      return (subtotalUsd * (appliedPromo!.discountPercent / 100.0));
    }
    if (appliedPromo!.flatDiscountUsd > 0) {
      return appliedPromo!.flatDiscountUsd.clamp(0.0, subtotalUsd);
    }
    return 0.0;
  }

  double get shippingFeeUsd {
    if (activeItems.isEmpty) return 0.0;
    if (appliedPromo?.isFreeShipping == true) return 0.0;
    if (subtotalUsd >= AppConstants.freeShippingThresholdUsd) return 0.0;
    return 4.99;
  }

  double get taxUsd {
    final taxable = (subtotalUsd - discountUsd).clamp(0.0, double.infinity);
    return taxable * 0.05; // 5% retail sales tax
  }

  double get totalUsd {
    if (activeItems.isEmpty) return 0.0;
    final total = (subtotalUsd - discountUsd) + shippingFeeUsd + taxUsd;
    return total.clamp(0.0, double.infinity);
  }

  double get shippingProgress {
    if (subtotalUsd >= AppConstants.freeShippingThresholdUsd) return 1.0;
    return (subtotalUsd / AppConstants.freeShippingThresholdUsd).clamp(
      0.0,
      1.0,
    );
  }

  double get amountRemainingForFreeShipping {
    if (subtotalUsd >= AppConstants.freeShippingThresholdUsd) return 0.0;
    return AppConstants.freeShippingThresholdUsd - subtotalUsd;
  }

  CartState copyWith({
    List<CartItem>? items,
    PromoCode? appliedPromo,
    bool clearPromo = false,
    String? promoError,
    bool clearPromoError = false,
    bool? isCheckingOut,
    String? checkoutError,
    bool clearCheckoutError = false,
  }) {
    return CartState(
      items: items ?? this.items,
      appliedPromo: clearPromo ? null : (appliedPromo ?? this.appliedPromo),
      promoError: clearPromoError ? null : (promoError ?? this.promoError),
      isCheckingOut: isCheckingOut ?? this.isCheckingOut,
      checkoutError: clearCheckoutError
          ? null
          : (checkoutError ?? this.checkoutError),
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  late final CartRepository _cartRepository;
  late final OrderRepository _orderRepository;

  @override
  CartState build() {
    _cartRepository = sl<CartRepository>();
    _orderRepository = sl<OrderRepository>();
    return CartState.initial();
  }

  Future<void> loadCart() async {
    final items = await _cartRepository.getCartItems();
    if (items.isNotEmpty || state.items.isEmpty) {
      state = state.copyWith(items: items);
    }
  }

  Future<void> addToCart(
    Product product, {
    int quantity = 1,
    String? color,
    String? size,
  }) async {
    final selectedColor = color ?? product.selectedColor;
    final selectedSize = size ?? product.selectedSize;

    final existingIndex = state.items.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.selectedColor == selectedColor &&
          item.selectedSize == selectedSize &&
          !item.isSavedForLater,
    );

    if (existingIndex != -1) {
      final existing = state.items[existingIndex];
      final updated = existing.copyWith(quantity: existing.quantity + quantity);
      final updatedList = List<CartItem>.from(state.items);
      updatedList[existingIndex] = updated;
      state = state.copyWith(items: updatedList);
      await _cartRepository.saveCartItem(updated);
    } else {
      final newItem = CartItem(
        id: 'cart_${DateTime.now().millisecondsSinceEpoch}_${state.items.length}',
        product: product,
        selectedColor: selectedColor,
        selectedSize: selectedSize,
        quantity: quantity,
      );
      final updatedList = [...state.items, newItem];
      state = state.copyWith(items: updatedList);
      await _cartRepository.saveCartItem(newItem);
    }
  }

  Future<void> incrementQuantity(String cartItemId) async {
    final index = state.items.indexWhere((i) => i.id == cartItemId);
    if (index == -1) return;

    final item = state.items[index];
    final updated = item.copyWith(quantity: item.quantity + 1);
    final updatedList = List<CartItem>.from(state.items);
    updatedList[index] = updated;

    state = state.copyWith(items: updatedList);
    await _cartRepository.saveCartItem(updated);
  }

  Future<void> decrementQuantity(String cartItemId) async {
    final index = state.items.indexWhere((i) => i.id == cartItemId);
    if (index == -1) return;

    final item = state.items[index];
    if (item.quantity > 1) {
      final updated = item.copyWith(quantity: item.quantity - 1);
      final updatedList = List<CartItem>.from(state.items);
      updatedList[index] = updated;

      state = state.copyWith(items: updatedList);
      await _cartRepository.saveCartItem(updated);
    } else {
      await removeItem(cartItemId);
    }
  }

  Future<CartItem?> removeItem(String cartItemId) async {
    final index = state.items.indexWhere((i) => i.id == cartItemId);
    if (index == -1) return null;

    final removed = state.items[index];
    final updatedList = state.items.where((i) => i.id != cartItemId).toList();

    state = state.copyWith(items: updatedList);
    await _cartRepository.removeCartItem(cartItemId);
    return removed;
  }

  Future<void> undoRemove(CartItem item) async {
    final updatedList = [...state.items, item];
    state = state.copyWith(items: updatedList);
    await _cartRepository.saveCartItem(item);
  }

  Future<void> toggleSaveForLater(String cartItemId) async {
    final index = state.items.indexWhere((i) => i.id == cartItemId);
    if (index == -1) return;

    final item = state.items[index];
    final updated = item.copyWith(isSavedForLater: !item.isSavedForLater);
    final updatedList = List<CartItem>.from(state.items);
    updatedList[index] = updated;

    state = state.copyWith(items: updatedList);
    await _cartRepository.saveCartItem(updated);
  }

  bool applyPromoCode(String input) {
    final match = PromoCode.match(input);
    if (match != null) {
      state = state.copyWith(appliedPromo: match, clearPromoError: true);
      return true;
    } else {
      state = state.copyWith(
        promoError: 'Invalid promo code. Try SAVE20, FREESHIP, or VIP15.',
      );
      return false;
    }
  }

  void removePromoCode() {
    state = state.copyWith(clearPromo: true, clearPromoError: true);
  }

  Future<CustomerOrder?> checkoutOrder({
    required DeliveryAddress address,
    required String deliverySpeed,
    required String paymentMethod,
  }) async {
    if (state.activeItems.isEmpty) return null;

    state = state.copyWith(isCheckingOut: true, clearCheckoutError: true);

    try {
      final orderId =
          'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      final order = CustomerOrder(
        id: orderId,
        items: List.from(state.activeItems),
        subtotalUsd: state.subtotalUsd,
        discountUsd: state.discountUsd,
        taxUsd: state.taxUsd,
        shippingFeeUsd: state.shippingFeeUsd,
        totalUsd: state.totalUsd,
        promoCode: state.appliedPromo?.code,
        deliveryAddress: address,
        deliverySpeed: deliverySpeed,
        paymentMethod: paymentMethod,
        status: OrderFulfillmentStatus.confirmed,
        courierName: 'Zubair Akram (OmniCart Express Rider #48)',
        courierPhone: '+92 312 4492019',
        courierLat: AppConstants.darkStoreLatitude,
        courierLng: AppConstants.darkStoreLongitude,
        courierProgress: 0.0,
        createdAtMillis: DateTime.now().millisecondsSinceEpoch,
      );

      await _orderRepository.createOrder(order);

      // Keep saved for later items, remove checked out items
      final remaining = state.savedForLaterItems;
      await _cartRepository.clearCart();
      for (final s in remaining) {
        await _cartRepository.saveCartItem(s);
      }

      state = state.copyWith(
        items: remaining,
        clearPromo: true,
        clearPromoError: true,
        isCheckingOut: false,
      );

      return order;
    } catch (e) {
      state = state.copyWith(isCheckingOut: false, checkoutError: e.toString());
      return null;
    }
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);
