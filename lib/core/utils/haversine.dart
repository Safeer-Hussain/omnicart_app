import 'dart:math';

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

  static int estimatedDeliveryMinutes(
    double remainingKm, {
    double averageSpeedKmh = 32.0,
  }) {
    if (remainingKm <= 0.05) return 0;
    final hours = remainingKm / averageSpeedKmh;
    final minutes = (hours * 60).ceil();
    return minutes.clamp(1, 45);
  }
}
