import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_cart_app/presentation/barcode_pos/notifiers/barcode_pos_notifier.dart';

import '../helpers/mock_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    registerMockServices();
  });

  test(
    'BarcodePosNotifier initializes with default telemetry and idle state',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(barcodePosProvider);

      expect(state.isScanning, isFalse);
      expect(state.isNfcProcessing, isFalse);
      expect(state.scannedBarcode, isNull);
      expect(state.matchedProduct, isNull);
      expect(state.liveTelemetry.activePickers, greaterThanOrEqualTo(0));
      expect(state.liveTelemetry.nfcTerminalReady, isTrue);
    },
  );

  test(
    'BarcodePosNotifier scans UPC barcode and matches catalog product',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(barcodePosProvider.notifier);
      await notifier.scanUpcBarcode();

      final state = container.read(barcodePosProvider);
      expect(state.isScanning, isFalse);
      expect(state.scannedBarcode, isNotNull);
      expect(state.matchedProduct, isNotNull);
      expect(state.scanFeedbackMessage, contains('Matched'));

      notifier.clearScan();
      final clearedState = container.read(barcodePosProvider);
      expect(clearedState.scannedBarcode, isNull);
      expect(clearedState.matchedProduct, isNull);
      expect(clearedState.scanFeedbackMessage, isNull);
    },
  );

  test(
    'BarcodePosNotifier initiates NFC tap payment and resets processing state',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(barcodePosProvider.notifier);
      final res = await notifier.initiateNfcTapToPay(
        amount: 149.99,
        currency: 'USD',
      );

      expect(res['status'], 'APPROVED');
      expect(res['authCode'], startsWith('AUTH-'));
      expect(res['amount'], 149.99);

      final state = container.read(barcodePosProvider);
      expect(state.isNfcProcessing, isFalse);
      expect(state.nfcResult, isNotNull);
    },
  );

  test(
    'BarcodePosNotifier triggers thermal receipt payload generation',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(barcodePosProvider.notifier);
      final receipt = await notifier.printThermalReceipt('ORD-8821');

      expect(receipt['status'], 'PRINTED');
      expect(receipt['orderId'], 'ORD-8821');
      expect(receipt['cutterState'], 'PARTIAL_CUT_COMPLETE');
    },
  );

  test('BarcodePosNotifier loads cold chain logs and maintains telemetry integrity', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(barcodePosProvider.notifier);
    await notifier.loadRecentColdChainLogs();

    final state = container.read(barcodePosProvider);
    expect(state.recentColdChainLogs, isNotNull);
  });
}
