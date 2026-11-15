class Product {
  final String id;
  final String name;
  final String description;
  final String brand;
  final String category;
  final double priceUsd;
  final double originalPriceUsd;
  final double rating;
  final int reviewCount;
  final bool isFlashSale;
  final bool isExpressDelivery;
  final int darkStoreStock;
  final String aisleLocation;
  final String upcBarcode;
  final double competitorPriceUsd;
  final String competitorName;
  final List<String> availableColors;
  final List<String> availableSizes;
  final String selectedColor;
  final String selectedSize;
  final Map<String, String> specs;
  final String imageAsset;
  final bool isWishlisted;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.brand,
    required this.category,
    required this.priceUsd,
    required this.originalPriceUsd,
    required this.rating,
    required this.reviewCount,
    required this.isFlashSale,
    required this.isExpressDelivery,
    required this.darkStoreStock,
    required this.aisleLocation,
    required this.upcBarcode,
    required this.competitorPriceUsd,
    required this.competitorName,
    required this.availableColors,
    required this.availableSizes,
    required this.selectedColor,
    required this.selectedSize,
    required this.specs,
    required this.imageAsset,
    this.isWishlisted = false,
  });

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? brand,
    String? category,
    double? priceUsd,
    double? originalPriceUsd,
    double? rating,
    int? reviewCount,
    bool? isFlashSale,
    bool? isExpressDelivery,
    int? darkStoreStock,
    String? aisleLocation,
    String? upcBarcode,
    double? competitorPriceUsd,
    String? competitorName,
    List<String>? availableColors,
    List<String>? availableSizes,
    String? selectedColor,
    String? selectedSize,
    Map<String, String>? specs,
    String? imageAsset,
    bool? isWishlisted,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      priceUsd: priceUsd ?? this.priceUsd,
      originalPriceUsd: originalPriceUsd ?? this.originalPriceUsd,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isFlashSale: isFlashSale ?? this.isFlashSale,
      isExpressDelivery: isExpressDelivery ?? this.isExpressDelivery,
      darkStoreStock: darkStoreStock ?? this.darkStoreStock,
      aisleLocation: aisleLocation ?? this.aisleLocation,
      upcBarcode: upcBarcode ?? this.upcBarcode,
      competitorPriceUsd: competitorPriceUsd ?? this.competitorPriceUsd,
      competitorName: competitorName ?? this.competitorName,
      availableColors: availableColors ?? this.availableColors,
      availableSizes: availableSizes ?? this.availableSizes,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedSize: selectedSize ?? this.selectedSize,
      specs: specs ?? this.specs,
      imageAsset: imageAsset ?? this.imageAsset,
      isWishlisted: isWishlisted ?? this.isWishlisted,
    );
  }

  double get discountPercent {
    if (originalPriceUsd <= priceUsd) return 0;
    return ((originalPriceUsd - priceUsd) / originalPriceUsd) * 100;
  }

  double get competitorSavingsPercent {
    if (competitorPriceUsd <= priceUsd) return 0;
    return ((competitorPriceUsd - priceUsd) / competitorPriceUsd) * 100;
  }
}
