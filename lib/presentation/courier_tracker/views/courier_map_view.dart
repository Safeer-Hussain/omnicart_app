import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/order.dart';
import '../notifiers/order_tracker_notifier.dart';
import '../widgets/digital_receipt_sheet.dart';
import '../widgets/status_stepper.dart';

class CourierMapView extends ConsumerStatefulWidget {
  const CourierMapView({super.key});

  @override
  ConsumerState<CourierMapView> createState() => _CourierMapViewState();
}

class _CourierMapViewState extends ConsumerState<CourierMapView> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final trackerState = ref.watch(orderTrackerProvider);
    final currency = ref.watch(currencyProvider);

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final selectedOrder = trackerState.selectedOrder;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'fab_courier_recenter',
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        tooltip: 'Recenter on Courier',
        onPressed: () {
          _mapController.move(
            LatLng(
              trackerState.currentCourierLat,
              trackerState.currentCourierLng,
            ),
            14.0,
          );
        },
        child: const Icon(Icons.my_location),
      ),
      body: SafeArea(
        child: selectedOrder == null
            ? const Center(child: CircularProgressIndicator())
            : isLandscape
            ? _buildLandscapeLayout(
                context,
                ref,
                colorScheme,
                trackerState,
                selectedOrder,
              )
            : _buildPortraitLayout(
                context,
                ref,
                colorScheme,
                trackerState,
                selectedOrder,
                currency,
              ),
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    OrderTrackerState trackerState,
    CustomerOrder selectedOrder,
    AppCurrency currency,
  ) {
    return Column(
      children: [
        // Top Order Header & Status Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active 15-Minute Courier Track',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Order #${selectedOrder.id} (${CurrencyFormatter.format(selectedOrder.totalUsd, currency)})',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.receipt_outlined, size: 18),
                        tooltip: 'View Invoice',
                        onPressed: () =>
                            DigitalReceiptSheet.show(context, selectedOrder),
                      ),
                      const SizedBox(width: 6),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: trackerState.isSimulatingDelivery
                              ? colorScheme.error
                              : colorScheme.primary,
                          foregroundColor: trackerState.isSimulatingDelivery
                              ? colorScheme.onError
                              : colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                        onPressed: () {
                          ref
                              .read(orderTrackerProvider.notifier)
                              .toggleSimulateDelivery();
                        },
                        icon: Icon(
                          trackerState.isSimulatingDelivery
                              ? Icons.pause
                              : Icons.play_arrow,
                          size: 16,
                        ),
                        label: Text(
                          trackerState.isSimulatingDelivery
                              ? 'Stop'
                              : 'Simulate',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Live Status Stepper
              StatusStepper(currentStatus: selectedOrder.status),
              const SizedBox(height: 10),

              // Live Telemetry Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.directions_bike,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${trackerState.remainingDistanceKm.toStringAsFixed(1)} km away',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          selectedOrder.status ==
                                  OrderFulfillmentStatus.delivered
                              ? 'Delivered'
                              : 'ETA: ~${trackerState.estimatedMinutesRemaining} mins',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Interactive Map
        Expanded(child: _buildMapCanvas(colorScheme, trackerState)),

        // Courier Contact Footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedOrder.courierName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Assigned Courier | ${selectedOrder.courierPhone}',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
                onPressed: () {
                  _showPastOrdersDialog(context, ref);
                },
                icon: const Icon(Icons.history, size: 16),
                label: const Text('History', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    OrderTrackerState trackerState,
    CustomerOrder selectedOrder,
  ) {
    return Row(
      children: [
        // Left Pane: Controls & Status
        Expanded(
          flex: 2,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            children: [
              Text(
                'Live Courier Track - #${selectedOrder.id}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              StatusStepper(currentStatus: selectedOrder.status),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trackerState.remainingDistanceKm.toStringAsFixed(1)} km remaining',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'ETA: ~${trackerState.estimatedMinutesRemaining} mins',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: trackerState.isSimulatingDelivery
                            ? colorScheme.error
                            : colorScheme.primary,
                        foregroundColor: trackerState.isSimulatingDelivery
                            ? colorScheme.onError
                            : colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                        ref
                            .read(orderTrackerProvider.notifier)
                            .toggleSimulateDelivery();
                      },
                      icon: Icon(
                        trackerState.isSimulatingDelivery
                            ? Icons.pause
                            : Icons.play_arrow,
                        size: 16,
                      ),
                      label: Text(
                        trackerState.isSimulatingDelivery ? 'Stop' : 'Simulate',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.receipt_outlined, size: 18),
                    onPressed: () =>
                        DigitalReceiptSheet.show(context, selectedOrder),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _showPastOrdersDialog(context, ref),
                icon: const Icon(Icons.history, size: 16),
                label: const Text('Past Orders'),
              ),
            ],
          ),
        ),

        VerticalDivider(color: colorScheme.outlineVariant, width: 1),

        // Right Pane: Full Interactive Map
        Expanded(flex: 3, child: _buildMapCanvas(colorScheme, trackerState)),
      ],
    );
  }

  Widget _buildMapCanvas(
    ColorScheme colorScheme,
    OrderTrackerState trackerState,
  ) {
    const darkStorePos = LatLng(
      AppConstants.darkStoreLatitude,
      AppConstants.darkStoreLongitude,
    );
    const customerPos = LatLng(
      AppConstants.defaultCustomerLatitude,
      AppConstants.defaultCustomerLongitude,
    );
    final courierPos = LatLng(
      trackerState.currentCourierLat,
      trackerState.currentCourierLng,
    );

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: courierPos, initialZoom: 13.5),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.safeer.omnicart',
        ),

        // Polyline Route
        PolylineLayer(
          polylines: [
            Polyline(
              points: OrderTrackerNotifier.deliveryRoute,
              strokeWidth: 4.5,
              color: colorScheme.primary,
            ),
          ],
        ),

        // Map Pins
        MarkerLayer(
          markers: [
            // Dark Store Marker
            Marker(
              point: darkStorePos,
              width: 38,
              height: 38,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.secondary, width: 2),
                ),
                child: Icon(
                  Icons.warehouse,
                  color: colorScheme.secondary,
                  size: 20,
                ),
              ),
            ),

            // Customer Destination Marker
            Marker(
              point: customerPos,
              width: 38,
              height: 38,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.tertiary, width: 2),
                ),
                child: Icon(Icons.home, color: colorScheme.tertiary, size: 20),
              ),
            ),

            // Moving Courier Rider Marker
            Marker(
              point: courierPos,
              width: 44,
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withAlpha(120),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.delivery_dining,
                  color: colorScheme.onPrimary,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showPastOrdersDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final orders = ref.read(orderTrackerProvider).orders;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Order History & Fulfillment Archive',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Divider(color: colorScheme.outlineVariant),
              Expanded(
                child: ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (context, index) =>
                      Divider(color: colorScheme.outlineVariant),
                  itemBuilder: (c, idx) {
                    final o = orders[idx];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      title: Text(
                        'Order #${o.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        '${o.items.length} items | ${o.status.label} | \$${o.totalUsd.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ref
                            .read(orderTrackerProvider.notifier)
                            .selectOrder(o.id);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
