import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../core/platform/pos_hardware_bridge.dart';
import '../../../domain/entities/cold_chain_log.dart';
import '../../../domain/entities/dark_store_metric.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/repositories/catalog_repository.dart';
import '../../../domain/repositories/cold_chain_repository.dart';

class BarcodePosState {
  final bool isScanning;
  final String? scannedBarcode;
  final Product? matchedProduct;
  final DarkStoreMetric liveTelemetry;
  final bool isNfcProcessing;
  final Map<String, dynamic>? nfcResult;
  final String? scanFeedbackMessage;
  final bool hasColdChainAlert;
  final String? coldChainAlertMessage;
  final List<ColdChainLog> recentColdChainLogs;

  const BarcodePosState({
    this.isScanning = false,
    this.scannedBarcode,
    this.matchedProduct,
    required this.liveTelemetry,
    this.isNfcProcessing = false,
    this.nfcResult,
    this.scanFeedbackMessage,
    this.hasColdChainAlert = false,
    this.coldChainAlertMessage,
    this.recentColdChainLogs = const [],
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
    bool? hasColdChainAlert,
    String? coldChainAlertMessage,
    bool clearColdChainAlert = false,
    List<ColdChainLog>? recentColdChainLogs,
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
      hasColdChainAlert: hasColdChainAlert ?? this.hasColdChainAlert,
      coldChainAlertMessage: clearColdChainAlert
          ? null
          : (coldChainAlertMessage ?? this.coldChainAlertMessage),
      recentColdChainLogs: recentColdChainLogs ?? this.recentColdChainLogs,
    );
  }
}

class BarcodePosNotifier extends Notifier<BarcodePosState> {
  late final PosHardwareBridge _posBridge;
  late final CatalogRepository _catalogRepository;
  late final ColdChainRepository _coldChainRepository;
  StreamSubscription<DarkStoreMetric>? _telemetrySub;

  @override
  BarcodePosState build() {
    _posBridge = sl<PosHardwareBridge>();
    _catalogRepository = sl<CatalogRepository>();
    _coldChainRepository = sl<ColdChainRepository>();

    _telemetrySub = _posBridge.telemetryStream.listen((metric) {
      _processIncomingTelemetry(metric);
    });

    ref.onDispose(() {
      _telemetrySub?.cancel();
    });

    return BarcodePosState.initial();
  }

  void _processIncomingTelemetry(DarkStoreMetric metric) {
    final isDeviation =
        metric.coldZoneTempCelsius > 4.0 || metric.coldZoneTempCelsius < 1.0;

    final log = ColdChainLog(
      id: 'CCL-${DateTime.now().millisecondsSinceEpoch}',
      warehouseZone: metric.warehouseZone,
      sensorId: 'SENSOR-CZ-01',
      temperatureCelsius: metric.coldZoneTempCelsius,
      isDeviation: isDeviation,
      activePickers: metric.activePickers,
      timestampMillis: DateTime.now().millisecondsSinceEpoch,
      status: isDeviation ? 'DEVIATION_ALERT' : 'OPTIMAL',
    );

    _coldChainRepository.recordLog(log);

    final updatedLogs = [log, ...state.recentColdChainLogs].take(20).toList();

    state = state.copyWith(
      liveTelemetry: metric,
      hasColdChainAlert: isDeviation,
      coldChainAlertMessage: isDeviation
          ? 'Cold-chain deviation: ${metric.coldZoneTempCelsius.toStringAsFixed(1)} °C exceeds safe perishable threshold (1.0°C - 4.0°C).'
          : null,
      clearColdChainAlert: !isDeviation,
      recentColdChainLogs: updatedLogs,
    );
  }

  Future<void> loadRecentColdChainLogs() async {
    final logs = await _coldChainRepository.getRecentLogs(limit: 20);
    state = state.copyWith(recentColdChainLogs: logs);
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
