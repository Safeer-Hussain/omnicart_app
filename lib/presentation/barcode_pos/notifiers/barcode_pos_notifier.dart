import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../core/platform/pos_hardware_bridge.dart';
import '../../../domain/entities/dark_store_metric.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/repositories/catalog_repository.dart';

class BarcodePosState {
  final bool isScanning;
  final String? scannedBarcode;
  final Product? matchedProduct;
  final DarkStoreMetric liveTelemetry;
  final bool isNfcProcessing;
  final Map<String, dynamic>? nfcResult;
  final String? scanFeedbackMessage;

  const BarcodePosState({
    this.isScanning = false,
    this.scannedBarcode,
    this.matchedProduct,
    required this.liveTelemetry,
    this.isNfcProcessing = false,
    this.nfcResult,
    this.scanFeedbackMessage,
  });

  factory BarcodePosState.initial() {
    return BarcodePosState(liveTelemetry: DarkStoreMetric.initial());
  }

  BarcodePosState copyWith({
    bool? isScanning,
    String? scannedBarcode,
    bool clearScannedBarcode = false,
    Product? matchedProduct,
    bool clearMatchedProduct = false,
    DarkStoreMetric? liveTelemetry,
    bool? isNfcProcessing,
    Map<String, dynamic>? nfcResult,
    bool clearNfcResult = false,
    String? scanFeedbackMessage,
    bool clearFeedbackMessage = false,
  }) {
    return BarcodePosState(
      isScanning: isScanning ?? this.isScanning,
      scannedBarcode: clearScannedBarcode
          ? null
          : (scannedBarcode ?? this.scannedBarcode),
      matchedProduct: clearMatchedProduct
          ? null
          : (matchedProduct ?? this.matchedProduct),
      liveTelemetry: liveTelemetry ?? this.liveTelemetry,
      isNfcProcessing: isNfcProcessing ?? this.isNfcProcessing,
      nfcResult: clearNfcResult ? null : (nfcResult ?? this.nfcResult),
      scanFeedbackMessage: clearFeedbackMessage
          ? null
          : (scanFeedbackMessage ?? this.scanFeedbackMessage),
    );
  }
}

class BarcodePosNotifier extends Notifier<BarcodePosState> {
  late final PosHardwareBridge _posBridge;
  late final CatalogRepository _catalogRepository;
  StreamSubscription<DarkStoreMetric>? _telemetrySub;

  @override
  BarcodePosState build() {
    _posBridge = sl<PosHardwareBridge>();
    _catalogRepository = sl<CatalogRepository>();

    _telemetrySub = _posBridge.telemetryStream.listen((metric) {
      state = state.copyWith(liveTelemetry: metric);
    });

    ref.onDispose(() {
      _telemetrySub?.cancel();
    });

    return BarcodePosState.initial();
  }

  Future<void> scanUpcBarcode() async {
    state = state.copyWith(isScanning: true, clearFeedbackMessage: true);
    try {
      final scanPayload = await _posBridge.scanUpcBarcode();
      final barcode = scanPayload['barcode'] as String? ?? '079452389101';

      final matched = await _catalogRepository.getProductByUpc(barcode);

      state = state.copyWith(
        isScanning: false,
        scannedBarcode: barcode,
        matchedProduct: matched,
        scanFeedbackMessage: matched != null
            ? 'Matched ${matched.name} in local dark-store database.'
            : 'Barcode $barcode detected. No catalog SKU matched.',
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        scanFeedbackMessage: 'Barcode scanner error: $e',
      );
    }
  }

  Future<Map<String, dynamic>> initiateNfcTapToPay({
    required double amount,
    required String currency,
  }) async {
    state = state.copyWith(isNfcProcessing: true, clearNfcResult: true);
    try {
      final res = await _posBridge.initiateNfcTapPayment(
        amount: amount,
        currency: currency,
      );
      state = state.copyWith(isNfcProcessing: false, nfcResult: res);
      return res;
    } finally {
      state = state.copyWith(isNfcProcessing: false);
    }
  }

  Future<Map<String, dynamic>> printThermalReceipt(String orderId) async {
    return await _posBridge.printThermalReceiptPayload(orderId: orderId);
  }

  void clearScan() {
    state = state.copyWith(
      clearScannedBarcode: true,
      clearMatchedProduct: true,
      clearFeedbackMessage: true,
      clearNfcResult: true,
    );
  }
}

final barcodePosProvider =
    NotifierProvider<BarcodePosNotifier, BarcodePosState>(
      BarcodePosNotifier.new,
    );
