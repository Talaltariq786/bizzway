import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/dev_log.dart';
import '../../core/utils/maps.dart';
import '../../models/order.dart';
import '../../providers/business_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/order_provider.dart';

class RiderAssignedOrderDetailScreen extends StatefulWidget {
  final Order order;
  final bool isPoolOrder;

  const RiderAssignedOrderDetailScreen({
    super.key,
    required this.order,
    required this.isPoolOrder,
  });

  @override
  State<RiderAssignedOrderDetailScreen> createState() =>
      _RiderAssignedOrderDetailScreenState();
}

class _RiderAssignedOrderDetailScreenState
    extends State<RiderAssignedOrderDetailScreen> {
  final MapController _mapController = MapController();
  bool _routeMapOpen = false;

  Order get _o => widget.order;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _callCustomer(BuildContext context) async {
    final phone = _o.customerPhone.trim();
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _o;
    final accent = widget.isPoolOrder ? AppColors.primary : AppColors.info;
    final canMarkDelivered =
        o.status != OrderStatus.completed && o.status != OrderStatus.cancelled;

    final biz = context.watch<BusinessProvider>();
    final pickup = LatLng(biz.businessLat, biz.businessLng);
    final dropLat = o.customerLat;
    final dropLng = o.customerLng;
    LatLng? drop;
    if (dropLat != null && dropLng != null) {
      drop = LatLng(dropLat, dropLng);
    }
    final hasRouteCoords = drop != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Delivery detail'),
        actions: [
          if (hasRouteCoords)
            TextButton.icon(
              onPressed: () => setState(() => _routeMapOpen = !_routeMapOpen),
              icon: Icon(
                _routeMapOpen ? Icons.expand_less : Icons.map_rounded,
                size: 20,
              ),
              label: Text(_routeMapOpen ? 'Map band karein' : 'Route map'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(
            title: 'Order',
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    o.id,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accent.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    o.statusLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: accent,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _section(
            title: 'Customer',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line('Name', o.customerName),
                _line('Phone', o.customerPhone),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _callCustomer(context),
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: const Text('Call'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => openDirections(
                          context: context,
                          address: o.customerAddress,
                          lat: o.customerLat,
                          lng: o.customerLng,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.directions_rounded, size: 18),
                        label: const Text('Directions'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _section(
            title: 'Drop-off address',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: hasRouteCoords
                      ? () => setState(() => _routeMapOpen = !_routeMapOpen)
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            (o.customerAddress ?? '').trim().isEmpty
                                ? '—'
                                : o.customerAddress!,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (hasRouteCoords) ...[
                          const SizedBox(width: 8),
                          Icon(
                            _routeMapOpen
                                ? Icons.expand_less_rounded
                                : Icons.route_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!hasRouteCoords) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Is order ke drop coordinates save nahi — sirf text address.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary.withValues(alpha: 0.95),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 6),
                  Text(
                    _routeMapOpen
                        ? 'Shop pin se customer drop tak seedha route (demo line).'
                        : 'Address par tap karein — map par pickup → drop line.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_routeMapOpen && drop != null) ...[
            const SizedBox(height: 12),
            _routeMapCard(pickup, drop),
          ],
          const SizedBox(height: 12),
          _section(
            title: 'Bill',
            child: Column(
              children: [
                ...o.items.map(
                  (it) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${it.quantity}× ${it.productName}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          'Rs ${it.total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 16),
                _kv('Subtotal', 'Rs ${o.subtotal.toStringAsFixed(0)}'),
                _kv('Delivery', 'Rs ${o.deliveryCharge.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _kv(
                  'Total',
                  'Rs ${o.totalAmount.toStringAsFixed(0)}',
                  strong: true,
                ),
              ],
            ),
          ),
          if ((o.notes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _section(
              title: 'Notes',
              child: Text(
                o.notes!,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          if (canMarkDelivered) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final op = context.read<OrderProvider>();
                  final jp = context.read<JobProvider>();
                  try {
                    op.updateStatus(
                      o.id,
                      OrderStatus.completed,
                      jobProvider: jp,
                    );
                    if (context.mounted) {
                      showAppToast(context, 'Delivered — thank you!',
                          success: true);
                      Navigator.pop(context);
                    }
                  } catch (e, st) {
                    devLog('Rider delivered', e, st);
                    if (context.mounted) {
                      showAppToast(context,
                          'Could not update. Check connection & try again.',
                          error: true);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Delivered'),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _routeMapCard(LatLng pickup, LatLng drop) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFE8E8ED)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          SizedBox(
            height: 260,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                backgroundColor: const Color(0xFFF2F3F7),
                initialCameraFit: CameraFit.bounds(
                  bounds: LatLngBounds(pickup, drop),
                  padding: const EdgeInsets.fromLTRB(36, 44, 36, 52),
                ),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.bizzway.bizlabel',
                  maxZoom: 20,
                  maxNativeZoom: 20,
                  retinaMode: true,
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [pickup, drop],
                      color: const Color(0x40000000),
                      strokeWidth: 9,
                    ),
                    Polyline(
                      points: [pickup, drop],
                      color: const Color(0xFF5B4FCF),
                      strokeWidth: 4,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: pickup,
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: _MapPin(
                        icon: Icons.storefront_rounded,
                        color: AppColors.primary,
                        ring: Colors.white,
                      ),
                    ),
                    Marker(
                      point: drop,
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: _MapPin(
                        icon: Icons.location_on_rounded,
                        color: AppColors.error,
                        ring: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 6,
            child: IgnorePointer(
              child: Text(
                'Pickup (shop pin) → drop · © CARTO © OSM',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade800,
                  shadows: const [
                    Shadow(color: Colors.white, blurRadius: 6),
                    Shadow(color: Colors.white, blurRadius: 2),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.05,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _line(String label, String value) => _kv(label, value);

  Widget _kv(String k, String v, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ),
          Text(
            v,
            style: TextStyle(
              fontSize: 12,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.icon,
    required this.color,
    required this.ring,
  });

  final IconData icon;
  final Color color;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: ring,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
