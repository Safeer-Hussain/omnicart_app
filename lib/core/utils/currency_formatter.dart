import 'package:intl/intl.dart';

enum AppCurrency {
  usd('USD', '\$', 1.0, 2),
  eur('EUR', '€', 0.92, 2),
  gbp('GBP', '£', 0.79, 2),
  pkr('PKR', 'Rs ', 278.50, 0);

  final String code;
  final String symbol;
  final double defaultRateToUsd;
  final int decimalDigits;

  const AppCurrency(
    this.code,
    this.symbol,
    this.defaultRateToUsd,
    this.decimalDigits,
  );

  static AppCurrency fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'EUR':
        return AppCurrency.eur;
      case 'GBP':
        return AppCurrency.gbp;
      case 'PKR':
        return AppCurrency.pkr;
      case 'USD':
      default:
        return AppCurrency.usd;
    }
  }
}

class CurrencyFormatter {
  static final NumberFormat _usdFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat _eurFormat = NumberFormat.currency(
    symbol: '€',
    decimalDigits: 2,
  );

  static final NumberFormat _gbpFormat = NumberFormat.currency(
    symbol: '£',
    decimalDigits: 2,
  );

  static final NumberFormat _pkrFormat = NumberFormat.currency(
    symbol: 'Rs ',
    decimalDigits: 0,
  );

  static String format(
    double amountUsd,
    AppCurrency currency, {
    double? customRate,
  }) {
    final rate = customRate ?? currency.defaultRateToUsd;
    final converted = amountUsd * rate;

    switch (currency) {
      case AppCurrency.usd:
        return _usdFormat.format(converted);
      case AppCurrency.eur:
        return _eurFormat.format(converted);
      case AppCurrency.gbp:
        return _gbpFormat.format(converted);
      case AppCurrency.pkr:
        return _pkrFormat.format(converted);
    }
  }

  static double convert(
    double amountUsd,
    AppCurrency currency, {
    double? customRate,
  }) {
    final rate = customRate ?? currency.defaultRateToUsd;
    return amountUsd * rate;
  }
}
