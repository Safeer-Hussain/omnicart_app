import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_cart_app/core/utils/currency_formatter.dart';
import 'package:omni_cart_app/presentation/ai_copilot/notifiers/ai_copilot_notifier.dart';

import '../helpers/mock_repositories.dart';

void main() {
  setUp(() {
    registerMockServices();
  });

  test(
    'AiShoppingCopilotNotifier initializes with welcome message and analytics',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(aiCopilotProvider);
      expect(state.messages.length, 1);
      expect(state.messages.first.isUser, isFalse);
      expect(state.monthlySpendData.length, 6);
      expect(state.isStreaming, isFalse);
    },
  );

  test('AiShoppingCopilotNotifier strictly resets isStreaming to false upon completion', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(aiCopilotProvider.notifier);

    // Send prompt
    final future = notifier.sendUserPrompt(
      'Find Best Promo Code & Bundle Savings for My Cart',
      AppCurrency.usd,
    );

    // Immediately after invoking, streaming should be true
    expect(container.read(aiCopilotProvider).isStreaming, isTrue);

    await future;

    // After completion, isStreaming MUST be false
    final finalState = container.read(aiCopilotProvider);
    expect(finalState.isStreaming, isFalse);
    expect(finalState.transientStatus, isNull);
    expect(finalState.messages.length, greaterThanOrEqualTo(3));
  });

  test(
    'AiShoppingCopilotNotifier clearConversation resets message thread',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(aiCopilotProvider.notifier);
      await notifier.sendUserPrompt(
        'Summarize My Monthly Order Spending',
        AppCurrency.usd,
      );

      expect(container.read(aiCopilotProvider).messages.length, greaterThan(1));

      notifier.clearConversation();
      expect(container.read(aiCopilotProvider).messages.length, 1);
      expect(
        container.read(aiCopilotProvider).messages.first.text,
        contains('cleared'),
      );
    },
  );
}
