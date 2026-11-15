import 'package:flutter_test/flutter_test.dart';
import 'package:omni_cart_app/core/constants/app_constants.dart';

void main() {
  test('OmniCart configuration sanity check', () {
    expect(AppConstants.appName, 'OmniCart');
    expect(AppConstants.freeShippingThresholdUsd, 50.0);
    expect(AppConstants.posHardwareChannel, 'com.safeer.omnicart/pos_hardware');
    expect(
      AppConstants.inventoryTelemetryChannel,
      'com.safeer.omnicart/inventory_telemetry',
    );
  });
}
