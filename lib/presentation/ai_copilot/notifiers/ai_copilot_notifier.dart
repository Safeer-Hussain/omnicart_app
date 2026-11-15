import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/repositories/cart_repository.dart';
import '../../../domain/repositories/catalog_repository.dart';
import '../../../domain/repositories/order_repository.dart';

class AiMessage {
  final String id;
  final String text;
  final bool isUser;
  final int timestampMillis;

  const AiMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestampMillis,
  });

  AiMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    int? timestampMillis,
  }) {
    return AiMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestampMillis: timestampMillis ?? this.timestampMillis,
    );
  }
}

class MonthlySpendPoint {
  final String month;
  final double spendUsd;
  final double savingsUsd;

  const MonthlySpendPoint({
    required this.month,
    required this.spendUsd,
    required this.savingsUsd,
  });
}

class AiCopilotState {
  final List<AiMessage> messages;
  final bool isStreaming;
  final String? transientStatus;
  final List<MonthlySpendPoint> monthlySpendData;

  const AiCopilotState({
    required this.messages,
    this.isStreaming = false,
    this.transientStatus,
    required this.monthlySpendData,
  });

  factory AiCopilotState.initial() {
    return AiCopilotState(
      messages: [
        AiMessage(
          id: 'welcome_msg',
          text: 'Welcome to OmniCart Enterprise Copilot. I analyze your real-time cart SKUs, local dark-store stock levels, competitor pricing, and active promos to optimize fulfillment and basket savings. How can I assist your order today?',
          isUser: false,
          timestampMillis: DateTime.now().millisecondsSinceEpoch,
        ),
      ],
      monthlySpendData: const [
        MonthlySpendPoint(month: 'Jun', spendUsd: 240.0, savingsUsd: 48.0),
        MonthlySpendPoint(month: 'Jul', spendUsd: 380.0, savingsUsd: 72.0),
        MonthlySpendPoint(month: 'Aug', spendUsd: 195.0, savingsUsd: 35.0),
        MonthlySpendPoint(month: 'Sep', spendUsd: 420.0, savingsUsd: 95.0),
        MonthlySpendPoint(month: 'Oct', spendUsd: 310.0, savingsUsd: 64.0),
        MonthlySpendPoint(month: 'Nov', spendUsd: 520.0, savingsUsd: 110.0),
      ],
    );
  }

  AiCopilotState copyWith({
    List<AiMessage>? messages,
    bool? isStreaming,
    String? transientStatus,
    bool clearTransientStatus = false,
    List<MonthlySpendPoint>? monthlySpendData,
  }) {
    return AiCopilotState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      transientStatus: clearTransientStatus
          ? null
          : (transientStatus ?? this.transientStatus),
      monthlySpendData: monthlySpendData ?? this.monthlySpendData,
    );
  }
}

class AiShoppingCopilotNotifier extends Notifier<AiCopilotState> {
  late final CartRepository _cartRepo;
  late final CatalogRepository _catalogRepo;
  late final OrderRepository _orderRepo;

  @override
  AiCopilotState build() {
    _cartRepo = sl<CartRepository>();
    _catalogRepo = sl<CatalogRepository>();
    _orderRepo = sl<OrderRepository>();
    return AiCopilotState.initial();
  }

  Future<void> sendUserPrompt(String prompt, AppCurrency currency) async {
    if (prompt.trim().isEmpty || state.isStreaming) return;

    final userMessage = AiMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: prompt.trim(),
      isUser: true,
      timestampMillis: DateTime.now().millisecondsSinceEpoch,
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isStreaming: true,
      transientStatus:
          'Comparing cart SKUs, active promo codes & dark-store stock...',
    );

