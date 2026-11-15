class DarkStoreMetric {
  final int activePickers;
  final int averagePackTimeSeconds;
  final double coldZoneTempCelsius;
  final bool nfcTerminalReady;
  final int liveSkuPulse;
  final String warehouseZone;
  final int timestampMillis;

  const DarkStoreMetric({
    required this.activePickers,
    required this.averagePackTimeSeconds,
    required this.coldZoneTempCelsius,
    required this.nfcTerminalReady,
    required this.liveSkuPulse,
    required this.warehouseZone,
    required this.timestampMillis,
  });

  factory DarkStoreMetric.fromMap(Map<dynamic, dynamic> map) {
    return DarkStoreMetric(
      activePickers: (map['activePickers'] as num?)?.toInt() ?? 12,
      averagePackTimeSeconds:
          (map['averagePackTimeSeconds'] as num?)?.toInt() ?? 48,
      coldZoneTempCelsius:
          (map['coldZoneTempCelsius'] as num?)?.toDouble() ?? 3.8,
      nfcTerminalReady: map['nfcTerminalReady'] as bool? ?? true,
      liveSkuPulse: (map['liveSkuPulse'] as num?)?.toInt() ?? 184,
      warehouseZone:
          (map['warehouseZone'] as String?) ?? 'Lahore Central Dark-Store A1',
      timestampMillis:
          (map['timestamp'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  static DarkStoreMetric initial() {
    return DarkStoreMetric(
      activePickers: 14,
      averagePackTimeSeconds: 52,
      coldZoneTempCelsius: 3.7,
      nfcTerminalReady: true,
      liveSkuPulse: 198,
      warehouseZone: 'Lahore Central Dark-Store A1',
      timestampMillis: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
