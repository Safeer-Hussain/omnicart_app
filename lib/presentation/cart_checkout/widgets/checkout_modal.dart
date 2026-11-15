import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/seeded_catalog.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/delivery_address.dart';
import '../../../domain/repositories/order_repository.dart';
import '../../barcode_pos/notifiers/barcode_pos_notifier.dart';
import '../../courier_tracker/notifiers/order_tracker_notifier.dart';
import '../../navigation/navigation_provider.dart';
import '../notifiers/cart_notifier.dart';

class CheckoutModal extends ConsumerStatefulWidget {
  const CheckoutModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CheckoutModal(),
    );
  }

  @override
  ConsumerState<CheckoutModal> createState() => _CheckoutModalState();
}

class _CheckoutModalState extends ConsumerState<CheckoutModal> {
  List<DeliveryAddress> _addresses = [];
  DeliveryAddress? _selectedAddress;
  String _selectedDeliverySpeed = '15-Min Express Dark Store';
  String _selectedPaymentMethod = 'NFC Tap-to-Pay';
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final list = await sl<OrderRepository>().getAddresses();
    if (list.isEmpty) {
      for (final a in SeededCatalog.defaultAddresses) {
        await sl<OrderRepository>().saveAddress(a);
      }
      _addresses = SeededCatalog.defaultAddresses;
    } else {
      _addresses = list;
    }

