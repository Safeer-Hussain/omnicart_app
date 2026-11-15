import '../entities/delivery_address.dart';
import '../entities/order.dart';

abstract class OrderRepository {
  Future<List<CustomerOrder>> getOrders();
  Future<void> createOrder(CustomerOrder order);
  Future<void> updateOrderStatus(
    String orderId,
    OrderFulfillmentStatus status,
    double progress,
    double lat,
    double lng,
  );
  Future<List<DeliveryAddress>> getAddresses();
  Future<void> saveAddress(DeliveryAddress address);
}
