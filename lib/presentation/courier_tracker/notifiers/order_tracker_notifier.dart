import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/seeded_catalog.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/haversine.dart';
import '../../../domain/entities/cart_item.dart';
import '../../../domain/entities/dark_store_hub.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/repositories/order_repository.dart';

class OrderTrackerState {
  final List<CustomerOrder> orders;
  final CustomerOrder? selectedOrder;
  final DarkStoreHub originHub;
  final bool isSimulatingDelivery;
  final double remainingDistanceKm;
  final int estimatedMinutesRemaining;
  final double currentCourierLat;
  final double currentCourierLng;
  final double courierBearingDegrees;
  final double simulationProgress; // 0.0 to 1.0

  const OrderTrackerState({
    required this.orders,
    this.selectedOrder,
    this.originHub = DarkStoreHub.defaultHub,
    this.isSimulatingDelivery = false,
    this.remainingDistanceKm = 8.4,
    this.estimatedMinutesRemaining = 15,
    this.currentCourierLat = AppConstants.darkStoreLatitude,
    this.currentCourierLng = AppConstants.darkStoreLongitude,
    this.courierBearingDegrees = 135.0,
    this.simulationProgress = 0.0,
  });

  factory OrderTrackerState.initial() {
    return const OrderTrackerState(orders: []);
  }

  OrderTrackerState copyWith({
    List<CustomerOrder>? orders,
    CustomerOrder? selectedOrder,
    bool clearSelectedOrder = false,
    DarkStoreHub? originHub,
    bool? isSimulatingDelivery,
    double? remainingDistanceKm,
    int? estimatedMinutesRemaining,
    double? currentCourierLat,
    double? currentCourierLng,
    double? courierBearingDegrees,
    double? simulationProgress,
  }) {
    return OrderTrackerState(
      orders: orders ?? this.orders,
      selectedOrder: clearSelectedOrder
          ? null
          : (selectedOrder ?? this.selectedOrder),
      originHub: originHub ?? this.originHub,
      isSimulatingDelivery: isSimulatingDelivery ?? this.isSimulatingDelivery,
      remainingDistanceKm: remainingDistanceKm ?? this.remainingDistanceKm,
      estimatedMinutesRemaining:
          estimatedMinutesRemaining ?? this.estimatedMinutesRemaining,
      currentCourierLat: currentCourierLat ?? this.currentCourierLat,
      currentCourierLng: currentCourierLng ?? this.currentCourierLng,
      courierBearingDegrees:
          courierBearingDegrees ?? this.courierBearingDegrees,
      simulationProgress: simulationProgress ?? this.simulationProgress,
    );
  }
}

class OrderTrackerNotifier extends Notifier<OrderTrackerState> {
  late final OrderRepository _repository;
  Timer? _simulationTimer;

  // Polyline waypoints between Lahore Gulberg Dark-Store and DHA Phase 5
  static const List<LatLng> deliveryRoute = [
    LatLng(31.5204, 74.3587), // Dark-Store Hub Gulberg
    LatLng(31.5120, 74.3645), // Main Boulevard
    LatLng(31.5015, 74.3720), // Kalma Chowk Overpass
    LatLng(31.4890, 74.3810), // Walton Road Junction
    LatLng(31.4780, 74.3890), // DHA Main Entrance
    LatLng(31.4697, 74.3980), // Customer Delivery Drop-Off DHA Phase 5
  ];

  @override
  OrderTrackerState build() {
    _repository = sl<OrderRepository>();
    ref.onDispose(() {
      _simulationTimer?.cancel();
    });
    return OrderTrackerState.initial();
  }

  Future<void> loadOrders() async {
    var orders = await _repository.getOrders();
    if (orders.isEmpty) {
      // Seed a realistic active order if none exist
      final sampleProduct = SeededCatalog.initialProducts.first;
      final seededOrder = CustomerOrder(
        id: 'ORD-89412',
        items: [
          CartItem(
            id: 'sample_item_1',
            product: sampleProduct,
            selectedColor: 'Obsidian Black',
            selectedSize: 'Standard Fit',
            quantity: 1,
          ),
        ],
        subtotalUsd: 149.99,
        discountUsd: 20.0,
        taxUsd: 6.50,
        shippingFeeUsd: 0.0,
        totalUsd: 136.49,
        promoCode: 'SAVE20',
        deliveryAddress: SeededCatalog.defaultAddresses.first,
        deliverySpeed: '15-Min Express Dark Store',
        paymentMethod: 'NFC Tap-to-Pay',
        status: OrderFulfillmentStatus.inTransit,
        courierName: 'Zubair Akram (OmniCart Express Rider #48)',
        courierPhone: '+92 312 4492019',
        courierLat: 31.5015,
        courierLng: 74.3720,
        courierProgress: 0.45,
        createdAtMillis: DateTime.now()
            .subtract(const Duration(minutes: 8))
            .millisecondsSinceEpoch,
      );

      await _repository.createOrder(seededOrder);
      orders = [seededOrder];
    }

    final activeOrder = orders.first;
    final nearestHub = HaversineUtil.findNearestDarkStore(
      activeOrder.courierLat,
      activeOrder.courierLng,
    );
    final dist = HaversineUtil.distanceInKm(
      activeOrder.courierLat,
      activeOrder.courierLng,
      AppConstants.defaultCustomerLatitude,
      AppConstants.defaultCustomerLongitude,
    );
    final eta = HaversineUtil.estimatedDeliveryMinutes(dist);
    final bearing = HaversineUtil.bearingBetween(
      activeOrder.courierLat,
      activeOrder.courierLng,
      AppConstants.defaultCustomerLatitude,
      AppConstants.defaultCustomerLongitude,
    );

    state = state.copyWith(
      orders: orders,
      selectedOrder: activeOrder,
      originHub: nearestHub,
      currentCourierLat: activeOrder.courierLat,
      currentCourierLng: activeOrder.courierLng,
      courierBearingDegrees: bearing,
      simulationProgress: activeOrder.courierProgress,
      remainingDistanceKm: dist,
      estimatedMinutesRemaining: eta,
    );
  }

