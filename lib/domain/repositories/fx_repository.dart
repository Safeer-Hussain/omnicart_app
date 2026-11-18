import '../entities/exchange_rate.dart';

abstract class FxRepository {
  Future<List<ExchangeRate>> getRates();
  Future<ExchangeRate?> getRate(String currencyCode);
  Future<void> updateRates(List<ExchangeRate> rates);
  Future<List<ExchangeRate>> syncLatestRates();
}
