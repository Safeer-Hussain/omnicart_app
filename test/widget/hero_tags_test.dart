import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_cart_app/core/theme/app_theme.dart';
import 'package:omni_cart_app/presentation/navigation/adaptive_scaffold.dart';
import 'package:omni_cart_app/presentation/navigation/navigation_provider.dart';

import '../helpers/mock_repositories.dart';

void main() {
  setUp(() {
    registerMockServices();
  });

  testWidgets('Zero duplicate Hero tag exceptions across multi-tab shell', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AdaptiveScaffold(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Catalog FAB has unique tag
    final catalogFab = find.byType(FloatingActionButton);
    expect(catalogFab, findsOneWidget);
    final catalogFabWidget = tester.widget<FloatingActionButton>(catalogFab);
    expect(catalogFabWidget.heroTag, 'fab_catalog_filter');

    // Switch to Courier Tracker tab
    final element = tester.element(find.byType(AdaptiveScaffold));
    final container = ProviderScope.containerOf(element);
    container.read(navigationProvider.notifier).selectTab(2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final courierFab = find.byType(FloatingActionButton);
    expect(courierFab, findsOneWidget);
    final courierFabWidget = tester.widget<FloatingActionButton>(courierFab);
    expect(courierFabWidget.heroTag, 'fab_courier_recenter');

    // Switch to POS Scanner tab
    container.read(navigationProvider.notifier).selectTab(3);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final posFab = find.byType(FloatingActionButton);
    expect(posFab, findsOneWidget);
    final posFabWidget = tester.widget<FloatingActionButton>(posFab);
    expect(posFabWidget.heroTag, 'fab_scan_upc_barcode');

    // Switch to AI Copilot tab
    container.read(navigationProvider.notifier).selectTab(4);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final aiFab = find.byType(FloatingActionButton);
    expect(aiFab, findsOneWidget);
    final aiFabWidget = tester.widget<FloatingActionButton>(aiFab);
    expect(aiFabWidget.heroTag, 'fab_ai_shopper_clear');

    // Verified: No multiple heroes sharing the same tag tag exception!
    expect(tester.takeException(), isNull);
  });
}
