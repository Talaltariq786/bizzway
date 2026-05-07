import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_client.dart';
import '../core/api/subscription_api.dart';
import '../core/utils/dev_log.dart';
import '../core/api/api_paths.dart';
import '../core/config/offline_mode.dart';
import '../models/business_type.dart';

class BusinessProvider extends ChangeNotifier {
  static const String _prefsRemoteMongoId = 'remote_business_mongo_id';

  static const double minDeliveryRadiusKm = 1.0;
  static const double maxDeliveryRadiusKm = 5.0;
  BusinessType? _selectedBusiness;
  /// MongoDB [Business] id for API product CRUD (owner app).
  String? _remoteBusinessMongoId;
  String _businessName = 'My Business';
  String _businessAddress = '';
  String _businessCoverImagePath = '';
  /// Shop pin for listings & `POST /api/businesses` (Atlas geo index).
  static const double defaultBusinessLat = 24.8607;
  static const double defaultBusinessLng = 67.0011;
  double _businessLat = defaultBusinessLat;
  double _businessLng = defaultBusinessLng;
  bool _businessPinConfirmed = false;
  Color _themeColor = const Color(0xFF6C63FF);
  TimeOfDay _openTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 22, minute: 0);
  double _deliveryRadiusKm = 5.0;
  double _deliveryBaseCharge = 50.0;
  double _deliveryPerKmCharge = 20.0;
  bool _isOnline = false;
  String _subscriptionPlan = 'free'; // 'free' | 'starter' | 'pro' | 'business'
  DateTime? _subscriptionExpiresAt;
  List<String> _customCategories = const [];
  /// Unique per install; encoded in store QR / order link (persisted).
  String _storeQrToken = '';
  /// Owner: force shop "closed" for customers even if time range says open.
  bool _shopManuallyClosed = false;
  String _shopClosedReason = '';

  BusinessType? get selectedBusiness => _selectedBusiness;

  /// Server-side business document id (see `/api/businesses/mine`).
  String? get remoteBusinessMongoId => _remoteBusinessMongoId;
  String get businessName => _businessName;
  String get businessAddress => _businessAddress;
  String get businessCoverImagePath => _businessCoverImagePath;
  double get businessLat => _businessLat;
  double get businessLng => _businessLng;
  bool get businessPinConfirmed => _businessPinConfirmed;
  String get businessLogo => '';
  Color get themeColor => _themeColor;
  List<String> get categories {
    final base = _selectedBusiness?.categories ?? const ['General'];
    final merged = <String>{
      ...base,
      ..._customCategories,
    }.toList();
    merged.sort();
    return merged;
  }

  List<String> get customCategories => List.unmodifiable(_customCategories);
  TimeOfDay get openTime => _openTime;
  TimeOfDay get closeTime => _closeTime;
  double get deliveryRadiusKm => _deliveryRadiusKm;
  double get deliveryBaseCharge => _deliveryBaseCharge;
  double get deliveryPerKmCharge => _deliveryPerKmCharge;
  bool get isOnline => _isOnline;
  String get subscriptionPlan => _subscriptionPlan;
  DateTime? get subscriptionExpiresAt => _subscriptionExpiresAt;

  /// Field / Near Me jobs (auto workshop only). Salon/beauty use open hours, not this toggle.
  bool get isNearMeType => _selectedBusiness?.id == 'mechanic';

  bool get shopManuallyClosed => _shopManuallyClosed;
  String get shopClosedReason => _shopClosedReason;

  /// Calculates total delivery charge for a given distance
  double deliveryChargeFor(double distanceKm) {
    if (distanceKm <= 0) return _deliveryBaseCharge;
    return _deliveryBaseCharge + (distanceKm * _deliveryPerKmCharge);
  }

  bool get isCurrentlyOpen {
    if (_shopManuallyClosed) return false;
    final now = TimeOfDay.now();
    final nowMins = now.hour * 60 + now.minute;
    final openMins = _openTime.hour * 60 + _openTime.minute;
    final closeMins = _closeTime.hour * 60 + _closeTime.minute;
    return nowMins >= openMins && nowMins < closeMins;
  }

  String get formattedHours =>
      '${_formatTime(_openTime)} – ${_formatTime(_closeTime)}';

  String _formatTime(TimeOfDay t) {
    final h = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  bool get hasDelivery =>
      ['restaurant', 'cafe', 'grocery', 'pharmacy', 'others']
          .contains(_selectedBusiness?.id);

  /// Public token for this shop (QR / deep links). Empty until [loadBusiness] runs.
  String get storeQrToken => _storeQrToken;

  /// HTTPS link embedded in QR; backend can resolve `t` to this merchant.
  static const String storeQrUrlHost = 'https://bizzway.app/o';

  String get storeOrderQrUrl {
    if (_storeQrToken.isEmpty) return '';
    return '$storeQrUrlHost?t=${Uri.encodeComponent(_storeQrToken)}';
  }

  static String _newStoreQrToken() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  Future<void> loadBusiness() async {
    final prefs = await SharedPreferences.getInstance();
    final businessId = prefs.getString('business_id');
    final name = prefs.getString('business_name');
    final address = prefs.getString('business_address');
    final cover = prefs.getString('business_cover_image_path');
    final openH = prefs.getInt('open_hour');
    final openM = prefs.getInt('open_min');
    final closeH = prefs.getInt('close_hour');
    final closeM = prefs.getInt('close_min');
    final radius = prefs.getDouble('delivery_radius');
    final baseCharge = prefs.getDouble('delivery_base_charge');
    final perKmCharge = prefs.getDouble('delivery_per_km_charge');
    final catsRaw = prefs.getString('custom_categories_json');

    if (businessId != null) {
      _selectedBusiness = BusinessType.all.firstWhere(
        (b) => b.id == businessId,
        orElse: () => BusinessType.all.first,
      );
    }
    _remoteBusinessMongoId = prefs.getString(_prefsRemoteMongoId);
    if (name != null) _businessName = name;
    if (address != null) _businessAddress = address;
    if (cover != null) _businessCoverImagePath = cover;
    final lat = prefs.getDouble('business_lat');
    final lng = prefs.getDouble('business_lng');
    if (lat != null && lng != null) {
      _businessLat = lat;
      _businessLng = lng;
    }
    _businessPinConfirmed =
        prefs.getBool('business_pin_confirmed') ?? false;
    if (openH != null && openM != null) {
      _openTime = TimeOfDay(hour: openH, minute: openM);
    }
    if (closeH != null && closeM != null) {
      _closeTime = TimeOfDay(hour: closeH, minute: closeM);
    }
    if (radius != null) {
      _deliveryRadiusKm = radius.clamp(minDeliveryRadiusKm, maxDeliveryRadiusKm);
    }
    if (baseCharge != null) _deliveryBaseCharge = baseCharge;
    if (perKmCharge != null) _deliveryPerKmCharge = perKmCharge;
    if (catsRaw != null && catsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(catsRaw);
        if (decoded is List) {
          _customCategories = decoded
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
        }
      } catch (_) {
        _customCategories = const [];
      }
    }
    final plan = prefs.getString('subscription_plan');
    _subscriptionPlan = plan ?? 'free';
    final exRaw = prefs.getString('subscription_expires_at');
    _subscriptionExpiresAt =
        exRaw != null && exRaw.isNotEmpty ? DateTime.tryParse(exRaw) : null;

    var qrTok = prefs.getString('store_qr_token');
    if (qrTok == null || qrTok.isEmpty) {
      qrTok = _newStoreQrToken();
      await prefs.setString('store_qr_token', qrTok);
    }
    _storeQrToken = qrTok;
    _shopManuallyClosed = prefs.getBool('shop_manually_closed') ?? false;
    _shopClosedReason = prefs.getString('shop_closed_reason') ?? '';

    notifyListeners();
    debugLogLocalProfile('loadBusiness');
  }

  /// Debug builds only: prints what is stored locally (SharedPreferences). No API.
  void debugLogLocalProfile(String reason) {
    if (!kDebugMode) return;
    devLog(
      '[BusinessProfile] $reason\n'
      '  businessTypeId: ${_selectedBusiness?.id ?? "(none)"}\n'
      '  name: $_businessName\n'
      '  address: $_businessAddress\n'
      '  coverImagePath: ${_businessCoverImagePath.isEmpty ? "(none)" : _businessCoverImagePath}\n'
      '  mapPin: lat=$_businessLat lng=$_businessLng confirmed=$_businessPinConfirmed\n'
      '  hours: $formattedHours\n'
      '  deliveryRadiusKm: ${_deliveryRadiusKm.toStringAsFixed(1)} '
      '(hasDelivery=$hasDelivery)\n'
      '  subscription: $_subscriptionPlan (expiry: $_subscriptionExpiresAt)\n'
      '  charges: base=$_deliveryBaseCharge perKm=$_deliveryPerKmCharge',
    );
  }

  /// Fetch owner businesses from API and store Mongo id matching [selectedBusiness] `type`.
  Future<void> syncRemoteBusinessWithApi() async {
    if (OfflineMode.enabled) return;
    try {
      final map = await ApiClient().getJson(ApiPaths.businessesMine);
      final raw = map['businesses'];
      if (raw is! List || raw.isEmpty) {
        _remoteBusinessMongoId = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_prefsRemoteMongoId);
        notifyListeners();
        return;
      }
      final typeId = _selectedBusiness?.id;
      String? matchId;
      if (typeId != null) {
        for (final item in raw) {
          if (item is Map && item['type']?.toString() == typeId) {
            matchId = item['id']?.toString();
            _shopManuallyClosed = item['shopManuallyClosed'] == true;
            _shopClosedReason = item['shopClosedReason']?.toString() ?? '';
            final p = await SharedPreferences.getInstance();
            await p.setBool('shop_manually_closed', _shopManuallyClosed);
            if (_shopClosedReason.isEmpty) {
              await p.remove('shop_closed_reason');
            } else {
              await p.setString('shop_closed_reason', _shopClosedReason);
            }
            break;
          }
        }
      }
      if (matchId == null || matchId.isEmpty) {
        _remoteBusinessMongoId = null;
        final p = await SharedPreferences.getInstance();
        await p.remove(_prefsRemoteMongoId);
        notifyListeners();
        return;
      }
      if (matchId.isNotEmpty) {
        _remoteBusinessMongoId = matchId;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsRemoteMongoId, matchId);
        await prefs.setString('subscription_plan', _subscriptionPlan);
        if (_subscriptionExpiresAt != null) {
          await prefs.setString(
            'subscription_expires_at',
            _subscriptionExpiresAt!.toIso8601String(),
          );
        } else {
          await prefs.remove('subscription_expires_at');
        }
        await syncSubscriptionFromApi();
        notifyListeners();
      }
    } catch (_) {
      // Not owner / offline / 401 — keep local prefs id.
    }
  }

  /// Creates a [Business] on server for current type if none exists (owner only).
  Future<void> ensureRemoteBusinessExists() async {
    if (OfflineMode.enabled) return;
    if ((_remoteBusinessMongoId ?? '').isNotEmpty) return;
    final type = _selectedBusiness;
    if (type == null) return;
    try {
      final res = await ApiClient().postJson(
        ApiPaths.businesses,
        body: {
          'name': _businessName.trim().isNotEmpty
              ? _businessName.trim()
              : '${type.title} Shop',
          'type': type.id,
          'address':
              _businessAddress.trim().isNotEmpty ? _businessAddress.trim() : 'Karachi',
          'lat': _businessLat,
          'lng': _businessLng,
        },
      );
      final id = res['id']?.toString();
      if (id != null && id.isNotEmpty) {
        _remoteBusinessMongoId = id;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsRemoteMongoId, id);
        notifyListeners();
      }
    } catch (_) {
      // 403 if not business owner, etc.
    }
  }

  void setOnline(bool value) {
    _isOnline = value;
    notifyListeners();
  }

  Future<void> updateSubscription(String plan) async {
    _subscriptionPlan = plan;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_plan', plan);
    notifyListeners();
  }

  /// Server truth for plan + renewal date (`GET /api/subscriptions/status`).
  Future<void> syncSubscriptionFromApi() async {
    if (OfflineMode.enabled) return;
    final id = _remoteBusinessMongoId;
    if (id == null || id.isEmpty) return;
    try {
      final s = await SubscriptionApi.fetchStatus(id);
      _subscriptionPlan = s.plan;
      _subscriptionExpiresAt = s.expiresAt;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('subscription_plan', _subscriptionPlan);
      if (_subscriptionExpiresAt != null) {
        await prefs.setString(
          'subscription_expires_at',
          _subscriptionExpiresAt!.toIso8601String(),
        );
      } else {
        await prefs.remove('subscription_expires_at');
      }
      notifyListeners();
    } catch (_) {
      // Keep local prefs
    }
  }

  Future<void> updateDeliveryCharges(double base, double perKm) async {
    _deliveryBaseCharge = base;
    _deliveryPerKmCharge = perKm;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('delivery_base_charge', base);
    await prefs.setDouble('delivery_per_km_charge', perKm);
    notifyListeners();
  }

  Future<void> selectBusiness(BusinessType type) async {
    _selectedBusiness = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('business_id', type.id);
    // Keep custom categories across business types, but drop anything not relevant
    // if you want stricter typing later. For now, keep as-is.
    notifyListeners();
  }

  Future<void> addCustomCategory(String name) async {
    final n = name.trim();
    if (n.isEmpty) return;
    _customCategories = {..._customCategories, n}.toList()..sort();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_categories_json', jsonEncode(_customCategories));
    notifyListeners();
  }

  Future<void> removeCustomCategory(String name) async {
    final n = name.trim();
    if (n.isEmpty) return;
    if (!_customCategories.contains(n)) return;
    _customCategories = _customCategories.where((c) => c != n).toList()..sort();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_categories_json', jsonEncode(_customCategories));
    notifyListeners();
  }

  Future<void> updateBusinessName(String name) async {
    _businessName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('business_name', name);
    notifyListeners();
  }

  Future<void> updateBusinessAddress(String address) async {
    _businessAddress = address;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('business_address', address);
    notifyListeners();
  }

  Future<void> updateBusinessCoverImagePath(String path) async {
    _businessCoverImagePath = path.trim();
    final prefs = await SharedPreferences.getInstance();
    if (_businessCoverImagePath.isEmpty) {
      await prefs.remove('business_cover_image_path');
    } else {
      await prefs.setString('business_cover_image_path', _businessCoverImagePath);
    }
    notifyListeners();
  }

  /// Persist shop coordinates (map pin). Used when creating the Mongo business doc.
  Future<void> updateBusinessPin(double lat, double lng) async {
    _businessLat = lat;
    _businessLng = lng;
    _businessPinConfirmed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('business_lat', lat);
    await prefs.setDouble('business_lng', lng);
    await prefs.setBool('business_pin_confirmed', true);
    notifyListeners();
  }

  Future<void> updateHours(TimeOfDay open, TimeOfDay close) async {
    _openTime = open;
    _closeTime = close;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('open_hour', open.hour);
    await prefs.setInt('open_min', open.minute);
    await prefs.setInt('close_hour', close.hour);
    await prefs.setInt('close_min', close.minute);
    notifyListeners();
  }

  Future<void> updateDeliveryRadius(double km) async {
    _deliveryRadiusKm = km.clamp(minDeliveryRadiusKm, maxDeliveryRadiusKm);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('delivery_radius', _deliveryRadiusKm);
    notifyListeners();
  }

  void updateThemeColor(Color color) {
    _themeColor = color;
    notifyListeners();
  }

  /// Shop closed toggle + optional reason (synced to Mongo when [remoteBusinessMongoId] exists).
  Future<void> setShopManualClose(bool closed, {String? reason}) async {
    _shopManuallyClosed = closed;
    _shopClosedReason = (reason ?? '').trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shop_manually_closed', closed);
    if (_shopClosedReason.isEmpty) {
      await prefs.remove('shop_closed_reason');
    } else {
      await prefs.setString('shop_closed_reason', _shopClosedReason);
    }
    notifyListeners();

    if (OfflineMode.enabled) return;
    final id = _remoteBusinessMongoId;
    if (id == null || id.isEmpty) return;
    try {
      await ApiClient().patchJson(
        ApiPaths.businessById(id),
        body: {
          'shopManuallyClosed': closed,
          'shopClosedReason': _shopClosedReason,
        },
      );
    } catch (_) {
      // Local state still applied; retry on next sync
    }
  }
}
