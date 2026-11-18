import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_cart_app/core/theme/theme_mode_provider.dart';
import 'package:omni_cart_app/core/utils/currency_formatter.dart';
import 'package:omni_cart_app/domain/entities/exchange_rate.dart';
import 'package:omni_cart_app/domain/repositories/fx_repository.dart';

import '../helpers/mock_repositories.dart';

void main() {
  late FxRepository fxRepo;

  setUp(() {
    registerMockServices();
    fxRepo = MockFxRepository();
  });

  group('ExchangeRate & CurrencyFormatter Tests', () {
    test('ExchangeRate entity serializes and deserializes accurately', () {
      const rate = ExchangeRate(
        code: 'EUR',
        symbol: '€',
        rateToUsd: 0.92,
        lastUpdatedMillis: 1731900000000,
      );

      final map = rate.toMap();
      expect(map['code'], 'EUR');
      expect(map['symbol'], '€');
      expect(map['rate_to_usd'], 0.92);

      final reconstructed = ExchangeRate.fromMap(map);
      expect(reconstructed.code, 'EUR');
      expect(reconstructed.symbol, '€');
      expect(reconstructed.rateToUsd, 0.92);
    });

    test('CurrencyFormatter formats all 4 global currencies accurately', () {
      const amountUsd = 100.0;

      final usd = CurrencyFormatter.format(amountUsd, AppCurrency.usd);
      expect(usd, '\$100.00');

      final eur = CurrencyFormatter.format(amountUsd, AppCurrency.eur);
      expect(eur, '€92.00');

      final gbp = CurrencyFormatter.format(amountUsd, AppCurrency.gbp);
      expect(gbp, '£79.00');

      final pkr = CurrencyFormatter.format(amountUsd, AppCurrency.pkr);
      expect(pkr, 'Rs 27,850');
    });

    test('CurrencyFormatter converts amounts using custom dynamic rates', () {
      const amountUsd = 50.0;
      final converted = CurrencyFormatter.convert(
        amountUsd,
        AppCurrency.eur,
        customRate: 0.95,
      );
      expect(converted, 47.5);
    });

    test('AppCurrency.fromCode parses currency codes safely', () {
      expect(AppCurrency.fromCode('usd'), AppCurrency.usd);
      expect(AppCurrency.fromCode('EUR'), AppCurrency.eur);
      expect(AppCurrency.fromCode('gbp'), AppCurrency.gbp);
      expect(AppCurrency.fromCode('PKR'), AppCurrency.pkr);
      expect(AppCurrency.fromCode('unknown'), AppCurrency.usd);
    });
  });

  group('FxRepository Tests', () {
    test('Retrieves default rates and individual currency rates', () async {
      final rates = await fxRepo.getRates();
      expect(rates.length, 4);

      final gbp = await fxRepo.getRate('GBP');
      expect(gbp, isNotNull);
      expect(gbp!.symbol, '£');
      expect(gbp.rateToUsd, 0.79);
    });

    test('Updates rates in repository', () async {
      final updatedEur = ExchangeRate(
        code: 'EUR',
        symbol: '€',
        rateToUsd: 0.94,
        lastUpdatedMillis: DateTime.now().millisecondsSinceEpoch,
      );

      await fxRepo.updateRates([updatedEur]);
      final fetched = await fxRepo.getRate('EUR');
      expect(fetched!.rateToUsd, 0.94);
    });

    test('CurrencyNotifier cycles through all 4 currencies', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(currencyProvider.notifier);
      expect(container.read(currencyProvider), AppCurrency.usd);

      await notifier.toggleCurrency();
      expect(container.read(currencyProvider), AppCurrency.eur);

      await notifier.toggleCurrency();
      expect(container.read(currencyProvider), AppCurrency.gbp);

      await notifier.toggleCurrency();
      expect(container.read(currencyProvider), AppCurrency.pkr);

      await notifier.toggleCurrency();
      expect(container.read(currencyProvider), AppCurrency.usd);
    });
  });
}
