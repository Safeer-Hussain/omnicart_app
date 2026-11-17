class ColdChainLog {
  final String id;
  final String warehouseZone;
  final String sensorId;
  final double temperatureCelsius;
  final bool isDeviation;
  final int activePickers;
  final int timestampMillis;
  final String status;

  const ColdChainLog({
    required this.id,
    required this.warehouseZone,
    required this.sensorId,
    required this.temperatureCelsius,
    required this.isDeviation,
    required this.activePickers,
    required this.timestampMillis,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'warehouse_zone': warehouseZone,
      'sensor_id': sensorId,
      'temperature_celsius': temperatureCelsius,
      'is_deviation': isDeviation ? 1 : 0,
      'active_pickers': activePickers,
      'timestamp': timestampMillis,
      'status': status,
    };
  }

  factory ColdChainLog.fromMap(Map<String, dynamic> map) {
    return ColdChainLog(
      id: map['id'] as String,
      warehouseZone: map['warehouse_zone'] as String,
      sensorId: map['sensor_id'] as String,
      temperatureCelsius: (map['temperature_celsius'] as num).toDouble(),
      isDeviation: (map['is_deviation'] as int) == 1,
      activePickers: map['active_pickers'] as int,
      timestampMillis: map['timestamp'] as int,
      status: map['status'] as String,
    );
  }
}
