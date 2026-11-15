import 'package:flutter/material.dart';

import '../../../domain/entities/dark_store_metric.dart';

class TelemetryStrip extends StatelessWidget {
  final DarkStoreMetric metric;

  const TelemetryStrip({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
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
                        color: colorScheme.primary,
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
                        color: colorScheme.primary,
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
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: isStatus ? colorScheme.primary : colorScheme.secondary,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
