class ExchangeRate {
  final String code;
  final String symbol;
  final double rateToUsd;
  final int lastUpdatedMillis;

  const ExchangeRate({
    required this.code,
    required this.symbol,
    required this.rateToUsd,
    required this.lastUpdatedMillis,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'symbol': symbol,
      'rate_to_usd': rateToUsd,
      'last_updated': lastUpdatedMillis,
    };
  }

  factory ExchangeRate.fromMap(Map<String, dynamic> map) {
    return ExchangeRate(
      code: map['code'] as String,
      symbol: map['symbol'] as String,
      rateToUsd: (map['rate_to_usd'] as num).toDouble(),
      lastUpdatedMillis: map['last_updated'] as int,
    );
  }

  static List<ExchangeRate> get defaultRates => [
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
}
