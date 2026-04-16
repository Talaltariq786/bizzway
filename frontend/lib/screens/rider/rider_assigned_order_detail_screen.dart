import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/dev_log.dart';
import '../../core/utils/maps.dart';
import '../../models/order.dart';
import '../../providers/job_provider.dart';
import '../../providers/order_provider.dart';

class RiderAssignedOrderDetailScreen extends StatelessWidget {
  final Order order;
  final bool isPoolOrder;

  const RiderAssignedOrderDetailScreen({
    super.key,
    required this.order,
    required this.isPoolOrder,
  });

  Future<void> _callCustomer(BuildContext context) async {
    final phone = order.customerPhone.trim();
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
    final o = order;
    final accent = isPoolOrder ? AppColors.primary : AppColors.info;
    final canMarkDelivered =
        o.status != OrderStatus.completed && o.status != OrderStatus.cancelled;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Delivery detail'),
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

