import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

enum AppCurrency { usd, pkr }

class CurrencyFormatter {
  static final NumberFormat _usdFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat _pkrFormat = NumberFormat.currency(
    symbol: 'Rs ',
    decimalDigits: 0,
  );

  static String format(double amountUsd, AppCurrency currency) {
    switch (currency) {
      case AppCurrency.usd:
        return _usdFormat.format(amountUsd);
      case AppCurrency.pkr:
        return _pkrFormat.format(amountUsd * AppConstants.usdToPkrRate);
    }
  }

  static double convert(double amountUsd, AppCurrency currency) {
    switch (currency) {
      case AppCurrency.usd:
        return amountUsd;
      case AppCurrency.pkr:
        return amountUsd * AppConstants.usdToPkrRate;
    }
  }
}
