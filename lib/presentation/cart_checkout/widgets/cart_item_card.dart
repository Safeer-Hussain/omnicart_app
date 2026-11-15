import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/cart_item.dart';
import '../notifiers/cart_notifier.dart';

class CartItemCard extends ConsumerWidget {
  final CartItem item;

  const CartItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = ref.watch(currencyProvider);

    final formattedTotal = CurrencyFormatter.format(
      item.totalPriceUsd,
      currency,
    );
    final formattedUnit = CurrencyFormatter.format(
      item.product.priceUsd,
      currency,
    );

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.delete_outline,
          color: colorScheme.onErrorContainer,
          size: 28,
        ),
      ),
      onDismissed: (_) async {
        final removed = await ref
            .read(cartProvider.notifier)
            .removeItem(item.id);
        if (removed != null && context.mounted) {
          AppFeedback.showInfo(
            context,
            'Removed ${item.product.name} from cart.',
            actionLabel: 'Undo',
            onAction: () {
              ref.read(cartProvider.notifier).undoRemove(removed);
            },
          );
        }
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        color: colorScheme.surfaceContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Image.asset(
                    item.product.imageAsset,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Product Info & Controls
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            final removed = await ref
                                .read(cartProvider.notifier)
                                .removeItem(item.id);
                            if (removed != null && context.mounted) {
                              AppFeedback.showInfo(
                                context,
                                'Removed ${item.product.name} from cart.',
                                actionLabel: 'Undo',
                                onAction: () {
                                  ref
                                      .read(cartProvider.notifier)
                                      .undoRemove(removed);
                                },
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Variant & Aisle details
                    Text(
                      '${item.selectedColor} | ${item.selectedSize}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      item.product.aisleLocation,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Price & Stepper Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedTotal,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (item.quantity > 1)
                              Text(
                                '$formattedUnit each',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),

                        // Action Controls
                        Row(
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .toggleSaveForLater(item.id);
                                AppFeedback.showInfo(
                                  context,
                                  item.isSavedForLater
                                      ? 'Moved to cart'
                                      : 'Saved for later',
                                );
                              },
                              child: Text(
                                item.isSavedForLater
                                    ? 'Move to Cart'
                                    : 'Save for Later',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Stepper
                            if (!item.isSavedForLater)
                              Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        ref
                                            .read(cartProvider.notifier)
                                            .decrementQuantity(item.id);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.remove,
                                          size: 16,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        '${item.quantity}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        ref
                                            .read(cartProvider.notifier)
                                            .incrementQuantity(item.id);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.add,
                                          size: 16,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
