import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../core/api/notifications_api.dart';
import '../core/config/offline_mode.dart';
import '../models/app_notification.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationsApi _api = NotificationsApi(ApiClient());
  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> refreshFromApi() async {
    if (OfflineMode.enabled) return;
    try {
      final list = await _api.list();
      final mapped = list.map(_fromApi).whereType<AppNotification>().toList();
      _notifications
        ..clear()
        ..addAll(mapped);
      notifyListeners();
    } catch (_) {
      // keep last local list
    }
  }

  AppNotification? _fromApi(Map<String, dynamic> m) {
    final id = (m['id'] ?? m['_id'] ?? '').toString();
    if (id.isEmpty) return null;
    final title = (m['title'] ?? '').toString();
    final msg = (m['body'] ?? m['message'] ?? '').toString();
    final typeRaw = (m['type'] ?? m['kind'] ?? 'system').toString().toLowerCase();
    final type = switch (typeRaw) {
      'order' => NotificationType.order,
      'booking' => NotificationType.booking,
      'payment' => NotificationType.payment,
      _ => NotificationType.system,
    };
    final isRead = (m['isRead'] as bool?) ?? false;
    final createdAt = DateTime.tryParse((m['createdAt'] ?? '').toString());
    return AppNotification(
      id: id,
      title: title.isEmpty ? 'Notification' : title,
      message: msg,
      type: type,
      isRead: isRead,
      createdAt: createdAt,
    );
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      if (!OfflineMode.enabled) {
        _api.patch(id, isRead: true);
      }
      notifyListeners();
    }
  }

  void markAllRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    if (!OfflineMode.enabled) {
      for (final n in _notifications) {
        _api.patch(n.id, isRead: true);
      }
    }
    notifyListeners();
  }
}
