class Review {
  final String id;
  final String productId;
  final String authorName;
  final double rating;
  final String date;
  final String comment;
  final bool isVerifiedPurchase;

  const Review({
    required this.id,
    required this.productId,
    required this.authorName,
    required this.rating,
    required this.date,
    required this.comment,
    this.isVerifiedPurchase = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'author_name': authorName,
      'rating': rating,
      'date': date,
      'comment': comment,
      'is_verified': isVerifiedPurchase ? 1 : 0,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      authorName: map['author_name'] as String,
      rating: (map['rating'] as num).toDouble(),
      date: map['date'] as String,
      comment: map['comment'] as String,
      isVerifiedPurchase: (map['is_verified'] as int? ?? 1) == 1,
    );
  }
}
