import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../core/utils/maps.dart';

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
    await showAppLoader(context, message: 'Saving...');
    try {
      context.read<OrderProvider>().updateStatus(
            widget.order.id,
            _status,
            etaMinutes: eta,
          );
    } finally {
      hideAppLoader(context);
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
                            await showAppLoader(context, message: 'Accepting...');
                            try {
                              context.read<OrderProvider>().updateStatus(
                                    widget.order.id,
                                    OrderStatus.active,
                                  );
                            } finally {
                              hideAppLoader(context);
                            }
                            if (mounted) {
                              setState(() => _status = OrderStatus.active);
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
                            await showAppLoader(context, message: 'Rejecting...');
                            try {
                              context.read<OrderProvider>().updateStatus(
                                    widget.order.id,
                                    OrderStatus.cancelled,
                                  );
                            } finally {
                              hideAppLoader(context);
                            }
                            if (mounted) {
                              setState(() => _status = OrderStatus.cancelled);
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

