import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/dev_log.dart';
import '../../models/order.dart';
import '../../providers/job_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../core/utils/maps.dart';
import '../../widgets/orders/assign_rider_sheet.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late OrderStatus _status;
  final _etaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _status = widget.order.status;
    _etaCtrl.text = widget.order.etaMinutes?.toString() ?? '';
  }

  @override
  void dispose() {
    _etaCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final eta = int.tryParse(_etaCtrl.text.trim());
    final op = context.read<OrderProvider>();
    final jp = context.read<JobProvider>();
    await showAppLoader(context, message: 'Saving...');
    if (!context.mounted) return;
    try {
      op.updateStatus(
        widget.order.id,
        _status,
        etaMinutes: eta,
        jobProvider: jp,
      );
      if (mounted) {
        showAppToast(context, 'Order updated', success: true);
      }
    } catch (e, st) {
      devLog('OrderDetail save', e, st);
      if (mounted) {
        showAppToast(context, 'Could not save. Try again.', error: true);
      }
      return;
    } finally {
      if (mounted) hideAppLoader(context);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.id,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  '${o.customerName} • ${o.customerPhone}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('d MMM yyyy • h:mm a').format(o.createdAt),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                const Divider(),
                ...o.items.map((it) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${it.productName} × ${it.quantity}',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textPrimary),
                            ),
                          ),
                          Text(
                            'Rs. ${it.total.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text('Rs. ${o.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 12),
                if (o.customerAddress != null && o.customerAddress!.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 18, color: AppColors.info),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          o.customerAddress!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => openDirections(
                          context: context,
                          address: o.customerAddress,
                          lat: o.customerLat,
                          lng: o.customerLng,
                        ),
                        icon: const Icon(Icons.directions_rounded, size: 18),
                        label: const Text('Navigate'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (o.isDelivery) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.22),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.delivery_dining_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Delivery',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (o.deliveryCharge > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Delivery charges: Rs. ${o.deliveryCharge.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (o.assignedRiderName != null &&
                      (o.assignedRiderName ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Assigned rider: ${o.assignedRiderName}'
                      '${o.assignedRiderId != null ? ' · ID: ${o.assignedRiderId}' : ''}'
                      ' · ${o.assignedRiderPhone ?? ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                  if (o.status != OrderStatus.completed &&
                      o.status != OrderStatus.cancelled) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => assignRiderToOrder(context, o.id),
                        icon: const Icon(Icons.pedal_bike_rounded, size: 20),
                        label: Text(
                          (o.assignedRiderName == null ||
                                  (o.assignedRiderName ?? '').isEmpty)
                              ? 'Rider assign karein'
                              : 'Rider change karein',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Update Status',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final op = context.read<OrderProvider>();
                            final jp = context.read<JobProvider>();
                            await showAppLoader(context, message: 'Accepting...');
                            if (!context.mounted) return;
                            try {
                              op.updateStatus(
                                widget.order.id,
                                OrderStatus.active,
                                jobProvider: jp,
                              );
                              if (mounted) {
                                showAppToast(context, 'Order accepted',
                                    success: true);
                                setState(() => _status = OrderStatus.active);
                              }
                            } catch (e, st) {
                              devLog('OrderDetail accept', e, st);
                              if (mounted) {
                                showAppToast(context,
                                    'Could not accept. Try again.',
                                    error: true);
                              }
                            } finally {
                              if (mounted) hideAppLoader(context);
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('Accept'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final op = context.read<OrderProvider>();
                            final jp = context.read<JobProvider>();
                            await showAppLoader(context, message: 'Rejecting...');
                            if (!context.mounted) return;
                            try {
                              op.updateStatus(
                                widget.order.id,
                                OrderStatus.cancelled,
                                jobProvider: jp,
                              );
                              if (mounted) {
                                showAppToast(context, 'Order rejected',
                                    success: true);
                                setState(() => _status = OrderStatus.cancelled);
                              }
                            } catch (e, st) {
                              devLog('OrderDetail reject', e, st);
                              if (mounted) {
                                showAppToast(context,
                                    'Could not reject. Try again.',
                                    error: true);
                              }
                            } finally {
                              if (mounted) hideAppLoader(context);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Reject'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                DropdownButtonFormField<OrderStatus>(
                  value: _status,
                  items: OrderStatus.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _status = v ?? _status),
                  decoration: const InputDecoration(
                    labelText: 'Status',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _etaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ETA (minutes)',
                    hintText: 'e.g. 30',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

