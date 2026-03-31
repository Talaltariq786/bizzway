import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartProvider extends ChangeNotifier {
  static const _kBusinessIdKey = 'cart_business_id';
  static const _kItemsKey = 'cart_items_json';

  String? _businessId;
  Map<String, int> _items = {};

  String? get businessId => _businessId;
  bool get hasItems => _items.isNotEmpty;

  CartProvider() {
    _load();
  }

  Map<String, int> itemsForBusiness(String businessId) {
    if (_businessId != businessId) return const {};
    return Map.unmodifiable(_items);
  }

  int itemCountForBusiness(String businessId) {
    if (_businessId != businessId) return 0;
    return _items.values.fold(0, (sum, qty) => sum + qty);
  }

  bool canUseBusiness(String businessId) {
    return _businessId == null || _businessId == businessId;
  }

  bool addItem({
    required String businessId,
    required String itemId,
    int quantity = 1,
  }) {
    if (!canUseBusiness(businessId)) return false;
    _businessId = businessId;
    _items[itemId] = (_items[itemId] ?? 0) + quantity;
    _save();
    notifyListeners();
    return true;
  }

  void removeItem({
    required String businessId,
    required String itemId,
    int quantity = 1,
  }) {
    if (_businessId != businessId) return;
    final current = _items[itemId];
    if (current == null) return;
    final next = current - quantity;
    if (next <= 0) {
      _items.remove(itemId);
    } else {
      _items[itemId] = next;
    }
    if (_items.isEmpty) _businessId = null;
    _save();
    notifyListeners();
  }

  void clearBusinessCart(String businessId) {
    if (_businessId != businessId) return;
    _businessId = null;
    _items = {};
    _save();
    notifyListeners();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _businessId = prefs.getString(_kBusinessIdKey);
    final raw = prefs.getString(_kItemsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _items = decoded.map((key, value) => MapEntry(key, (value as num).toInt()));
        }
      } catch (_) {
        _items = {};
      }
    }
    if (_items.isEmpty) _businessId = null;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    if (_businessId == null || _items.isEmpty) {
      await prefs.remove(_kBusinessIdKey);
      await prefs.remove(_kItemsKey);
      return;
    }
    await prefs.setString(_kBusinessIdKey, _businessId!);
    await prefs.setString(_kItemsKey, jsonEncode(_items));
  }
}
