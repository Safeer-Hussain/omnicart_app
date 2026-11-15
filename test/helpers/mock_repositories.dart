import 'package:shared_preferences/shared_preferences.dart';
import 'package:omni_cart_app/core/constants/seeded_catalog.dart';
import 'package:omni_cart_app/core/di/injection.dart';
import 'package:omni_cart_app/core/platform/pos_hardware_bridge.dart';
import 'package:omni_cart_app/domain/entities/cart_item.dart';
import 'package:omni_cart_app/domain/entities/delivery_address.dart';
import 'package:omni_cart_app/domain/entities/order.dart';
import 'package:omni_cart_app/domain/entities/product.dart';
import 'package:omni_cart_app/domain/entities/review.dart';
import 'package:omni_cart_app/domain/repositories/cart_repository.dart';
import 'package:omni_cart_app/domain/repositories/catalog_repository.dart';
import 'package:omni_cart_app/domain/repositories/order_repository.dart';

class MockCatalogRepository implements CatalogRepository {
  List<Product> products = List.from(SeededCatalog.initialProducts);
  final Map<String, List<Review>> reviews = {};

  @override
  Future<List<Product>> getProducts() async => List.from(products);

  @override
  Future<Product?> getProductById(String id) async {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Product?> getProductByUpc(String barcode) async {
    try {
      return products.firstWhere((p) => p.upcBarcode == barcode);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> toggleWishlist(String id, bool isWishlisted) async {
    products = products.map((p) {
      if (p.id == id) {
        return p.copyWith(isWishlisted: isWishlisted);
      }
      return p;
    }).toList();
  }

  @override
  Future<List<Review>> getReviews(String productId) async {
    return reviews[productId] ??
        SeededCatalog.initialReviewsForProduct(productId);
  }

  @override
  Future<void> addReview(Review review) async {
    final list = reviews[review.productId] ?? [];
    list.add(review);
    reviews[review.productId] = list;
  }
}

class MockCartRepository implements CartRepository {
  List<CartItem> items = [];

  @override
  Future<List<CartItem>> getCartItems() async => List.from(items);

  @override
  Future<void> saveCartItem(CartItem item) async {
    final index = items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      items[index] = item;
    } else {
      items.add(item);
    }
  }

  @override
  Future<void> removeCartItem(String id) async {
    items.removeWhere((i) => i.id == id);
  }

  @override
  Future<void> clearCart() async {
    items.clear();
  }
}

class MockOrderRepository implements OrderRepository {
  List<CustomerOrder> orders = [];
  List<DeliveryAddress> addresses = List.from(SeededCatalog.defaultAddresses);

  @override
  Future<List<CustomerOrder>> getOrders() async => List.from(orders);

  @override
  Future<void> createOrder(CustomerOrder order) async {
    orders.insert(0, order);
  }

  @override
  Future<void> updateOrderStatus(
    String orderId,
    OrderFulfillmentStatus status,
    double progress,
    double lat,
    double lng,
  ) async {
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      orders[index] = orders[index].copyWith(
        status: status,
        courierProgress: progress,
        courierLat: lat,
        courierLng: lng,
      );
    }
  }

  @override
  Future<List<DeliveryAddress>> getAddresses() async => List.from(addresses);

  @override
  Future<void> saveAddress(DeliveryAddress address) async {
    addresses.add(address);
  }
}

void registerMockServices() {
  SharedPreferences.setMockInitialValues({});
  if (sl.isRegistered<CatalogRepository>()) {
    sl.unregister<CatalogRepository>();
  }
  sl.registerSingleton<CatalogRepository>(MockCatalogRepository());

  if (sl.isRegistered<CartRepository>()) {
    sl.unregister<CartRepository>();
  }
  sl.registerSingleton<CartRepository>(MockCartRepository());

  if (sl.isRegistered<OrderRepository>()) {
    sl.unregister<OrderRepository>();
  }
  sl.registerSingleton<OrderRepository>(MockOrderRepository());

  if (!sl.isRegistered<PosHardwareBridge>()) {
    sl.registerSingleton<PosHardwareBridge>(PosHardwareBridge());
  }
}
