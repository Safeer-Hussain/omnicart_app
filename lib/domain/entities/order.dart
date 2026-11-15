import 'cart_item.dart';
import 'delivery_address.dart';

enum OrderFulfillmentStatus { confirmed, picking, inTransit, delivered }

extension OrderFulfillmentStatusExtension on OrderFulfillmentStatus {
  String get label {
    switch (this) {
      case OrderFulfillmentStatus.confirmed:
        return 'Order Confirmed';
      case OrderFulfillmentStatus.picking:
        return 'Dark-Store Picking';
      case OrderFulfillmentStatus.inTransit:
        return 'Courier En Route';
      case OrderFulfillmentStatus.delivered:
        return 'Delivered';
    }
  }

  int get stepIndex {
    switch (this) {
      case OrderFulfillmentStatus.confirmed:
        return 0;
      case OrderFulfillmentStatus.picking:
        return 1;
      case OrderFulfillmentStatus.inTransit:
        return 2;
      case OrderFulfillmentStatus.delivered:
        return 3;
    }
  }
}

class CustomerOrder {
  final String id;
  final List<CartItem> items;
  final double subtotalUsd;
  final double discountUsd;
  final double taxUsd;
  final double shippingFeeUsd;
  final double totalUsd;
  final String? promoCode;
  final DeliveryAddress deliveryAddress;
  final String deliverySpeed; // '15-Min Express' or 'Standard Scheduled'
  final String
  paymentMethod; // 'NFC Tap-to-Pay', 'Vault Card', 'Cash on Delivery'
  final OrderFulfillmentStatus status;
  final String courierName;
  final String courierPhone;
  final double courierLat;
  final double courierLng;
  final double courierProgress; // 0.0 to 1.0
  final int createdAtMillis;

  const CustomerOrder({
    required this.id,
    required this.items,
    required this.subtotalUsd,
    required this.discountUsd,
    required this.taxUsd,
    required this.shippingFeeUsd,
    required this.totalUsd,
    this.promoCode,
    required this.deliveryAddress,
    required this.deliverySpeed,
    required this.paymentMethod,
    required this.status,
    required this.courierName,
    required this.courierPhone,
    required this.courierLat,
    required this.courierLng,
    required this.courierProgress,
    required this.createdAtMillis,
  });

  CustomerOrder copyWith({
    String? id,
    List<CartItem>? items,
    double? subtotalUsd,
    double? discountUsd,
    double? taxUsd,
    double? shippingFeeUsd,
    double? totalUsd,
    String? promoCode,
    DeliveryAddress? deliveryAddress,
    String? deliverySpeed,
    String? paymentMethod,
    OrderFulfillmentStatus? status,
    String? courierName,
    String? courierPhone,
    double? courierLat,
    double? courierLng,
    double? courierProgress,
    int? createdAtMillis,
  }) {
    return CustomerOrder(
      id: id ?? this.id,
      items: items ?? this.items,
      subtotalUsd: subtotalUsd ?? this.subtotalUsd,
      discountUsd: discountUsd ?? this.discountUsd,
      taxUsd: taxUsd ?? this.taxUsd,
      shippingFeeUsd: shippingFeeUsd ?? this.shippingFeeUsd,
      totalUsd: totalUsd ?? this.totalUsd,
      promoCode: promoCode ?? this.promoCode,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliverySpeed: deliverySpeed ?? this.deliverySpeed,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      courierName: courierName ?? this.courierName,
      courierPhone: courierPhone ?? this.courierPhone,
      courierLat: courierLat ?? this.courierLat,
      courierLng: courierLng ?? this.courierLng,
      courierProgress: courierProgress ?? this.courierProgress,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
    );
  }
}
