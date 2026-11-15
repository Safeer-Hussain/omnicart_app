import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../navigation/navigation_provider.dart';
import '../notifiers/cart_notifier.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/checkout_modal.dart';
import '../widgets/promo_input_card.dart';
import '../widgets/shipping_progress_bar.dart';

class CartView extends ConsumerWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cartState = ref.watch(cartProvider);
    final currency = ref.watch(currencyProvider);

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final formattedTotal = CurrencyFormatter.format(
      cartState.totalUsd,
      currency,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: cartState.activeItems.isNotEmpty
          ? FloatingActionButton.extended(
              heroTag: 'fab_cart_quick_checkout',
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              icon: const Icon(Icons.bolt),
              label: Text('Checkout ($formattedTotal)'),
              onPressed: () => CheckoutModal.show(context),
            )
          : null,
      body: SafeArea(
        child: cartState.items.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your Enterprise Cart is Empty',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Browse dark-store inventory or scan product UPC barcodes.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        ref.read(navigationProvider.notifier).selectTab(0);
                      },
                      icon: const Icon(Icons.storefront),
                      label: const Text('Explore Catalog'),
                    ),
                  ],
                ),
              )
            : isLandscape
            ? _buildLandscapeLayout(context, ref, colorScheme, cartState)
            : _buildPortraitLayout(context, ref, colorScheme, cartState),
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    CartState cartState,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Shipping Progress
        const ShippingProgressBar(),
        const SizedBox(height: 16),

        // Active Items Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Items (${cartState.totalItemCount})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              'Swipe left to remove',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Active Cart Items List
        ...cartState.activeItems.map((item) => CartItemCard(item: item)),

        // Saved For Later Items
        if (cartState.savedForLaterItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Saved for Later (${cartState.savedForLaterItems.length})',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ...cartState.savedForLaterItems.map(
            (item) => CartItemCard(item: item),
          ),
        ],

        const SizedBox(height: 16),
        const PromoInputCard(),
        const SizedBox(height: 80), // Padding for FAB
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    CartState cartState,
  ) {
    return Row(
      children: [
        // Left Pane: Cart Items
        Expanded(
          flex: 3,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            children: [
              Text(
                'Cart Items (${cartState.totalItemCount})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ...cartState.activeItems.map((item) => CartItemCard(item: item)),
              if (cartState.savedForLaterItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Saved for Later',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                ...cartState.savedForLaterItems.map(
                  (item) => CartItemCard(item: item),
                ),
              ],
            ],
          ),
        ),

        VerticalDivider(color: colorScheme.outlineVariant, width: 1),

        // Right Pane: Summary & Actions
        Expanded(
          flex: 2,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            children: const [
              ShippingProgressBar(),
              SizedBox(height: 12),
              PromoInputCard(),
              SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }
}
