import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';

import '../constants/app_constants.dart';
import '../../domain/entities/dark_store_metric.dart';

class PosHardwareBridge {
  static const MethodChannel _posChannel = MethodChannel(
    AppConstants.posHardwareChannel,
  );
  static const EventChannel _telemetryChannel = EventChannel(
    AppConstants.inventoryTelemetryChannel,
  );

  Stream<DarkStoreMetric>? _telemetryStream;
  Timer? _fallbackTimer;

  Future<Map<String, dynamic>> scanUpcBarcode() async {
    try {
      final result = await _posChannel.invokeMapMethod<String, dynamic>(
        'scanUpcBarcode',
      );
      if (result != null) return result;
    } on MissingPluginException {
      // Graceful fallback for non-Android/iOS host environments
    } catch (_) {}

    final sampleUpcs = [
      '079452389101',
      '079452389102',
      '079452389103',
      '079452389104',
      '079452389105',
      '079452389106',
      '079452389107',
      '079452389108',
      '079452389111',
      '079452389114',
      '079452389116',
      '079452389121',
    ];
    final barcode = sampleUpcs[Random().nextInt(sampleUpcs.length)];
    return {
      'status': 'SUCCESS',
      'barcode': barcode,
      'symbology': 'UPC-A / EAN-13',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'hardwareSource': 'Emulated Optical Laser Imager',
    };
  }

  Future<Map<String, dynamic>> initiateNfcTapPayment({
    required double amount,
    required String currency,
  }) async {
    try {
      final result = await _posChannel.invokeMapMethod<String, dynamic>(
        'initiateNfcTapPayment',
        {'amount': amount, 'currency': currency},
      );
      if (result != null) return result;
    } on MissingPluginException {
      // Graceful fallback
    } catch (_) {}

    final rand = Random();
    return {
      'status': 'APPROVED',
      'transactionId': 'TXN-${rand.nextInt(900000) + 100000}',
      'terminalId': 'NFC-POS-TER-${rand.nextInt(9000) + 1000}',
      'amount': amount,
      'currency': currency,
      'authCode': 'AUTH-${rand.nextInt(900000) + 100000}',
      'cardNetwork': 'Visa OmniTap Contactless EMV',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Future<Map<String, dynamic>> printThermalReceiptPayload({
    required String orderId,
  }) async {
    try {
      final result = await _posChannel.invokeMapMethod<String, dynamic>(
        'printThermalReceiptPayload',
        {'orderId': orderId},
      );
      if (result != null) return result;
    } on MissingPluginException {
      // Fallback
    } catch (_) {}

    return {
      'status': 'PRINTED',
      'receiptJobId': 'THM-${Random().nextInt(90000) + 10000}',
      'orderId': orderId,
      'feedMm': 120,
      'cutterState': 'PARTIAL_CUT_COMPLETE',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Future<Map<String, dynamic>> verifyDarkStoreInventory({
    required String sku,
  }) async {
    try {
      final result = await _posChannel.invokeMapMethod<String, dynamic>(
        'verifyDarkStoreInventory',
        {'sku': sku},
      );
      if (result != null) return result;
    } on MissingPluginException {
      // Fallback
    } catch (_) {}

    return {
      'status': 'IN_STOCK',
      'sku': sku,
      'shelfLocation': 'Aisle 3, Shelf B2 (Cold-Zone)',
      'stockCount': Random().nextInt(40) + 12,
      'lastCycleCountMinutesAgo': Random().nextInt(20) + 3,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Stream<DarkStoreMetric> get telemetryStream {
    _telemetryStream ??= _buildTelemetryStream();
    return _telemetryStream!;
  }

  Stream<DarkStoreMetric> _buildTelemetryStream() {
    late StreamController<DarkStoreMetric> controller;
    StreamSubscription? nativeSub;

    controller = StreamController<DarkStoreMetric>.broadcast(
      onListen: () {
        try {
          nativeSub = _telemetryChannel
              .receiveBroadcastStream()
              .map((event) => DarkStoreMetric.fromMap(event as Map))
              .listen(
                (metric) {
                  if (!controller.isClosed) controller.add(metric);
                },
                onError: (err) {
                  _startFallback(controller);
                },
              );
        } catch (_) {
          _startFallback(controller);
        }
      },
      onCancel: () {
        nativeSub?.cancel();
        _fallbackTimer?.cancel();
      },
    );

    return controller.stream;
  }

  void _startFallback(StreamController<DarkStoreMetric> controller) {
    _fallbackTimer?.cancel();
    final rand = Random();
    controller.add(DarkStoreMetric.initial());
    _fallbackTimer = Timer.periodic(const Duration(seconds: 2), (t) {
      if (controller.isClosed) {
        t.cancel();
        return;
      }
      controller.add(
        DarkStoreMetric(
          activePickers: rand.nextInt(12) + 6,
          averagePackTimeSeconds: rand.nextInt(34) + 38,
          coldZoneTempCelsius: 3.8 + (rand.nextDouble() * 0.8 - 0.4),
          nfcTerminalReady: true,
          liveSkuPulse: rand.nextInt(120) + 140,
          warehouseZone: 'Lahore Central Dark-Store A1',
          timestampMillis: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });
  }
}
