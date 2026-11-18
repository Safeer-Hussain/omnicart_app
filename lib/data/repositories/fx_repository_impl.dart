import '../../domain/entities/exchange_rate.dart';
import '../../domain/repositories/fx_repository.dart';
import '../datasources/local_database.dart';

class FxRepositoryImpl implements FxRepository {
  final AppDatabase _db = AppDatabase.instance;

  @override
  Future<List<ExchangeRate>> getRates() async {
    return await _db.getExchangeRates();
  }

  @override
  Future<ExchangeRate?> getRate(String currencyCode) async {
    return await _db.getExchangeRate(currencyCode);
  }

  @override
  Future<void> updateRates(List<ExchangeRate> rates) async {
    for (final rate in rates) {
      await _db.insertExchangeRate(rate);
    }
  }

  @override
  Future<List<ExchangeRate>> syncLatestRates() async {
    // Simulated live interbank rates with SQLite caching
    final latestRates = [
      ExchangeRate(
        code: 'USD',
        symbol: '\$',
        rateToUsd: 1.0,
        lastUpdatedMillis: DateTime.now().millisecondsSinceEpoch,
      ),
      ExchangeRate(
        code: 'EUR',
        symbol: '€',
        rateToUsd: 0.92,
        lastUpdatedMillis: DateTime.now().millisecondsSinceEpoch,
      ),
      ExchangeRate(
        code: 'GBP',
        symbol: '£',
        rateToUsd: 0.79,
        lastUpdatedMillis: DateTime.now().millisecondsSinceEpoch,
      ),
      ExchangeRate(
        code: 'PKR',
        symbol: 'Rs ',
        rateToUsd: 278.50,
        lastUpdatedMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    ];

    await updateRates(latestRates);
    return latestRates;
  }
}
