import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_cart_app/core/constants/seeded_catalog.dart';
import 'package:omni_cart_app/presentation/cart_checkout/notifiers/cart_notifier.dart';

import '../helpers/mock_repositories.dart';

void main() {
  setUp(() {
    registerMockServices();
  });

  test('CartNotifier adds items and increments quantity correctly', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(cartProvider.notifier);
    final product = SeededCatalog.initialProducts.first;

    await notifier.addToCart(product, quantity: 2);
    var state = container.read(cartProvider);
    expect(state.items.length, 1);
    expect(state.totalItemCount, 2);
    expect(state.subtotalUsd, closeTo(product.priceUsd * 2, 0.01));

    await notifier.incrementQuantity(state.items.first.id);
    state = container.read(cartProvider);
    expect(state.totalItemCount, 3);
  });

  test(
    'CartNotifier decrements quantity and removes item when reaching zero',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);
      final product = SeededCatalog.initialProducts.first;

      await notifier.addToCart(product, quantity: 1);
      var state = container.read(cartProvider);
      expect(state.totalItemCount, 1);

      await notifier.decrementQuantity(state.items.first.id);
      state = container.read(cartProvider);
      expect(state.items.isEmpty, isTrue);
    },
  );

  test('CartNotifier removes item and supports undo recovery', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(cartProvider.notifier);
    final product = SeededCatalog.initialProducts.first;

    await notifier.addToCart(product, quantity: 1);
    final item = container.read(cartProvider).items.first;

    final removed = await notifier.removeItem(item.id);
    expect(container.read(cartProvider).items.isEmpty, isTrue);
    expect(removed?.id, item.id);

    await notifier.undoRemove(removed!);
    expect(container.read(cartProvider).items.length, 1);
  });

  test(
    'CartNotifier validates SAVE20, FREESHIP, and VIP15 promo codes',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);
      final product = SeededCatalog.initialProducts[0]; // $149.99

      await notifier.addToCart(product, quantity: 1);

      // Apply SAVE20
      final success20 = notifier.applyPromoCode('SAVE20');
      expect(success20, isTrue);
      var state = container.read(cartProvider);
      expect(state.appliedPromo?.code, 'SAVE20');
      expect(state.discountUsd, closeTo(149.99 * 0.20, 0.01));

      // Apply FREESHIP
      final successShip = notifier.applyPromoCode('FREESHIP');
      expect(successShip, isTrue);
      state = container.read(cartProvider);
      expect(state.shippingFeeUsd, 0.0);

      // Apply VIP15
      final success15 = notifier.applyPromoCode('VIP15');
      expect(success15, isTrue);
      state = container.read(cartProvider);
      expect(state.discountUsd, closeTo(149.99 * 0.15, 0.01));

      // Reject Invalid Code
      final invalid = notifier.applyPromoCode('INVALID_CODE');
      expect(invalid, isFalse);
      expect(container.read(cartProvider).promoError, isNotNull);
    },
  );

  test(
    'CartNotifier accurately computes free shipping threshold progress',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);
      final cheapItem = SeededCatalog.initialProducts.firstWhere(
        (p) => p.priceUsd < 50.0,
      );

      await notifier.addToCart(cheapItem, quantity: 1);
      var state = container.read(cartProvider);
      expect(state.shippingProgress, lessThan(1.0));
      expect(state.shippingFeeUsd, 4.99);

      final expensiveItem = SeededCatalog.initialProducts.firstWhere(
        (p) => p.priceUsd > 100.0,
      );
      await notifier.addToCart(expensiveItem, quantity: 1);
      state = container.read(cartProvider);
      expect(state.shippingProgress, 1.0);
      expect(state.shippingFeeUsd, 0.0);
    },
  );

  test('CartNotifier places checkout order and clears cart', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(cartProvider.notifier);
    final product = SeededCatalog.initialProducts.first;

    await notifier.addToCart(product, quantity: 2);
    final address = SeededCatalog.defaultAddresses.first;

    final order = await notifier.checkoutOrder(
      address: address,
      deliverySpeed: '15-Min Express Dark Store',
      paymentMethod: 'NFC Tap-to-Pay',
    );

    expect(order, isNotNull);
    expect(order?.items.length, 1);
    expect(order?.deliverySpeed, '15-Min Express Dark Store');
    expect(order?.paymentMethod, 'NFC Tap-to-Pay');
    expect(container.read(cartProvider).items.isEmpty, isTrue);
  });
}
