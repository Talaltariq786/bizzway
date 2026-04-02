import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifProv = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(AppStrings.notifications),
        actions: [
          TextButton(
            onPressed: notifProv.markAllRead,
            child: const Text(AppStrings.markAllRead,
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: notifProv.notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text('No notifications',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifProv.notifications.length,
              separatorBuilder: (_, i) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final notif = notifProv.notifications[i];
                return _NotifCard(
                  notif: notif,
                  onTap: () => notifProv.markAsRead(notif.id),
                );
              },
            ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback onTap;

  const _NotifCard({required this.notif, required this.onTap});

  Color get _typeColor {
    switch (notif.type) {
      case NotificationType.order:
        return AppColors.primary;
      case NotificationType.booking:
        return AppColors.info;
      case NotificationType.payment:
        return AppColors.success;
      case NotificationType.system:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead
              ? AppColors.surface
              : _typeColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead
                ? AppColors.border
                : _typeColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _typeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(notif.typeIcon, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: notif.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('MMM d, h:mm a').format(notif.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
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
