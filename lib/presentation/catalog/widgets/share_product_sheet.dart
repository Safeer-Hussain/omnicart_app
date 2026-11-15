import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/product.dart';

class ShareProductSheet extends ConsumerWidget {
  final Product product;

  const ShareProductSheet({super.key, required this.product});

  static Future<void> show(BuildContext context, Product product) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareProductSheet(product: product),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = ref.watch(currencyProvider);

    final formattedPrice = CurrencyFormatter.format(product.priceUsd, currency);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 20,
            right: 20,
            top: 12,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Share Product & Technical Brief',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // Preview Card
                Container(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            product.brand.toUpperCase(),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            formattedPrice,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.name,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'UPC: ${product.upcBarcode} | ${product.aisleLocation}',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Share Actions
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.copy,
                      color: colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  title: const Text('Copy Specification & Price Brief'),
                  subtitle: const Text(
                    'Copies markdown brief with live stock and specs',
                  ),
                  onTap: () {
                    final buffer = StringBuffer();
                    buffer.writeln('${product.brand} - ${product.name}');
                    buffer.writeln('Price: $formattedPrice');
                    buffer.writeln(
                      'Stock: ${product.darkStoreStock} units available (${product.aisleLocation})',
                    );
                    buffer.writeln('Barcode: ${product.upcBarcode}');
                    buffer.writeln('Key Specs:');
                    product.specs.forEach(
                      (k, v) => buffer.writeln('  - $k: $v'),
                    );
                    buffer.writeln('OmniCart 15-Minute Quick-Commerce');

                    Clipboard.setData(ClipboardData(text: buffer.toString()));
                    Navigator.of(context).pop();
                    AppFeedback.showSuccess(
                      context,
                      'Product brief copied to clipboard.',
                    );
                  },
                ),
                Divider(color: colorScheme.outlineVariant),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.qr_code_2,
                      color: colorScheme.onSecondaryContainer,
                      size: 20,
                    ),
                  ),
                  title: const Text('Export Digital SKU Card'),
                  subtitle: const Text(
                    'Exports itemized JSON schema for POS ingestion',
                  ),
                  onTap: () {
                    final skuJson =
                        '''
{
  "sku": "${product.id}",
  "name": "${product.name}",
  "brand": "${product.brand}",
  "upc": "${product.upcBarcode}",
  "price_usd": ${product.priceUsd},
  "aisle": "${product.aisleLocation}",
  "stock": ${product.darkStoreStock}
}
''';
                    Clipboard.setData(ClipboardData(text: skuJson));
                    Navigator.of(context).pop();
                    AppFeedback.showSuccess(
                      context,
                      'SKU JSON schema exported to clipboard.',
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
