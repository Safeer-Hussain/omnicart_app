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

  testWidgets('Zero RenderFlex overflow errors on 800x360 landscape viewport', (
    tester,
  ) async {
    // Set 800x360 landscape viewport
    await tester.binding.setSurfaceSize(const Size(800, 360));

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

    // In landscape, NavigationRail must be active and bottom NavigationBar must not exist
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    // Switch across tabs and verify zero RenderFlex exceptions
    final element = tester.element(find.byType(AdaptiveScaffold));
    final container = ProviderScope.containerOf(element);

    for (var i = 0; i <= 4; i++) {
      container.read(navigationProvider.notifier).selectTab(i);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester.takeException(),
        isNull,
        reason: 'Tab $i failed on 800x360 landscape',
      );
    }
  });
}
