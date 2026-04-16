import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/dev_log.dart';
import '../common/loading_overlay.dart';
import '../../models/order.dart';
import '../../providers/job_provider.dart';
import '../../providers/order_provider.dart';
import '../common/status_badge.dart';
import '../../screens/orders/order_detail_screen.dart';

class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.id,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          order.customerName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (order.etaMinutes != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'ETA: ${order.etaMinutes} min',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  StatusBadge(status: order.status),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.access_time,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, h:mm a').format(order.createdAt),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                Text(
                  'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          if (order.status == OrderStatus.pending ||
              order.status == OrderStatus.active)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  if (order.status == OrderStatus.pending)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(order: order),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.info,
                          side: const BorderSide(color: AppColors.info),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Accept',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  if (order.status == OrderStatus.pending)
                    const SizedBox(width: 8),
                  if (order.status == OrderStatus.active)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final op = context.read<OrderProvider>();
                          final jp = context.read<JobProvider>();
                          await showAppLoader(context, message: 'Updating...');
                          if (!context.mounted) return;
                          try {
                            op.updateStatus(
                              order.id,
                              OrderStatus.completed,
                              jobProvider: jp,
                            );
                            if (context.mounted) {
                              showAppToast(context,
                                  'Order marked complete',
                                  success: true);
                            }
                          } catch (e, st) {
                            devLog('OrderCard complete', e, st);
                            if (context.mounted) {
                              showAppToast(context,
                                  'Update failed. Please try again.',
                                  error: true);
                            }
                          } finally {
                            if (context.mounted) hideAppLoader(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Complete',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      final op = context.read<OrderProvider>();
                      final jp = context.read<JobProvider>();
                      await showAppLoader(context, message: 'Updating...');
                      if (!context.mounted) return;
                      try {
                        op.updateStatus(
                          order.id,
                          OrderStatus.cancelled,
                          jobProvider: jp,
                        );
                        if (context.mounted) {
                          showAppToast(context, 'Order cancelled', success: true);
                        }
                      } catch (e, st) {
                        devLog('OrderCard cancel', e, st);
                        if (context.mounted) {
                          showAppToast(context,
                              'Could not cancel. Try again.',
                              error: true);
                        }
                      } finally {
                        if (context.mounted) hideAppLoader(context);
                      }
                    },
                    icon: const Icon(Icons.close, color: AppColors.error),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.cancelled,
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
