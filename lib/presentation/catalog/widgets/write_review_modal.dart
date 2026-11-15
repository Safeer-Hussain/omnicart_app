import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../domain/entities/review.dart';
import '../notifiers/catalog_notifier.dart';

class WriteReviewModal extends ConsumerStatefulWidget {
  final String productId;
  final String productName;

  const WriteReviewModal({
    super.key,
    required this.productId,
    required this.productName,
  });

  static Future<void> show(
    BuildContext context,
    String productId,
    String productName,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          WriteReviewModal(productId: productId, productName: productName),
    );
  }

  @override
  ConsumerState<WriteReviewModal> createState() => _WriteReviewModalState();
}

class _WriteReviewModalState extends ConsumerState<WriteReviewModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();
  double _selectedRating = 5.0;

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _submitReview() {
    if (!_formKey.currentState!.validate()) return;

    final review = Review(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      productId: widget.productId,
      authorName: _nameController.text.trim(),
      rating: _selectedRating,
      date: 'Just now',
      comment: _commentController.text.trim(),
      isVerifiedPurchase: true,
    );

    ref.read(catalogProvider.notifier).addReview(review);
    Navigator.of(context).pop();
    AppFeedback.showSuccess(context, 'Verified review submitted successfully.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            child: Form(
              key: _formKey,
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
                    'Write Verified Review',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.productName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rating Star Selector
                  Text('Overall Rating', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      final starValue = index + 1.0;
                      return IconButton(
                        icon: Icon(
                          starValue <= _selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: colorScheme.tertiary,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() => _selectedRating = starValue);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Your Name or Pseudonym',
                      hintText: 'e.g., Safeer H.',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please provide your name';
                      }
                      if (val.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Comment Field
                  TextFormField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Your Review Feedback',
                      hintText: 'How was the product performance and delivery?',
                      alignLabelWithHint: true,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter review comments';
                      }
                      if (val.trim().length < 10) {
                        return 'Feedback must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _submitReview,
                      icon: const Icon(Icons.rate_review),
                      label: const Text('Submit Verified Review'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
