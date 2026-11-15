import 'package:flutter/material.dart';

import '../../../domain/entities/order.dart';

class StatusStepper extends StatelessWidget {
  final OrderFulfillmentStatus currentStatus;

  const StatusStepper({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final steps = [
      {'title': 'Confirmed', 'icon': Icons.receipt_long},
      {'title': 'Picking', 'icon': Icons.inventory_2},
      {'title': 'En Route', 'icon': Icons.delivery_dining},
      {'title': 'Delivered', 'icon': Icons.check_circle},
    ];

    final currentIndex = currentStatus.stepIndex;

    return Row(
      children: List.generate(steps.length, (index) {
        final isDone = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isDone
                          ? (isCurrent
                                ? colorScheme.primary
                                : colorScheme.primaryContainer)
                          : colorScheme.surfaceContainerHighest,
                      child: Icon(
                        steps[index]['icon'] as IconData,
                        size: 16,
                        color: isDone
                            ? (isCurrent
                                  ? colorScheme.onPrimary
                                  : colorScheme.onPrimaryContainer)
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[index]['title'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isCurrent
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isDone
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1)
                Container(
                  width: 14,
                  height: 2,
                  color: index < currentIndex
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                ),
            ],
          ),
        );
      }),
    );
  }
}
