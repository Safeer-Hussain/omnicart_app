import 'package:flutter_test/flutter_test.dart';
import 'package:omni_cart_app/core/constants/app_constants.dart';
import 'package:omni_cart_app/core/utils/haversine.dart';

void main() {
  group('Haversine Geofencing & ETA Calculations', () {
    test('Calculates accurate distance between known city coordinates', () {
      final distance = HaversineUtil.distanceInKm(
        AppConstants.darkStoreLatitude,
        AppConstants.darkStoreLongitude,
        AppConstants.defaultCustomerLatitude,
        AppConstants.defaultCustomerLongitude,
      );

      // Distance between Gulberg Hub (31.5204, 74.3587) and DHA Phase 5 (31.4697, 74.3980) is ~6.8-7.0 km
      expect(distance, greaterThan(6.0));
      expect(distance, lessThan(8.0));
    });

    test('Identical coordinates yield zero distance and zero ETA minutes', () {
      final distance = HaversineUtil.distanceInKm(31.50, 74.35, 31.50, 74.35);
      expect(distance, 0.0);

      final eta = HaversineUtil.estimatedDeliveryMinutes(distance);
      expect(eta, 0);
    });

    test(
      'Estimated delivery minutes clamps realistic courier transit times',
      () {
        // 5 km at 32 km/h is ~9.3 minutes -> rounded to 10 mins
        final eta5km = HaversineUtil.estimatedDeliveryMinutes(5.0);
        expect(eta5km, equals(10));

        // 0.02 km yields 0 mins (arrived)
        final etaNearZero = HaversineUtil.estimatedDeliveryMinutes(0.02);
        expect(etaNearZero, equals(0));

        // Large distance clamps to 45 mins maximum
        final etaMax = HaversineUtil.estimatedDeliveryMinutes(100.0);
        expect(etaMax, equals(45));
      },
    );

    test('Calculates valid initial navigation bearing [0, 360) degrees', () {
      final bearing = HaversineUtil.bearingBetween(
        AppConstants.darkStoreLatitude,
        AppConstants.darkStoreLongitude,
        AppConstants.defaultCustomerLatitude,
        AppConstants.defaultCustomerLongitude,
      );

      // Heading south-east from Gulberg to DHA Phase 5
      expect(bearing, greaterThanOrEqualTo(0.0));
      expect(bearing, lessThan(360.0));
      expect(bearing, greaterThan(90.0)); // In South-East quadrant
      expect(bearing, lessThan(180.0));
    });

    test('findNearestDarkStore selects closest fulfillment center', () {
      // Coordinates right next to DHA Phase 6 Hub
      const nearDhaLat = 31.4590;
      const nearDhaLng = 74.4200;
      final nearestToDha = HaversineUtil.findNearestDarkStore(
        nearDhaLat,
        nearDhaLng,
      );
      expect(nearestToDha.id, equals('hub_dha_b2'));
      expect(nearestToDha.code, equals('HUB-DHA-02'));

      // Coordinates right next to Gulberg Hub
      const nearGulbergLat = 31.5200;
      const nearGulbergLng = 74.3580;
      final nearestToGulberg = HaversineUtil.findNearestDarkStore(
        nearGulbergLat,
        nearGulbergLng,
      );
      expect(nearestToGulberg.id, equals('hub_central_a1'));
      expect(nearestToGulberg.code, equals('HUB-GLB-01'));

      // Coordinates in Johar Town
      const nearJoharLat = 31.4680;
      const nearJoharLng = 74.2990;
      final nearestToJohar = HaversineUtil.findNearestDarkStore(
        nearJoharLat,
        nearJoharLng,
      );
      expect(nearestToJohar.id, equals('hub_johar_c3'));
      expect(nearestToJohar.code, equals('HUB-JHR-03'));
    });

    test('findNearestDarkStore throws ArgumentError on empty hubs list', () {
      expect(
        () => HaversineUtil.findNearestDarkStore(31.5, 74.3, []),
        throwsArgumentError,
      );
    });
  });
}
