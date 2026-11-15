class PromoCode {
  final String code;
  final double discountPercent;
  final double flatDiscountUsd;
  final bool isFreeShipping;
  final double minSubtotalUsd;
  final String description;

  const PromoCode({
    required this.code,
    this.discountPercent = 0.0,
    this.flatDiscountUsd = 0.0,
    this.isFreeShipping = false,
    this.minSubtotalUsd = 0.0,
    required this.description,
  });

  static const List<PromoCode> availableCodes = [
    PromoCode(
      code: 'SAVE20',
      discountPercent: 20.0,
      description: '20% off entire order subtotal',
    ),
    PromoCode(
      code: 'FREESHIP',
      isFreeShipping: true,
      description: 'Free 15-minute express delivery fee',
    ),
    PromoCode(
      code: 'VIP15',
      discountPercent: 15.0,
      description: '15% exclusive retail VIP privilege',
    ),
  ];

  static PromoCode? match(String input) {
    final clean = input.trim().toUpperCase();
    for (final promo in availableCodes) {
      if (promo.code == clean) {
        return promo;
      }
    }
    return null;
  }
}
