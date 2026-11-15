import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/review.dart';
import '../../cart_checkout/notifiers/cart_notifier.dart';
import '../notifiers/catalog_notifier.dart';
import '../widgets/share_product_sheet.dart';
import '../widgets/write_review_modal.dart';

class ProductDetailSheet extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailSheet({super.key, required this.product});

  static Future<void> show(BuildContext context, Product product) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetailSheet(product: product),
    );
  }

  @override
  ConsumerState<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends ConsumerState<ProductDetailSheet> {
  late String _selectedColor;
  late String _selectedSize;
  int _quantity = 1;
  List<Review> _reviews = [];
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.product.selectedColor.isNotEmpty
        ? widget.product.selectedColor
        : (widget.product.availableColors.isNotEmpty
              ? widget.product.availableColors.first
              : 'Default');
    _selectedSize = widget.product.selectedSize.isNotEmpty
        ? widget.product.selectedSize
        : (widget.product.availableSizes.isNotEmpty
              ? widget.product.availableSizes.first
              : 'Standard');
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final list = await ref
        .read(catalogProvider.notifier)
        .getReviews(widget.product.id);
    if (mounted) {
      setState(() {
        _reviews = list;
        _isLoadingReviews = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = ref.watch(currencyProvider);
    final isWishlisted = ref
        .watch(catalogProvider)
        .allProducts
        .firstWhere(
          (p) => p.id == widget.product.id,
          orElse: () => widget.product,
        )
        .isWishlisted;

    final formattedPrice = CurrencyFormatter.format(
      widget.product.priceUsd,
      currency,
    );
    final formattedOrigPrice = CurrencyFormatter.format(
      widget.product.originalPriceUsd,
      currency,
    );
    final formattedCompetitorPrice = CurrencyFormatter.format(
      widget.product.competitorPriceUsd,
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
          child: Column(
            children: [
              // Drag Handle
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

              // Scrollable Details
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.product.category.toUpperCase(),
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.share_outlined),
                                tooltip: 'Share Spec Brief',
                                onPressed: () {
                                  ShareProductSheet.show(
                                    context,
                                    widget.product,
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  isWishlisted
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isWishlisted
                                      ? colorScheme.error
                                      : colorScheme.onSurface,
                                ),
                                tooltip: 'Save to Wishlist',
                                onPressed: () {
                                  ref
                                      .read(catalogProvider.notifier)
                                      .toggleWishlist(widget.product.id);
                                  AppFeedback.showInfo(
                                    context,
                                    !isWishlisted
                                        ? 'Added to wishlist'
                                        : 'Removed from wishlist',
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Title & Brand
                      Text(
                        widget.product.brand.toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.product.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Rating & Reviews Summary
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: colorScheme.tertiary,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.product.rating}',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${widget.product.reviewCount} verified ratings)',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Pricing & Savings Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            formattedPrice,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (widget.product.originalPriceUsd >
                              widget.product.priceUsd) ...[
                            const SizedBox(width: 10),
                            Text(
                              formattedOrigPrice,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 16,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '-${widget.product.discountPercent.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: colorScheme.onTertiaryContainer,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Competitor Price Comparison Badge
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.compare_arrows,
                              color: colorScheme.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${widget.product.competitorName} Price: $formattedCompetitorPrice (OmniCart saves you ${widget.product.competitorSavingsPercent.toStringAsFixed(0)}%)',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dark-Store Stock & Aisle Location
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  widget.product.darkStoreStock > 0
                                      ? Icons.inventory_2_outlined
                                      : Icons.remove_circle_outline,
                                  color: widget.product.darkStoreStock > 0
                                      ? colorScheme.primary
                                      : colorScheme.error,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.product.darkStoreStock > 0
                                      ? 'In Stock: ${widget.product.darkStoreStock} units available'
                                      : 'Backorder Required',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                if (widget.product.isExpressDelivery)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '15-MIN EXPRESS',
                                      style: TextStyle(
                                        color: colorScheme.onPrimaryContainer,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Dark-Store Location: ${widget.product.aisleLocation}',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Hardware UPC: ${widget.product.upcBarcode}',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'Overview',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.product.description,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Interactive Variant Selector - Colors
                      if (widget.product.availableColors.isNotEmpty) ...[
                        Text(
                          'Color: $_selectedColor',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: widget.product.availableColors.map((col) {
                            final isSel = _selectedColor == col;
                            return ChoiceChip(
                              label: Text(col),
                              selected: isSel,
                              selectedColor: colorScheme.primary,
                              labelStyle: TextStyle(
                                color: isSel
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface,
                                fontWeight: isSel
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedColor = col);
                                  ref
                                      .read(catalogProvider.notifier)
                                      .updateProductVariant(
                                        widget.product.id,
                                        color: col,
                                      );
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Interactive Variant Selector - Size/Capacity
                      if (widget.product.availableSizes.isNotEmpty) ...[
                        Text(
                          'Configuration: $_selectedSize',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: widget.product.availableSizes.map((sz) {
                            final isSel = _selectedSize == sz;
                            return ChoiceChip(
                              label: Text(sz),
                              selected: isSel,
                              selectedColor: colorScheme.primary,
                              labelStyle: TextStyle(
                                color: isSel
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface,
                                fontWeight: isSel
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedSize = sz);
                                  ref
                                      .read(catalogProvider.notifier)
                                      .updateProductVariant(
                                        widget.product.id,
                                        size: sz,
                                      );
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Technical Specifications Table
                      Text(
                        'Technical Specifications',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Column(
                          children: widget.product.specs.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 130,
                                    child: Text(
                                      entry.key,
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Customer Reviews Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Verified Reviews (${_reviews.length})',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              WriteReviewModal.show(
                                context,
                                widget.product.id,
                                widget.product.name,
                              ).then((_) => _loadReviews());
                            },
                            icon: const Icon(Icons.rate_review, size: 16),
                            label: const Text('Write Review'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingReviews)
                        const Center(child: CircularProgressIndicator())
                      else if (_reviews.isEmpty)
                        Text(
                          'No reviews yet. Be the first to review!',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reviews.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final rev = _reviews[idx];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        rev.authorName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.onSurface,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        rev.date,
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: List.generate(5, (i) {
                                      return Icon(
                                        i < rev.rating
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: colorScheme.tertiary,
                                        size: 14,
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    rev.comment,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom Action Bar
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
                child: Row(
                  children: [
                    // Quantity Stepper
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                          ),
                          Text(
                            '$_quantity',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                              fontSize: 15,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Add to Cart Button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: () {
                            ref
                                .read(cartProvider.notifier)
                                .addToCart(
                                  widget.product,
                                  quantity: _quantity,
                                  color: _selectedColor,
                                  size: _selectedSize,
                                );
                            Navigator.of(context).pop();
                            AppFeedback.showSuccess(
                              context,
                              'Added $_quantity x ${widget.product.name} to cart.',
                            );
                          },
                          icon: const Icon(Icons.add_shopping_cart),
                          label: Text('Add to Cart ($formattedPrice)'),
                        ),
                      ),
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
