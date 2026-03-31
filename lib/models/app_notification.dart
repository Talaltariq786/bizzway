enum NotificationType { order, booking, payment, system }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get typeIcon {
    switch (type) {
      case NotificationType.order:
        return '🛒';
      case NotificationType.booking:
        return '📅';
      case NotificationType.payment:
        return '💳';
      case NotificationType.system:
        return '🔔';
    }
  }
}
