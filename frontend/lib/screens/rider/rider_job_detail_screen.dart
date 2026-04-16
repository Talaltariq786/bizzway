import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/maps.dart';
import '../../models/job_request.dart';
import '../../providers/job_provider.dart';
import '../../widgets/common/loading_overlay.dart';

class RiderJobDetailScreen extends StatefulWidget {
  const RiderJobDetailScreen({super.key, required this.request});

  final JobRequest request;

  @override
  State<RiderJobDetailScreen> createState() => _RiderJobDetailScreenState();
}

Color _categoryColor(String? cat) {
  switch (cat) {
    case 'restaurant':
      return const Color(0xFFE91E63);
    case 'grocery':
      return const Color(0xFF2E7D32);
    case 'pharmacy':
      return const Color(0xFF00897B);
    default:
      return AppColors.primary;
  }
}

Color _categoryTint(String? cat) =>
    _categoryColor(cat).withValues(alpha: 0.12);

class _RiderJobDetailScreenState extends State<RiderJobDetailScreen> {
  final MapController _mapController = MapController();

  JobRequest get r => widget.request;

  LatLng? get _origin {
    final la = r.originLat ?? r.destLat;
    final ln = r.originLng ?? r.destLng;
    if (la == null || ln == null) return null;
    return LatLng(la, ln);
  }

  LatLng? get _dest {
    if (r.destLat == null || r.destLng == null) return null;
    return LatLng(r.destLat!, r.destLng!);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    await showAppLoader(context, message: 'Accepting...');
    if (!mounted) return;
    try {
      context.read<JobProvider>().accept(r.id, estimatedMins: 25);
    } finally {
      if (mounted) hideAppLoader(context);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  Widget _billRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'Rs. ${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _dialCustomerPhone(String raw) async {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _reject() async {
    await showAppLoader(context, message: 'Rejecting...');
    if (!mounted) return;
    try {
      context.read<JobProvider>().reject(r.id);
    } finally {
      if (mounted) hideAppLoader(context);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final o = _origin;
    final d = _dest;
    final hasRoute = o != null && d != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Delivery details'),
        actions: [
          TextButton.icon(
            onPressed: () => openDirections(
              context: context,
              address: r.userAddress,
              lat: r.destLat,
              lng: r.destLng,
            ),
            icon: const Icon(Icons.navigation_rounded, size: 20),
            label: const Text('Google Maps'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        r.serviceTypeName,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (r.isRiderJob) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _categoryTint(r.deliveryCategory),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          r.deliveryCategoryLabel,
                          style: TextStyle(
                            color: _categoryColor(r.deliveryCategory),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      r.timeAgo,
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                    ),
                  ],
                ),
                if ((r.customerName ?? '').isNotEmpty ||
                    (r.customerPhone ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Customer',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if ((r.customerName ?? '').isNotEmpty)
                    Text(
                      r.customerName!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  if ((r.customerPhone ?? '').isNotEmpty) ...[
                    if ((r.customerName ?? '').isNotEmpty)
                      const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _dialCustomerPhone(r.customerPhone!),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone_in_talk_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                r.customerPhone!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.primary,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.call_rounded,
                              size: 20,
                              color: AppColors.success,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 10),
                const Text(
                  'Address',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  r.userAddress,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Order',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  r.issue,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                ),
                if (r.orderItems.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...r.orderItems.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: AppColors.primary)),
                          Expanded(
                            child: Text(
                              line,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (r.grandTotal != null) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  const Text(
                    'Bill',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (r.itemsTotal != null)
                    _billRow('Items total', r.itemsTotal!),
                  if (r.deliveryFee != null)
                    _billRow('Delivery charges', r.deliveryFee!),
                  if ((r.serviceFee ?? 0) > 0)
                    _billRow('Service fee', r.serviceFee!),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Rs. ${r.grandTotal!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (hasRoute) ...[
            Row(
              children: [
                const Icon(Icons.route_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Pickup se drop tak route',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
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
                    height: 280,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        backgroundColor: const Color(0xFFF2F3F7),
                        initialCameraFit: CameraFit.bounds(
                          bounds: LatLngBounds(o, d),
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
                              points: [o, d],
                              color: const Color(0x40000000),
                              strokeWidth: 9,
                            ),
                            Polyline(
                              points: [o, d],
                              color: const Color(0xFF5B4FCF),
                              strokeWidth: 4,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: o,
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              child: _MapPin(
                                icon: Icons.two_wheeler_rounded,
                                color: AppColors.primary,
                                ring: Colors.white,
                              ),
                            ),
                            Marker(
                              point: d,
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
                        '© CARTO © OpenStreetMap contributors',
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
            ),
            const SizedBox(height: 10),
            Material(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  _mapController.fitCamera(
                    CameraFit.bounds(
                      bounds: LatLngBounds(o, d),
                      padding: const EdgeInsets.fromLTRB(32, 40, 32, 48),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  child: Row(
                    children: [
                      Icon(Icons.center_focus_strong_rounded,
                          color: AppColors.primary, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Route map dubara center karein',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Is order ke liye map coordinates set nahi — sirf address dikha rahe hain.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          const SizedBox(height: 16),
          if (r.isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _accept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                    label: const Text('Accept', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
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