  void selectOrder(String orderId) {
    final order = state.orders.firstWhere(
      (o) => o.id == orderId,
      orElse: () => state.orders.first,
    );
    final nearestHub = HaversineUtil.findNearestDarkStore(
      order.courierLat,
      order.courierLng,
    );
    final dist = HaversineUtil.distanceInKm(
      order.courierLat,
      order.courierLng,
      AppConstants.defaultCustomerLatitude,
      AppConstants.defaultCustomerLongitude,
    );
    final eta = HaversineUtil.estimatedDeliveryMinutes(dist);
    final bearing = HaversineUtil.bearingBetween(
      order.courierLat,
      order.courierLng,
      AppConstants.defaultCustomerLatitude,
      AppConstants.defaultCustomerLongitude,
    );

    state = state.copyWith(
      selectedOrder: order,
      originHub: nearestHub,
      currentCourierLat: order.courierLat,
      currentCourierLng: order.courierLng,
      courierBearingDegrees: bearing,
      simulationProgress: order.courierProgress,
      remainingDistanceKm: dist,
      estimatedMinutesRemaining: eta,
    );
  }

  void toggleSimulateDelivery() {
    if (state.isSimulatingDelivery) {
      _simulationTimer?.cancel();
      state = state.copyWith(isSimulatingDelivery: false);
    } else {
      state = state.copyWith(isSimulatingDelivery: true);
      _startSimulationLoop();
    }
  }

  void _startSimulationLoop() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1200), (
      timer,
    ) {
      if (!state.isSimulatingDelivery || state.selectedOrder == null) {
        timer.cancel();
        return;
      }

      var newProgress = state.simulationProgress + 0.05;
      if (newProgress > 1.0) {
        newProgress = 1.0;
        timer.cancel();
        state = state.copyWith(isSimulatingDelivery: false);
      }

      // Calculate courier position and bearing along route
      final pos = _interpolatePosition(newProgress);
      final dist = HaversineUtil.distanceInKm(
        pos.latitude,
        pos.longitude,
        AppConstants.defaultCustomerLatitude,
        AppConstants.defaultCustomerLongitude,
      );
      final eta = HaversineUtil.estimatedDeliveryMinutes(dist);
      final bearing = HaversineUtil.bearingBetween(
        pos.latitude,
        pos.longitude,
        AppConstants.defaultCustomerLatitude,
        AppConstants.defaultCustomerLongitude,
      );

      OrderFulfillmentStatus status = OrderFulfillmentStatus.confirmed;
      if (newProgress >= 1.0) {
        status = OrderFulfillmentStatus.delivered;
      } else if (newProgress >= 0.35) {
        status = OrderFulfillmentStatus.inTransit;
      } else if (newProgress >= 0.10) {
        status = OrderFulfillmentStatus.picking;
      }

      final updatedOrder = state.selectedOrder!.copyWith(
        status: status,
        courierProgress: newProgress,
        courierLat: pos.latitude,
        courierLng: pos.longitude,
      );

      final updatedOrders = state.orders.map((o) {
        return o.id == updatedOrder.id ? updatedOrder : o;
      }).toList();

      state = state.copyWith(
        orders: updatedOrders,
        selectedOrder: updatedOrder,
        currentCourierLat: pos.latitude,
        currentCourierLng: pos.longitude,
        courierBearingDegrees: bearing,
        simulationProgress: newProgress,
        remainingDistanceKm: dist,
        estimatedMinutesRemaining: eta,
      );

      _repository.updateOrderStatus(
        updatedOrder.id,
        status,
        newProgress,
        pos.latitude,
        pos.longitude,
      );
    });
  }

  LatLng _interpolatePosition(double t) {
    if (t <= 0) return deliveryRoute.first;
    if (t >= 1.0) return deliveryRoute.last;

    final totalSegments = deliveryRoute.length - 1;
    final scaled = t * totalSegments;
    final index = scaled.floor().clamp(0, totalSegments - 1);
    final frac = scaled - index;

    final p1 = deliveryRoute[index];
    final p2 = deliveryRoute[index + 1];

    final lat = p1.latitude + (p2.latitude - p1.latitude) * frac;
    final lng = p1.longitude + (p2.longitude - p1.longitude) * frac;

    return LatLng(lat, lng);
  }
}

final orderTrackerProvider =
    NotifierProvider<OrderTrackerNotifier, OrderTrackerState>(
      OrderTrackerNotifier.new,
    );
