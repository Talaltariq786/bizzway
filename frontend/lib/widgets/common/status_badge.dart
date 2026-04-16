import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order.dart';

class StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case OrderStatus.pending:
        bg = AppColors.pending;
        text = AppColors.pendingText;
        label = 'Pending';
        break;
      case OrderStatus.active:
        bg = const Color(0xFFDBEAFE);
        text = const Color(0xFF1E40AF);
        label = 'Active';
        break;
      case OrderStatus.completed:
        bg = AppColors.completed;
        text = AppColors.completedText;
        label = 'Completed';
        break;
      case OrderStatus.cancelled:
        bg = AppColors.cancelled;
        text = AppColors.cancelledText;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
