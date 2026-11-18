import 'package:shared_preferences/shared_preferences.dart';
import 'package:omni_cart_app/core/constants/seeded_catalog.dart';
import 'package:omni_cart_app/core/di/injection.dart';
import 'package:omni_cart_app/core/platform/pos_hardware_bridge.dart';
import 'package:omni_cart_app/domain/entities/cart_item.dart';
import 'package:omni_cart_app/domain/entities/cold_chain_log.dart';
import 'package:omni_cart_app/domain/entities/delivery_address.dart';
import 'package:omni_cart_app/domain/entities/exchange_rate.dart';
import 'package:omni_cart_app/domain/entities/order.dart';
import 'package:omni_cart_app/domain/entities/product.dart';
import 'package:omni_cart_app/domain/entities/review.dart';
import 'package:omni_cart_app/domain/repositories/cart_repository.dart';
import 'package:omni_cart_app/domain/repositories/catalog_repository.dart';
import 'package:omni_cart_app/domain/repositories/cold_chain_repository.dart';
import 'package:omni_cart_app/domain/repositories/fx_repository.dart';
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

class MockColdChainRepository implements ColdChainRepository {
  List<ColdChainLog> logs = [];

  @override
  Future<void> recordLog(ColdChainLog log) async {
    logs.insert(0, log);
  }

  @override
  Future<List<ColdChainLog>> getRecentLogs({int limit = 20}) async {
    return logs.take(limit).toList();
  }

  @override
  Future<List<ColdChainLog>> getDeviations() async {
    return logs.where((l) => l.isDeviation).toList();
  }
}

class MockFxRepository implements FxRepository {
  List<ExchangeRate> rates = List.from(ExchangeRate.defaultRates);

  @override
  Future<List<ExchangeRate>> getRates() async => List.from(rates);

  @override
  Future<ExchangeRate?> getRate(String currencyCode) async {
    try {
      return rates.firstWhere((r) => r.code == currencyCode.toUpperCase());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateRates(List<ExchangeRate> newRates) async {
    for (final nr in newRates) {
      final idx = rates.indexWhere((r) => r.code == nr.code);
      if (idx != -1) {
        rates[idx] = nr;
      } else {
        rates.add(nr);
      }
    }
  }

  @override
  Future<List<ExchangeRate>> syncLatestRates() async {
    return List.from(rates);
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

  if (sl.isRegistered<ColdChainRepository>()) {
    sl.unregister<ColdChainRepository>();
  }
  sl.registerSingleton<ColdChainRepository>(MockColdChainRepository());

  if (sl.isRegistered<FxRepository>()) {
    sl.unregister<FxRepository>();
  }
  sl.registerSingleton<FxRepository>(MockFxRepository());

  if (!sl.isRegistered<PosHardwareBridge>()) {
    sl.registerSingleton<PosHardwareBridge>(PosHardwareBridge());
  }
}
