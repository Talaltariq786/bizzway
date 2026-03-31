import 'package:flutter/material.dart';
import '../models/app_notification.dart';

class NotificationProvider extends ChangeNotifier {
  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'n1',
      title: 'New Order Received!',
      message: 'Ahmed Khan placed an order worth Rs. 1,260',
      type: NotificationType.order,
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    AppNotification(
      id: 'n2',
      title: 'Order Completed',
      message: 'Order ORD-003 by Bilal Hassan has been completed',
      type: NotificationType.order,
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'n3',
      title: 'Payment Received',
      message: 'Rs. 1,800 received for Order ORD-002',
      type: NotificationType.payment,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AppNotification(
      id: 'n4',
      title: 'New Booking',
      message: 'Sara Ali booked an appointment for tomorrow 3:00 PM',
      type: NotificationType.booking,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AppNotification(
      id: 'n5',
      title: 'System Update',
      message: 'BizzWay has been updated to v1.2.0 with new features',
      type: NotificationType.system,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }
}
