import 'package:flutter_test/flutter_test.dart';
import 'package:omni_cart_app/domain/entities/cold_chain_log.dart';
import 'package:omni_cart_app/domain/repositories/cold_chain_repository.dart';

import '../helpers/mock_repositories.dart';

void main() {
  late ColdChainRepository repository;

  setUp(() {
    registerMockServices();
    repository = MockColdChainRepository();
  });

  group('ColdChainRepository & Entity Tests', () {
    test('ColdChainLog entity serializes to and from Map accurately', () {
      const log = ColdChainLog(
        id: 'CCL-99120',
        warehouseZone: 'Lahore Central Dark-Store A1',
        sensorId: 'SENSOR-CZ-01',
        temperatureCelsius: 4.6,
        isDeviation: true,
        activePickers: 14,
        timestampMillis: 1731800000000,
        status: 'DEVIATION_ALERT',
      );

      final map = log.toMap();
      expect(map['id'], 'CCL-99120');
      expect(map['warehouse_zone'], 'Lahore Central Dark-Store A1');
      expect(map['temperature_celsius'], 4.6);
      expect(map['is_deviation'], 1);
      expect(map['status'], 'DEVIATION_ALERT');

      final reconstructed = ColdChainLog.fromMap(map);
      expect(reconstructed.id, log.id);
      expect(reconstructed.temperatureCelsius, log.temperatureCelsius);
      expect(reconstructed.isDeviation, isTrue);
      expect(reconstructed.status, 'DEVIATION_ALERT');
    });

    test('ColdChainRepository records and retrieves recent logs', () async {
      const log1 = ColdChainLog(
        id: 'CCL-1',
        warehouseZone: 'Gulberg A1',
        sensorId: 'SENSOR-01',
        temperatureCelsius: 3.4,
        isDeviation: false,
        activePickers: 12,
        timestampMillis: 1000,
        status: 'OPTIMAL',
      );

      const log2 = ColdChainLog(
        id: 'CCL-2',
        warehouseZone: 'Gulberg A1',
        sensorId: 'SENSOR-01',
        temperatureCelsius: 4.8,
        isDeviation: true,
        activePickers: 14,
        timestampMillis: 2000,
        status: 'DEVIATION_ALERT',
      );

      await repository.recordLog(log1);
      await repository.recordLog(log2);

      final recent = await repository.getRecentLogs(limit: 10);
      expect(recent.length, equals(2));
      expect(recent.first.id, equals('CCL-2')); // Most recent first
    });

    test('ColdChainRepository accurately filters deviations', () async {
      const optimalLog = ColdChainLog(
        id: 'CCL-OPT',
        warehouseZone: 'DHA B2',
        sensorId: 'SENSOR-02',
        temperatureCelsius: 3.2,
        isDeviation: false,
        activePickers: 10,
        timestampMillis: 3000,
        status: 'OPTIMAL',
      );

      const deviationLog = ColdChainLog(
        id: 'CCL-DEV',
        warehouseZone: 'DHA B2',
        sensorId: 'SENSOR-02',
        temperatureCelsius: 5.1,
        isDeviation: true,
        activePickers: 10,
        timestampMillis: 4000,
        status: 'DEVIATION_ALERT',
      );

      await repository.recordLog(optimalLog);
      await repository.recordLog(deviationLog);

      final deviations = await repository.getDeviations();
      expect(deviations.length, equals(1));
      expect(deviations.first.id, equals('CCL-DEV'));
      expect(deviations.first.isDeviation, isTrue);
      expect(deviations.first.temperatureCelsius, greaterThan(4.0));
    });
  });
}
