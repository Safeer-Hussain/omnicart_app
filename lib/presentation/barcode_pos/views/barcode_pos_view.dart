import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../cart_checkout/notifiers/cart_notifier.dart';
import '../notifiers/barcode_pos_notifier.dart';
import '../widgets/laser_reticle_painter.dart';
import '../widgets/telemetry_strip.dart';

class BarcodePosView extends ConsumerStatefulWidget {
  const BarcodePosView({super.key});

  @override
  ConsumerState<BarcodePosView> createState() => _BarcodePosViewState();
}

class _BarcodePosViewState extends ConsumerState<BarcodePosView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final posState = ref.watch(barcodePosProvider);
    final currency = ref.watch(currencyProvider);

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_scan_upc_barcode',
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan UPC Barcode'),
        onPressed: () {
          ref.read(barcodePosProvider.notifier).scanUpcBarcode();
        },
      ),
      body: SafeArea(
        child: isLandscape
            ? _buildLandscapeLayout(
                context,
                ref,
                colorScheme,
                posState,
                currency,
              )
            : _buildPortraitLayout(
                context,
                ref,
                colorScheme,
                posState,
                currency,
              ),
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    BarcodePosState posState,
    AppCurrency currency,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Live Telemetry Strip
        TelemetryStrip(metric: posState.liveTelemetry),
        const SizedBox(height: 16),

        // Optical Barcode Viewfinder
        _buildViewfinder(colorScheme, posState),
        const SizedBox(height: 16),

        // Scanned SKU Result or Instructions
        if (posState.matchedProduct != null) ...[
          _buildMatchedSkuCard(context, ref, colorScheme, posState, currency),
        ] else ...[
          _buildEmptyScannerPlaceholder(colorScheme, posState),
        ],

        const SizedBox(height: 16),

        // Native Hardware Testing Actions
        _buildHardwareActionButtons(
          context,
          ref,
          colorScheme,
          posState,
          currency,
        ),
        const SizedBox(height: 80), // Padding for FAB
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    BarcodePosState posState,
    AppCurrency currency,
  ) {
    return Row(
      children: [
        // Left Pane: Viewfinder & Telemetry
        Expanded(
          flex: 1,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            children: [
              TelemetryStrip(metric: posState.liveTelemetry),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: _buildViewfinder(colorScheme, posState),
              ),
            ],
          ),
        ),

        VerticalDivider(color: colorScheme.outlineVariant, width: 1),

        // Right Pane: Scanned SKU Result & Hardware Actions
        Expanded(
          flex: 1,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            children: [
              if (posState.matchedProduct != null) ...[
                _buildMatchedSkuCard(
                  context,
                  ref,
                  colorScheme,
                  posState,
                  currency,
                ),
              ] else ...[
                _buildEmptyScannerPlaceholder(colorScheme, posState),
              ],
              const SizedBox(height: 12),
              _buildHardwareActionButtons(
                context,
                ref,
                colorScheme,
                posState,
                currency,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewfinder(ColorScheme colorScheme, BarcodePosState posState) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Barcode Graphics
          Opacity(
            opacity: 0.15,
            child: Icon(
              Icons.qr_code_2,
              size: 140,
              color: colorScheme.onSurface,
            ),
          ),

          // Custom Animated Reticle
          AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              return CustomPaint(
                size: const Size(220, 120),
                painter: LaserReticlePainter(
                  animationValue: _animController.value,
                  laserColor: colorScheme.primary,
                  cornerColor: colorScheme.secondary,
                ),
              );
            },
          ),

          // Label
          Positioned(
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(200),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                posState.isScanning
                    ? 'Capturing UPC Barcode Laser Stream...'
                    : 'Align Barcode Inside Laser Bounds',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchedSkuCard(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    BarcodePosState posState,
    AppCurrency currency,
  ) {
    final product = posState.matchedProduct!;
    final formattedPrice = CurrencyFormatter.format(product.priceUsd, currency);
    final formattedComp = CurrencyFormatter.format(
      product.competitorPriceUsd,
      currency,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'MATCHED SKU: ${product.upcBarcode}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  ref.read(barcodePosProvider.notifier).clearScan();
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Location: ${product.aisleLocation} | Live Stock: ${product.darkStoreStock} units',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Price Comparison
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OmniCart POS Price',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      formattedPrice,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${product.competitorName} Price',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      formattedComp,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 1-Tap Add to Cart
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              onPressed: () {
                ref.read(cartProvider.notifier).addToCart(product);
                AppFeedback.showSuccess(
                  context,
                  'Added ${product.name} to cart.',
                );
              },
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: Text('Add Scanned Item to Cart ($formattedPrice)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScannerPlaceholder(
    ColorScheme colorScheme,
    BarcodePosState posState,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.barcode_reader, size: 36, color: colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            'Hardware Laser Scanner Ready',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            posState.scanFeedbackMessage ?? 'Tap the button below or trigger physical hardware imager to scan any seeded catalog SKU.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareActionButtons(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    BarcodePosState posState,
    AppCurrency currency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RETAIL POS HARDWARE BRIDGES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),

        // NFC Terminal Tap-to-Pay Test
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          tileColor: colorScheme.surfaceContainer,
          leading: Icon(Icons.contactless, color: colorScheme.secondary),
          title: const Text(
            'Test NFC Tap-to-Pay Terminal',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'Invokes native iOS CoreNFC / Android HCE Bridge',
            style: TextStyle(fontSize: 11),
          ),
          trailing: posState.isNfcProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right),
          onTap: () async {
            final currencyStr = currency == AppCurrency.pkr ? 'PKR' : 'USD';
            final res = await ref
                .read(barcodePosProvider.notifier)
                .initiateNfcTapToPay(amount: 25.0, currency: currencyStr);
            if (context.mounted) {
              AppFeedback.showSuccess(
                context,
                'NFC Tap Approved: ${res["cardNetwork"]} | Txn: ${res["transactionId"]}',
              );
            }
          },
        ),
      ],
    );
  }
}
