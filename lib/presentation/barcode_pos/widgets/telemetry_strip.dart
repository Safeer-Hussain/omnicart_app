import 'package:flutter/material.dart';

import '../../../domain/entities/dark_store_metric.dart';

class TelemetryStrip extends StatelessWidget {
  final DarkStoreMetric metric;
  final bool hasColdChainAlert;
  final String? coldChainAlertMessage;

  const TelemetryStrip({
    super.key,
    required this.metric,
    this.hasColdChainAlert = false,
    this.coldChainAlertMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isColdChainDeviation =
        hasColdChainAlert ||
        metric.coldZoneTempCelsius > 4.0 ||
        metric.coldZoneTempCelsius < 1.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isColdChainDeviation
              ? colorScheme.error
              : colorScheme.outlineVariant,
          width: isColdChainDeviation ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isColdChainDeviation
                            ? colorScheme.error
                            : colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'DARK-STORE HARDWARE TELEMETRY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: isColdChainDeviation
                            ? colorScheme.error
                            : colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Text(
                  metric.warehouseZone,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 340,
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Pack Time',
                      value: '${metric.averagePackTimeSeconds}s',
                      icon: Icons.timer,
                      colorScheme: colorScheme,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Cold-Chain',
                      value:
                          '${metric.coldZoneTempCelsius.toStringAsFixed(1)} °C',
                      icon: Icons.ac_unit,
                      colorScheme: colorScheme,
                      isWarning: isColdChainDeviation,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'NFC Terminal',
                      value: metric.nfcTerminalReady ? 'Online' : 'Offline',
                      icon: Icons.contactless,
                      colorScheme: colorScheme,
                      isStatus: true,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Active Pickers',
                      value: '${metric.activePickers}',
                      icon: Icons.badge_outlined,
                      colorScheme: colorScheme,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isColdChainDeviation) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      coldChainAlertMessage ??
                          'Cold-chain temperature deviation: ${metric.coldZoneTempCelsius.toStringAsFixed(1)} °C exceeds 4.0 °C safety limit.',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required ColorScheme colorScheme,
    bool isStatus = false,
    bool isWarning = false,
  }) {
    final iconColor = isWarning
        ? colorScheme.error
        : (isStatus ? colorScheme.primary : colorScheme.secondary);

    final textColor = isWarning ? colorScheme.error : colorScheme.onSurface;

    return Column(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isWarning ? colorScheme.error : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
