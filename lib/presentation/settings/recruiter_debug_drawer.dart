import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../core/utils/app_feedback.dart';
import '../catalog/notifiers/catalog_notifier.dart';

class RecruiterDebugDrawer extends ConsumerStatefulWidget {
  const RecruiterDebugDrawer({super.key});

  @override
  ConsumerState<RecruiterDebugDrawer> createState() =>
      _RecruiterDebugDrawerState();
}

class _RecruiterDebugDrawerState extends ConsumerState<RecruiterDebugDrawer> {
  int _latencyMs = 500;
  bool _force503 = false;
  bool _flashSaleActive = false;

  @override
  void initState() {
    super.initState();
    _loadDebugSettings();
  }

  Future<void> _loadDebugSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _latencyMs = prefs.getInt(AppConstants.prefSimulatedLatency) ?? 500;
      _force503 = prefs.getBool(AppConstants.prefForce503) ?? false;
      _flashSaleActive =
          prefs.getBool(AppConstants.prefFlashSaleDiscount) ?? false;
    });
  }

  Future<void> _updateLatency(int val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefSimulatedLatency, val);
    setState(() => _latencyMs = val);
  }

  Future<void> _toggleForce503(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefForce503, val);
    setState(() => _force503 = val);
  }

  Future<void> _toggleFlashSale(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefFlashSaleDiscount, val);
    setState(() => _flashSaleActive = val);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = ref.watch(currencyProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            Row(
              children: [
                Icon(Icons.terminal, color: colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recruiter Debug Console',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Offline Architecture & Stress Tools',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: colorScheme.outlineVariant),
            const SizedBox(height: 12),

            // Theme & Currency Toggles
            Text(
              'ENVIRONMENT CONTROLS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: colorScheme.secondary,
              ),
              title: Text(
                'Obsidian / Crisp Mode',
                style: theme.textTheme.bodyMedium,
              ),
              trailing: Switch(
                value: themeMode == ThemeMode.dark,
                onChanged: (val) {
                  ref.read(themeModeProvider.notifier).toggleTheme();
                },
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.currency_exchange,
                color: colorScheme.secondary,
              ),
              title: Text(
                'Multi-Currency (${currency.code})',
                style: theme.textTheme.bodyMedium,
              ),
              trailing: OutlinedButton(
                onPressed: () {
                  ref.read(currencyProvider.notifier).toggleCurrency();
                },
                child: Text('${currency.code} (${currency.symbol.trim()})'),
              ),
            ),

            const SizedBox(height: 16),
            Divider(color: colorScheme.outlineVariant),
            const SizedBox(height: 12),

            // Network latency simulation
            Text(
              'SIMULATED NETWORK LATENCY (DIO)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Current latency: ${_latencyMs}ms',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Slider(
              value: _latencyMs.toDouble(),
              min: 100,
              max: 2000,
              divisions: 19,
              activeColor: colorScheme.primary,
              label: '${_latencyMs}ms',
              onChanged: (val) => _updateLatency(val.toInt()),
            ),

            const SizedBox(height: 16),
            Divider(color: colorScheme.outlineVariant),
            const SizedBox(height: 12),

            // Fault Injection: Force HTTP 503
            Text(
              'FAULT INJECTION & RESILIENCE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Force HTTP 503 on Checkout',
                style: theme.textTheme.bodyMedium,
              ),
              subtitle: Text(
                'Simulate dark-store cluster capacity overload and retry flow',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              value: _force503,
              activeColor: colorScheme.error,
              onChanged: _toggleForce503,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Inject Flash-Sale Price Drops',
                style: theme.textTheme.bodyMedium,
              ),
              subtitle: Text(
                'Trigger instant 15% markdown across all catalog SKUs',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              value: _flashSaleActive,
              activeColor: colorScheme.tertiary,
              onChanged: (val) {
                _toggleFlashSale(val);
                ref.read(catalogProvider.notifier).loadCatalog();
                AppFeedback.showInfo(
                  context,
                  val
                      ? 'Simulated flash-sale markdown active!'
                      : 'Standard pricing restored.',
                );
              },
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BUILD & ARCHITECTURE INFO',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'App Version: ${AppConstants.appVersion}',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    'Compile Target: Android SDK 36 (Android 15+)',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    'State Engine: Riverpod 2.6 (NotifierProvider)',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    'Local Storage: sqflite 2.4 + SharedPreferences',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    'Hardware Bridge: MethodChannel & EventChannel',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
