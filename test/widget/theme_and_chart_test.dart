import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_cart_app/core/theme/app_theme.dart';
import 'package:omni_cart_app/core/theme/theme_mode_provider.dart';
import 'package:omni_cart_app/core/utils/currency_formatter.dart';
import 'package:omni_cart_app/presentation/ai_copilot/notifiers/ai_copilot_notifier.dart';
import 'package:omni_cart_app/presentation/ai_copilot/widgets/spend_analytics_chart.dart';

import '../helpers/mock_repositories.dart';

void main() {
  setUp(() {
    registerMockServices();
  });

  testWidgets(
    'SpendAnalyticsChart renders full-width edge-to-edge without errors',
    (tester) async {
      const sampleData = [
        MonthlySpendPoint(month: 'Jun', spendUsd: 200, savingsUsd: 40),
        MonthlySpendPoint(month: 'Jul', spendUsd: 350, savingsUsd: 60),
        MonthlySpendPoint(month: 'Aug', spendUsd: 410, savingsUsd: 85),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SpendAnalyticsChart(
              data: sampleData,
              currency: AppCurrency.usd,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Monthly Spend & Savings Analytics'), findsOneWidget);
      expect(find.byType(SpendAnalyticsChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Instant Dark and Light theme mode switching updates widget tree',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              final mode = ref.watch(themeModeProvider);
              return MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: mode,
                home: const Scaffold(
                  body: Center(child: Text('OmniCart Themed Container')),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      final materialAppFinder = find.byType(MaterialApp);
      expect(materialAppFinder, findsOneWidget);

      final appElement = tester.element(materialAppFinder);
      final container = ProviderScope.containerOf(appElement);

      // Initial default is dark
      expect(container.read(themeModeProvider), ThemeMode.dark);

      // Switch to light
      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.light);
      await tester.pump();
      expect(container.read(themeModeProvider), ThemeMode.light);

      // Switch back to dark
      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.dark);
      await tester.pump();
      expect(container.read(themeModeProvider), ThemeMode.dark);

      expect(tester.takeException(), isNull);
    },
  );
}
