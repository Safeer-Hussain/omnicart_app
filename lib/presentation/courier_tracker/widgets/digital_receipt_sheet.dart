import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/platform/pos_hardware_bridge.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/order.dart';

class DigitalReceiptSheet extends ConsumerWidget {
  final CustomerOrder order;

  const DigitalReceiptSheet({super.key, required this.order});

  static Future<void> show(BuildContext context, CustomerOrder order) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DigitalReceiptSheet(order: order),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = ref.watch(currencyProvider);

    final dateFormatted = DateFormat('MMM dd, yyyy - hh:mm a')
        .format(DateTime.fromMillisecondsSinceEpoch(order.createdAtMillis));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Digital Tax Invoice',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Order ID: #${order.id}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.print_outlined),
                      tooltip: 'Print Thermal POS Receipt',
                      onPressed: () async {
                        final res = await sl<PosHardwareBridge>()
                            .printThermalReceiptPayload(orderId: order.id);
                        if (context.mounted) {
                          AppFeedback.showSuccess(
                            context,
                            'Thermal Receipt ${res["receiptJobId"]} printed on hardware cutter.',
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Created: $dateFormatted',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Fulfillment Center: Lahore Central Dark-Store A1',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Delivery Address: ${order.deliveryAddress.streetAddress}, ${order.deliveryAddress.city}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: colorScheme.outlineVariant),

                // Itemized List
                Text(
                  'Purchased SKUs (${order.items.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity}x ${item.product.name} (${item.selectedColor})',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(
                            item.totalPriceUsd,
                            currency,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),
                Divider(color: colorScheme.outlineVariant),

                // Totals
                _buildReceiptRow(
                  'Subtotal',
                  CurrencyFormatter.format(order.subtotalUsd, currency),
                  colorScheme,
                ),
                if (order.discountUsd > 0)
                  _buildReceiptRow(
                    'Promo Discount (${order.promoCode ?? ""})',
                    '-${CurrencyFormatter.format(order.discountUsd, currency)}',
                    colorScheme,
                    isDiscount: true,
                  ),
                _buildReceiptRow(
                  'Express Delivery Fee',
                  CurrencyFormatter.format(order.shippingFeeUsd, currency),
                  colorScheme,
                ),
                _buildReceiptRow(
                  'Sales Tax (5%)',
                  CurrencyFormatter.format(order.taxUsd, currency),
                  colorScheme,
                ),
                Divider(color: colorScheme.outlineVariant),
                _buildReceiptRow(
                  'Total Paid',
                  CurrencyFormatter.format(order.totalUsd, currency),
                  colorScheme,
                  isTotal: true,
                ),

                const SizedBox(height: 20),

                // Export & Copy Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy Invoice'),
                        onPressed: () {
                          final buffer = StringBuffer();
                          buffer.writeln('OMNICART ENTERPRISE TAX INVOICE');
                          buffer.writeln('Order ID: #${order.id}');
                          buffer.writeln('Date: $dateFormatted');
                          buffer.writeln(
                            'Delivery To: ${order.deliveryAddress.fullName}, ${order.deliveryAddress.streetAddress}',
                          );
                          buffer.writeln('Items:');
                          for (final i in order.items) {
                            buffer.writeln(
                              '  - ${i.quantity}x ${i.product.name} @ \$${i.product.priceUsd}',
                            );
                          }
                          buffer.writeln(
                            'Subtotal: \$${order.subtotalUsd.toStringAsFixed(2)}',
                          );
                          buffer.writeln(
                            'Discount: -\$${order.discountUsd.toStringAsFixed(2)}',
                          );
                          buffer.writeln(
                            'Shipping: \$${order.shippingFeeUsd.toStringAsFixed(2)}',
                          );
                          buffer.writeln(
                            'Tax: \$${order.taxUsd.toStringAsFixed(2)}',
                          );
                          buffer.writeln(
                            'TOTAL: \$${order.totalUsd.toStringAsFixed(2)}',
                          );

                          Clipboard.setData(
                            ClipboardData(text: buffer.toString()),
                          );
                          Navigator.of(context).pop();
                          AppFeedback.showSuccess(
                            context,
                            'Tax invoice brief copied to clipboard.',
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        icon: const Icon(
                          Icons.file_download_outlined,
                          size: 16,
                        ),
                        label: const Text('Export JSON'),
                        onPressed: () {
                          final jsonPayload = {
                            'invoice_id': order.id,
                            'created_at': dateFormatted,
                            'fulfillment_status': order.status.name,
                            'payment_method': order.paymentMethod,
                            'subtotal': order.subtotalUsd,
                            'discount': order.discountUsd,
                            'tax': order.taxUsd,
                            'total': order.totalUsd,
                            'items_count': order.items.length,
                          };

                          Clipboard.setData(
                            ClipboardData(text: jsonEncode(jsonPayload)),
                          );
                          Navigator.of(context).pop();
                          AppFeedback.showSuccess(
                            context,
                            'JSON receipt payload copied to clipboard.',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value,
    ColorScheme colorScheme, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 12,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              color: isDiscount ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
