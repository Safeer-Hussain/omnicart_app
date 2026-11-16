import 'dart:math';

import '../../domain/entities/dark_store_hub.dart';

class HaversineUtil {
  static const double _earthRadiusKm = 6371.0;

  static double distanceInKm(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final dLat = _degToRad(endLat - startLat);
    final dLng = _degToRad(endLng - startLng);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(startLat)) *
            cos(_degToRad(endLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (pi / 180.0);
  static double _radToDeg(double rad) => rad * (180.0 / pi);

  static int estimatedDeliveryMinutes(
    double remainingKm, {
    double averageSpeedKmh = 32.0,
  }) {
    if (remainingKm <= 0.05) return 0;
    final hours = remainingKm / averageSpeedKmh;
    final minutes = (hours * 60).ceil();
    return minutes.clamp(1, 45);
  }

  /// Calculates the initial navigation bearing (heading) in degrees [0, 360)
  /// from start coordinates towards destination coordinates.
  static double bearingBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final phi1 = _degToRad(startLat);
    final phi2 = _degToRad(endLat);
    final deltaLambda = _degToRad(endLng - startLng);

    final y = sin(deltaLambda) * cos(phi2);
    final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLambda);
    final theta = atan2(y, x);
    final bearing = (_radToDeg(theta) + 360.0) % 360.0;
    return bearing;
  }

  /// Determines the nearest dark-store fulfillment hub from available network hubs
  /// based on minimal geodesic Haversine distance.
  static DarkStoreHub findNearestDarkStore(
    double customerLat,
    double customerLng, [
    List<DarkStoreHub> hubs = DarkStoreHub.networkHubs,
  ]) {
    if (hubs.isEmpty) {
      throw ArgumentError('Dark store hubs list cannot be empty.');
    }

    DarkStoreHub nearest = hubs.first;
    double minDistance = distanceInKm(
      nearest.latitude,
      nearest.longitude,
      customerLat,
      customerLng,
    );

    for (int i = 1; i < hubs.length; i++) {
      final hub = hubs[i];
      final dist = distanceInKm(
        hub.latitude,
        hub.longitude,
        customerLat,
        customerLng,
      );
      if (dist < minDistance) {
        minDistance = dist;
        nearest = hub;
      }
    }

    return nearest;
  }
}
