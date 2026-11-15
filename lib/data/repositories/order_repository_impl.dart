import '../../domain/entities/delivery_address.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/local_database.dart';

class OrderRepositoryImpl implements OrderRepository {
  final AppDatabase database;

  OrderRepositoryImpl({required this.database});

  @override
  Future<List<CustomerOrder>> getOrders() async {
    return await database.getOrders();
  }

  @override
  Future<void> createOrder(CustomerOrder order) async {
    await database.insertOrder(order);
  }

  @override
  Future<void> updateOrderStatus(
    String orderId,
    OrderFulfillmentStatus status,
    double progress,
    double lat,
    double lng,
  ) async {
    await database.updateOrderStatus(orderId, status, progress, lat, lng);
  }

  @override
  Future<List<DeliveryAddress>> getAddresses() async {
    return await database.getAddresses();
  }

  @override
  Future<void> saveAddress(DeliveryAddress address) async {
    await database.insertAddress(address);
  }
}
