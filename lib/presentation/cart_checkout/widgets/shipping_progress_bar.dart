import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../notifiers/cart_notifier.dart';

class ShippingProgressBar extends ConsumerWidget {
  const ShippingProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cartState = ref.watch(cartProvider);
    final currency = ref.watch(currencyProvider);

    final isFree =
        cartState.shippingFeeUsd == 0.0 && cartState.activeItems.isNotEmpty;
    final remainingFormatted = CurrencyFormatter.format(
      cartState.amountRemainingForFreeShipping,
      currency,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFree ? Icons.local_shipping : Icons.bolt,
                color: isFree ? colorScheme.primary : colorScheme.secondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFree
                      ? 'Congratulations! You unlocked Free 15-Minute Express Delivery.'
                      : 'Add $remainingFormatted more for Free 15-Minute Express Delivery',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cartState.shippingProgress,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: isFree ? colorScheme.primary : colorScheme.secondary,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
