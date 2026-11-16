import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_cart_app/domain/entities/order.dart';
import 'package:omni_cart_app/presentation/courier_tracker/notifiers/order_tracker_notifier.dart';

import '../helpers/mock_repositories.dart';

void main() {
  setUp(() {
    registerMockServices();
  });

  test(
    'OrderTrackerNotifier loads orders and initializes delivery route state',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(orderTrackerProvider.notifier);
      await notifier.loadOrders();

      final state = container.read(orderTrackerProvider);
      expect(state.orders.isNotEmpty, isTrue);
      expect(state.selectedOrder, isNotNull);
      expect(state.originHub, isNotNull);
      expect(state.originHub.code, isNotEmpty);
      expect(state.courierBearingDegrees, greaterThanOrEqualTo(0));
      expect(state.remainingDistanceKm, greaterThan(0));
      expect(state.estimatedMinutesRemaining, greaterThan(0));
    },
  );

  test('OrderTrackerNotifier toggles delivery simulation cleanly', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(orderTrackerProvider.notifier);
    await notifier.loadOrders();

    expect(container.read(orderTrackerProvider).isSimulatingDelivery, isFalse);

    notifier.toggleSimulateDelivery();
    expect(container.read(orderTrackerProvider).isSimulatingDelivery, isTrue);

    notifier.toggleSimulateDelivery();
    expect(container.read(orderTrackerProvider).isSimulatingDelivery, isFalse);
  });

  test('OrderTrackerNotifier correctly updates selected order', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(orderTrackerProvider.notifier);
    await notifier.loadOrders();

    final initialOrderId = container
        .read(orderTrackerProvider)
        .selectedOrder!
        .id;
    notifier.selectOrder(initialOrderId);

    expect(
      container.read(orderTrackerProvider).selectedOrder?.id,
      initialOrderId,
    );
  });

  test('OrderFulfillmentStatus steps and labels map accurately', () {
    expect(OrderFulfillmentStatus.confirmed.stepIndex, 0);
    expect(OrderFulfillmentStatus.picking.stepIndex, 1);
    expect(OrderFulfillmentStatus.inTransit.stepIndex, 2);
    expect(OrderFulfillmentStatus.delivered.stepIndex, 3);

    expect(OrderFulfillmentStatus.confirmed.label, 'Order Confirmed');
    expect(OrderFulfillmentStatus.inTransit.label, 'Courier En Route');
  });
}
