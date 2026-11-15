import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../ai_copilot/views/ai_shopping_copilot_view.dart';
import '../barcode_pos/views/barcode_pos_view.dart';
import '../cart_checkout/notifiers/cart_notifier.dart';
import '../cart_checkout/views/cart_view.dart';
import '../catalog/views/catalog_view.dart';
import '../courier_tracker/views/courier_map_view.dart';
import '../settings/recruiter_debug_drawer.dart';
import 'navigation_provider.dart';

class AdaptiveScaffold extends ConsumerStatefulWidget {
  const AdaptiveScaffold({super.key});

  @override
  ConsumerState<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends ConsumerState<AdaptiveScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final connectivity = Connectivity();
    final results = await connectivity.checkConnectivity();
    _handleConnectivityResults(results);

    _connectivitySub = connectivity.onConnectivityChanged.listen(
      _handleConnectivityResults,
    );
  }

  void _handleConnectivityResults(List<ConnectivityResult> results) {
    final offline =
        results.contains(ConnectivityResult.none) || results.isEmpty;
    if (mounted && offline != _isOffline) {
      setState(() => _isOffline = offline);
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  final List<Widget> _destinations = const [
    CatalogView(),
    CartView(),
    CourierMapView(),
    BarcodePosView(),
    AiShoppingCopilotView(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedIndex = ref.watch(navigationProvider);
    final cartItemCount = ref.watch(cartProvider).totalItemCount;
    final currency = ref.watch(currencyProvider);
    final themeMode = ref.watch(themeModeProvider);

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: colorScheme.surface,
        endDrawer: const RecruiterDebugDrawer(),
        appBar: AppBar(
          toolbarHeight: isLandscape ? 36 : 48,
          title: Row(
            children: [
              Icon(
                Icons.shopping_bag,
                color: colorScheme.primary,
                size: isLandscape ? 18 : 22,
              ),
              const SizedBox(width: 8),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isLandscape ? 14 : 18,
                  letterSpacing: -0.5,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '15-MIN',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontSize: isLandscape ? 8 : 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            // Currency Toggle
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                ref.read(currencyProvider.notifier).toggleCurrency();
              },
              child: Text(
                currency == AppCurrency.usd ? 'USD' : 'PKR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isLandscape ? 11 : 13,
                  color: colorScheme.primary,
                ),
              ),
            ),

            // Theme Toggle
            IconButton(
              iconSize: isLandscape ? 18 : 20,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              icon: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
                color: colorScheme.onSurface,
              ),
              onPressed: () {
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
            ),

            // Recruiter Debug Console Drawer
            IconButton(
              iconSize: isLandscape ? 18 : 20,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              icon: Icon(Icons.tune, color: colorScheme.secondary),
              tooltip: 'Recruiter Debug Console',
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Animated Offline Banner
            if (_isOffline)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                color: colorScheme.errorContainer,
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 16,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Offline Catalog Mode - Browsing Cached SKUs, Wishlist & Saved Cart in Local SQLite',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Main Content Area (Portrait vs Landscape NavigationRail)
            Expanded(
              child: isLandscape
                  ? Row(
                      children: [
                        // Compact Landscape NavigationRail wrapped in SingleChildScrollView + IntrinsicHeight
                        SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight:
                                  MediaQuery.of(context).size.height -
                                  (isLandscape ? 36 : 48),
                            ),
                            child: IntrinsicHeight(
                              child: NavigationRail(
                                minWidth: 56,
                                labelType: NavigationRailLabelType.none,
                                backgroundColor: colorScheme.surface,
                                selectedIndex: selectedIndex,
                                onDestinationSelected: (idx) {
                                  ref
                                      .read(navigationProvider.notifier)
                                      .selectTab(idx);
                                },
                                destinations: [
                                  const NavigationRailDestination(
                                    icon: Icon(
                                      Icons.storefront_outlined,
                                      size: 20,
                                    ),
                                    selectedIcon: Icon(
                                      Icons.storefront,
                                      size: 20,
                                    ),
                                    label: Text('Catalog'),
                                  ),
                                  NavigationRailDestination(
                                    icon: Badge(
                                      isLabelVisible: cartItemCount > 0,
                                      label: Text('$cartItemCount'),
                                      child: const Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 20,
                                      ),
                                    ),
                                    selectedIcon: Badge(
                                      isLabelVisible: cartItemCount > 0,
                                      label: Text('$cartItemCount'),
                                      child: const Icon(
                                        Icons.shopping_bag,
                                        size: 20,
                                      ),
                                    ),
                                    label: const Text('Cart'),
                                  ),
                                  const NavigationRailDestination(
                                    icon: Icon(
                                      Icons.delivery_dining_outlined,
                                      size: 20,
                                    ),
                                    selectedIcon: Icon(
                                      Icons.delivery_dining,
                                      size: 20,
                                    ),
                                    label: Text('Tracker'),
                                  ),
                                  const NavigationRailDestination(
                                    icon: Icon(Icons.qr_code_scanner, size: 20),
                                    selectedIcon: Icon(
                                      Icons.qr_code_scanner,
                                      size: 20,
                                    ),
                                    label: Text('POS'),
                                  ),
                                  const NavigationRailDestination(
                                    icon: Icon(
                                      Icons.smart_toy_outlined,
                                      size: 20,
                                    ),
                                    selectedIcon: Icon(
                                      Icons.smart_toy,
                                      size: 20,
                                    ),
                                    label: Text('Copilot'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        VerticalDivider(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                        Expanded(
                          child: IndexedStack(
                            index: selectedIndex,
                            children: _destinations,
                          ),
                        ),
                      ],
                    )
                  : IndexedStack(index: selectedIndex, children: _destinations),
            ),
          ],
        ),
        bottomNavigationBar: isLandscape
            ? null
            : NavigationBar(
                selectedIndex: selectedIndex,
                height: 64,
                backgroundColor: colorScheme.surface,
                indicatorColor: colorScheme.primaryContainer,
                onDestinationSelected: (idx) {
                  ref.read(navigationProvider.notifier).selectTab(idx);
                },
                destinations: [
                  const NavigationRequestDestination(
                    icon: Icon(Icons.storefront_outlined),
                    selectedIcon: Icon(Icons.storefront),
                    label: 'Store',
                  ),
                  NavigationRequestDestination(
                    icon: Badge(
                      isLabelVisible: cartItemCount > 0,
                      label: Text('$cartItemCount'),
                      child: const Icon(Icons.shopping_bag_outlined),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: cartItemCount > 0,
                      label: Text('$cartItemCount'),
                      child: const Icon(Icons.shopping_bag),
                    ),
                    label: 'Cart',
                  ),
                  const NavigationRequestDestination(
                    icon: Icon(Icons.delivery_dining_outlined),
                    selectedIcon: Icon(Icons.delivery_dining),
                    label: 'Courier',
                  ),
                  const NavigationRequestDestination(
                    icon: Icon(Icons.qr_code_scanner),
                    selectedIcon: Icon(Icons.qr_code_scanner),
                    label: 'Scanner',
                  ),
                  const NavigationRequestDestination(
                    icon: Icon(Icons.smart_toy_outlined),
                    selectedIcon: Icon(Icons.smart_toy),
                    label: 'Copilot',
                  ),
                ],
              ),
      ),
    );
  }
}

class NavigationRequestDestination extends NavigationDestination {
  const NavigationRequestDestination({
    super.key,
    required super.icon,
    super.selectedIcon,
    required super.label,
  });
}