    _selectedAddress = _addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => _addresses.first,
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processCheckout() async {
    if (_selectedAddress == null) {
      AppFeedback.showError(
        context,
        'Please select or add a delivery address.',
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Check for Recruiter Debug force 503
      final prefs = await SharedPreferences.getInstance();
      final force503 = prefs.getBool(AppConstants.prefForce503) ?? false;
      if (force503) {
        await Future.delayed(const Duration(milliseconds: 600));
        throw Exception(
          'HTTP 503: Dark-Store Fulfillment Hub is temporarily at peak capacity. Please retry.',
        );
      }

      // If NFC Tap-to-Pay, trigger native platform bridge
      if (_selectedPaymentMethod == 'NFC Tap-to-Pay') {
        final cartState = ref.read(cartProvider);
        final currency = ref.read(currencyProvider);
        final currencyStr = currency == AppCurrency.pkr ? 'PKR' : 'USD';

        final nfcResult = await ref
            .read(barcodePosProvider.notifier)
            .initiateNfcTapToPay(
              amount: cartState.totalUsd,
              currency: currencyStr,
            );

        if (nfcResult['status'] != 'APPROVED') {
          throw Exception('NFC POS Hardware terminal declined transaction.');
        }
      }

      // Proceed with order placement
      final order = await ref
          .read(cartProvider.notifier)
          .checkoutOrder(
            address: _selectedAddress!,
            deliverySpeed: _selectedDeliverySpeed,
            paymentMethod: _selectedPaymentMethod,
          );

      if (order != null && mounted) {
        // Refresh tracker
        await ref.read(orderTrackerProvider.notifier).loadOrders();
        if (!mounted) return;
        Navigator.of(context).pop();

        AppFeedback.showSuccess(
          context,
          'Order #${order.id} placed! Courier dispatching in 15 mins.',
          actionLabel: 'Track',
          onAction: () {
            ref
                .read(navigationProvider.notifier)
                .selectTab(2); // Go to Courier Tracker
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _showAddAddressDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: 'Lahore');
    final postalCtrl = TextEditingController(text: '54000');
    final phoneCtrl = TextEditingController(text: '+92 300 ');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: const Text('Add Delivery Address'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Recipient Full Name',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: streetCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Street Address & House #',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: cityCtrl,
                          decoration: const InputDecoration(labelText: 'City'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: postalCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Postal Code',
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                    ),
                    validator: (v) => v == null || v.trim().length < 8
                        ? 'Valid phone required'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newAddr = DeliveryAddress(
                    id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
                    fullName: nameCtrl.text.trim(),
                    streetAddress: streetCtrl.text.trim(),
                    city: cityCtrl.text.trim(),
                    postalCode: postalCtrl.text.trim(),
                    phoneNumber: phoneCtrl.text.trim(),
                    isDefault: true,
                  );
                  await sl<OrderRepository>().saveAddress(newAddr);
                  if (!dialogCtx.mounted) return;
                  Navigator.pop(dialogCtx);
                  await _loadAddresses();
                  if (mounted) {
                    setState(() => _selectedAddress = newAddr);
                    AppFeedback.showSuccess(context, 'Delivery address saved.');
                  }
                }
              },
              child: const Text('Save Address'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cartState = ref.watch(cartProvider);
    final currency = ref.watch(currencyProvider);

    final formattedSubtotal = CurrencyFormatter.format(
      cartState.subtotalUsd,
      currency,
    );
    final formattedDiscount = CurrencyFormatter.format(
      cartState.discountUsd,
      currency,
    );
    final formattedShipping = CurrencyFormatter.format(
      cartState.shippingFeeUsd,
      currency,
    );
    final formattedTax = CurrencyFormatter.format(cartState.taxUsd, currency);
    final formattedTotal = CurrencyFormatter.format(
      cartState.totalUsd,
      currency,
    );

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
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Checkout & Dispatch Studio',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Direct from Lahore Central Dark-Store A1',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Error banner if any
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: colorScheme.onErrorContainer,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: colorScheme.onErrorContainer,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Address Selection
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Delivery Address',
                                  style: theme.textTheme.titleSmall,
                                ),
                                TextButton.icon(
                                  onPressed: _showAddAddressDialog,
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add New'),
                                ),
                              ],
                            ),
                            ..._addresses.map((addr) {
                              final isSelected =
                                  _selectedAddress?.id == addr.id;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorScheme.surfaceContainerHighest
                                      : colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.outlineVariant,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: RadioListTile<String>(
                                  value: addr.id,
                                  groupValue: _selectedAddress?.id,
                                  title: Text(
                                    addr.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${addr.streetAddress}, ${addr.city} (${addr.phoneNumber})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  onChanged: (_) {
                                    setState(() => _selectedAddress = addr);
                                  },
                                ),
                              );
                            }),
                            const SizedBox(height: 16),

                            // Delivery Speed Selection
                            Text(
                              'Fulfillment Speed',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Text('15-Min Express'),
                                    avatar: const Icon(Icons.bolt, size: 16),
                                    selected:
                                        _selectedDeliverySpeed ==
                                        '15-Min Express Dark Store',
                                    onSelected: (sel) {
                                      if (sel) {
                                        setState(
                                          () => _selectedDeliverySpeed =
                                              '15-Min Express Dark Store',
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Text('Scheduled Next Day'),
                                    avatar: const Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                    ),
                                    selected:
                                        _selectedDeliverySpeed ==
                                        'Standard Scheduled',
                                    onSelected: (sel) {
                                      if (sel) {
                                        setState(
                                          () => _selectedDeliverySpeed =
                                              'Standard Scheduled',
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Payment Method Selection
                            Text(
                              'Payment Method',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                              child: Column(
                                children: [
                                  RadioListTile<String>(
                                    title: const Text(
                                      'NFC Tap-to-Pay (Native Hardware Bridge)',
                                    ),
                                    subtitle: const Text(
                                      'Contactless EMV via POS MethodChannel',
                                    ),
                                    secondary: Icon(
                                      Icons.contactless,
                                      color: colorScheme.primary,
                                    ),
                                    value: 'NFC Tap-to-Pay',
                                    groupValue: _selectedPaymentMethod,
                                    onChanged: (v) => setState(
                                      () => _selectedPaymentMethod = v!,
                                    ),
                                  ),
                                  Divider(color: colorScheme.outlineVariant),
                                  RadioListTile<String>(
                                    title: const Text(
                                      'Enterprise Vault Card (Visa / Mastercard)',
                                    ),
                                    subtitle: const Text(
                                      'Encrypted on-device token (ending 4921)',
                                    ),
                                    secondary: Icon(
                                      Icons.credit_card,
                                      color: colorScheme.secondary,
                                    ),
                                    value: 'Vault Card',
                                    groupValue: _selectedPaymentMethod,
                                    onChanged: (v) => setState(
                                      () => _selectedPaymentMethod = v!,
                                    ),
                                  ),
                                  Divider(color: colorScheme.outlineVariant),
                                  RadioListTile<String>(
                                    title: const Text(
                                      'Cash on Delivery (Courier Handover)',
                                    ),
                                    subtitle: const Text(
                                      'Pay courier upon physical drop-off',
                                    ),
                                    secondary: Icon(
                                      Icons.payments_outlined,
                                      color: colorScheme.tertiary,
                                    ),
                                    value: 'Cash on Delivery',
                                    groupValue: _selectedPaymentMethod,
                                    onChanged: (v) => setState(
                                      () => _selectedPaymentMethod = v!,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Financial Summary Breakdown
                            Text(
                              'Order Breakdown',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildSummaryRow(
                                    'Subtotal (${cartState.totalItemCount} items)',
                                    formattedSubtotal,
                                    colorScheme,
                                  ),
                                  if (cartState.discountUsd > 0)
                                    _buildSummaryRow(
                                      'Promo Discount (${cartState.appliedPromo?.code ?? ""})',
                                      '-$formattedDiscount',
                                      colorScheme,
                                      isDiscount: true,
                                    ),
                                  _buildSummaryRow(
                                    'Delivery Fee',
                                    formattedShipping,
                                    colorScheme,
                                  ),
                                  _buildSummaryRow(
                                    'Sales Tax (5%)',
                                    formattedTax,
                                    colorScheme,
                                  ),
                                  Divider(color: colorScheme.outlineVariant),
                                  _buildSummaryRow(
                                    'Total Amount',
                                    formattedTotal,
                                    colorScheme,
                                    isTotal: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // Confirm Order Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        border: Border(
                          top: BorderSide(color: colorScheme.outlineVariant),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _isProcessing ? null : _processCheckout,
                          icon: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.lock_outline),
                          label: Text(
                            _isProcessing
                                ? 'Authorizing Transaction...'
                                : 'Place Order ($formattedTotal)',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ColorScheme colorScheme, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 17 : 13,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              color: isDiscount
                  ? colorScheme.primary
                  : (isTotal ? colorScheme.onSurface : colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