    try {
      final fullResponse = await _generateContextualResponse(prompt, currency);

      // Prepare assistant placeholder message
      final assistantMessageId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
      var assistantMessage = AiMessage(
        id: assistantMessageId,
        text: '',
        isUser: false,
        timestampMillis: DateTime.now().millisecondsSinceEpoch,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        clearTransientStatus: true,
      );

      // Stream tokens smoothly
      final tokens = fullResponse.split(' ');
      var accumulated = '';

      for (var i = 0; i < tokens.length; i++) {
        accumulated += (i == 0 ? '' : ' ') + tokens[i];
        final updatedList = List<AiMessage>.from(state.messages);
        final idx = updatedList.indexWhere((m) => m.id == assistantMessageId);
        if (idx != -1) {
          updatedList[idx] = updatedList[idx].copyWith(text: accumulated);
          state = state.copyWith(messages: updatedList);
        }
        await Future.delayed(const Duration(milliseconds: 25));
      }
    } finally {
      state = state.copyWith(isStreaming: false, clearTransientStatus: true);
    }
  }

  Future<String> _generateContextualResponse(
    String prompt,
    AppCurrency currency,
  ) async {
    final cartItems = await _cartRepo.getCartItems();
    final allProducts = await _catalogRepo.getProducts();
    final orders = await _orderRepo.getOrders();
    final wishlisted = allProducts.where((p) => p.isWishlisted).toList();

    final query = prompt.toLowerCase();

    if (query.contains('promo') ||
        query.contains('discount') ||
        query.contains('bundle')) {
      final subtotal = cartItems.fold(0.0, (sum, i) => sum + i.totalPriceUsd);
      final save20Val = CurrencyFormatter.format(subtotal * 0.20, currency);
      final vip15Val = CurrencyFormatter.format(subtotal * 0.15, currency);

      if (cartItems.isEmpty) {
        return 'Your cart is currently empty. Our active dark-store promo codes are: '
            '1. SAVE20: 20% off entire order subtotal. '
            '2. FREESHIP: 100% waiver on the 15-minute express delivery fee. '
            '3. VIP15: 15% flat privilege discount. '
            'Add items from the Storefront or POS Scanner to calculate real-time savings.';
      }

      return 'Basket Optimization Report for ${cartItems.length} active item(s): '
          'Subtotal is ${CurrencyFormatter.format(subtotal, currency)}. '
          'Recommended code: SAVE20 will yield maximum savings of $save20Val at checkout! '
          'Alternatively, code VIP15 saves $vip15Val. Free express shipping automatically activates at \$50.00 threshold.';
    }

    if (query.contains('wishlist') ||
        query.contains('spec') ||
        query.contains('value')) {
      if (wishlisted.isEmpty) {
        return 'You have not wishlisted any items yet. Tap the heart icon on any product in the Storefront to track price-to-spec performance and dark-store stock drops.';
      }

      final specsSummary = wishlisted
          .take(3)
          .map((p) {
            final compDiff = (p.competitorPriceUsd - p.priceUsd);
            final compText = compDiff > 0
                ? 'OmniCart saves you ${CurrencyFormatter.format(compDiff, currency)} vs ${p.competitorName}.'
                : 'Offered at fair enterprise pricing.';
            return '${p.name} (${CurrencyFormatter.format(p.priceUsd, currency)}): Rated ${p.rating}/5.0 with ${p.darkStoreStock} units in ${p.aisleLocation}. $compText';
          })
          .join('\n\n');

      return 'Wishlist Value Assessment (${wishlisted.length} tracked items):\n\n$specsSummary';
    }

    if (query.contains('spend') ||
        query.contains('summary') ||
        query.contains('month')) {
      final totalOrdersCount = orders.length;
      final totalSpent = orders.fold(0.0, (sum, o) => sum + o.totalUsd);
      final totalSavings = orders.fold(0.0, (sum, o) => sum + o.discountUsd);

      return 'Fiscal Spend Summary:\n'
          'Total Recorded Orders: $totalOrdersCount\n'
          'Cumulative Order Volume: ${CurrencyFormatter.format(totalSpent, currency)}\n'
          'Total Captured Promo Savings: ${CurrencyFormatter.format(totalSavings, currency)}\n'
          'Average Delivery Window: 13.8 minutes across Lahore Dark-Store A1 fulfillment route.';
    }

    if (query.contains('express') ||
        query.contains('15-min') ||
        query.contains('essential')) {
      final expressItems = allProducts
          .where((p) => p.isExpressDelivery)
          .take(4)
          .toList();
      final summary = expressItems
          .map((p) {
            return '- ${p.name}: ${CurrencyFormatter.format(p.priceUsd, currency)} (${p.darkStoreStock} in stock, ${p.aisleLocation})';
          })
          .join('\n');

      return 'Top 15-Minute Express Essentials ready for immediate dispatch:\n$summary\nAll items are staged in cold-zone or high-velocity bays for sub-minute picking.';
    }

    return 'OmniCart Copilot analyzed your request against local SQLite catalog (${allProducts.length} items), ${cartItems.length} cart SKU(s), and ${orders.length} historical order(s). All fulfillment lanes are operating at 100% nominal throughput with active NFC hardware terminals.';
  }

  void clearConversation() {
    state = state.copyWith(
      messages: [
        AiMessage(
          id: 'welcome_msg_reset',
          text: 'Conversation cleared. How can I assist your order today?',
          isUser: false,
          timestampMillis: DateTime.now().millisecondsSinceEpoch,
        ),
      ],
    );
  }
}

final aiCopilotProvider =
    NotifierProvider<AiShoppingCopilotNotifier, AiCopilotState>(
      AiShoppingCopilotNotifier.new,
    );
