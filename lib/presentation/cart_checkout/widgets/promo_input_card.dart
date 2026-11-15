import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_feedback.dart';
import '../notifiers/cart_notifier.dart';

class PromoInputCard extends ConsumerStatefulWidget {
  const PromoInputCard({super.key});

  @override
  ConsumerState<PromoInputCard> createState() => _PromoInputCardState();
}

class _PromoInputCardState extends ConsumerState<PromoInputCard> {
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo() {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    final success = ref.read(cartProvider.notifier).applyPromoCode(code);
    if (success) {
      _promoController.clear();
      AppFeedback.showSuccess(
        context,
        'Promo code $code applied successfully!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cartState = ref.watch(cartProvider);

    return Container(
      padding: const EdgeInsets.all(14),
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
                Icons.confirmation_number_outlined,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Promo Code & Enterprise Vouchers',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (cartState.appliedPromo != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: colorScheme.onPrimaryContainer,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Code ${cartState.appliedPromo!.code} Active',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            cartState.appliedPromo!.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onPrimaryContainer.withAlpha(
                                200,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    onPressed: () {
                      ref.read(cartProvider.notifier).removePromoCode();
                      AppFeedback.showInfo(context, 'Promo code removed.');
                    },
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter code (e.g., SAVE20, FREESHIP)',
                      hintStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      errorText: cartState.promoError,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: _applyPromo,
                  child: const Text('Apply'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                ActionChip(
                  label: const Text('SAVE20', style: TextStyle(fontSize: 10)),
                  onPressed: () {
                    _promoController.text = 'SAVE20';
                    _applyPromo();
                  },
                ),
                ActionChip(
                  label: const Text('FREESHIP', style: TextStyle(fontSize: 10)),
                  onPressed: () {
                    _promoController.text = 'FREESHIP';
                    _applyPromo();
                  },
                ),
                ActionChip(
                  label: const Text('VIP15', style: TextStyle(fontSize: 10)),
                  onPressed: () {
                    _promoController.text = 'VIP15';
                    _applyPromo();
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
