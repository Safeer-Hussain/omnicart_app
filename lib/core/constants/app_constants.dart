class AppConstants {
  static const String appName = 'OmniCart';
  static const String appVersion = 'v2.4.0-enterprise';
  static const String darkStoreLocationName = 'Lahore Central Dark-Store A1';
  static const double darkStoreLatitude = 31.5204;
  static const double darkStoreLongitude = 74.3587;
  static const double defaultCustomerLatitude = 31.4697;
  static const double defaultCustomerLongitude = 74.3980;

  static const double freeShippingThresholdUsd = 50.0;
  static const double freeShippingThresholdPkr = 14000.0;
  static const double usdToPkrRate = 280.0;

  static const String posHardwareChannel = 'com.safeer.omnicart/pos_hardware';
  static const String inventoryTelemetryChannel =
      'com.safeer.omnicart/inventory_telemetry';

  static const String prefThemeMode = 'omnicart_theme_mode';
  static const String prefCurrency = 'omnicart_currency';
  static const String prefSimulatedLatency = 'omnicart_simulated_latency';
  static const String prefForce503 = 'omnicart_force_503';
  static const String prefFlashSaleDiscount = 'omnicart_flash_sale_discount';
}
