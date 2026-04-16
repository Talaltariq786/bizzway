import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_paths.dart';
import '../core/config/offline_mode.dart';
import '../models/business_type.dart';
import '../models/product.dart';

String _categoryForCatalogProduct(String businessTypeId, Map<String, dynamic> mm) {
  final raw = (mm['category'] ?? '').toString().trim();
  BusinessType? bt;
  for (final b in BusinessType.all) {
    if (b.id == businessTypeId) {
      bt = b;
      break;
    }
  }
  final allowed = bt?.categories ?? const <String>['General'];
  if (raw.isNotEmpty && allowed.contains(raw)) return raw;
  if (allowed.isNotEmpty) return allowed.first;
  return raw.isNotEmpty ? raw : 'General';
}

class ApiCatalogProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  bool _loading = false;
  String? _error;
  String? _activeBusinessId;
  List<Product> _products = const [];

  bool get isLoading => _loading;
  String? get error => _error;
  String? get activeBusinessId => _activeBusinessId;
  List<Product> get products => List.unmodifiable(_products);

  /// Loads catalog for [businessTypeId].
  ///
  /// When [remoteBusinessMongoId] is set (logged-in owner’s business on server),
  /// products are loaded for **that** id — not the first random row from the public list.
  Future<void> loadProductsForBusinessType(
    String businessTypeId, {
    String? remoteBusinessMongoId,
  }) async {
    if (businessTypeId.trim().isEmpty) return;
    if (OfflineMode.enabled) {
      _activeBusinessId = null;
      _products = const [];
      _loading = false;
      _error = null;
      notifyListeners();
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final trimmedRemote = (remoteBusinessMongoId ?? '').trim();
      String? resolvedId =
          trimmedRemote.isNotEmpty ? trimmedRemote : null;

      if (resolvedId == null) {
        final bizRes = await _api.dio.get<List<dynamic>>(
          ApiPaths.businesses,
          queryParameters: {
            'type': businessTypeId,
          },
        );
        final bizList = bizRes.data ?? const [];
        if (bizList.isEmpty) {
          _activeBusinessId = null;
          _products = const [];
          _loading = false;
          notifyListeners();
          return;
        }

        final first = bizList.first;
        resolvedId = (first is Map && first['id'] != null)
            ? first['id'].toString()
            : null;
        if (resolvedId == null || resolvedId.isEmpty) {
          _activeBusinessId = null;
          _products = const [];
          _loading = false;
          notifyListeners();
          return;
        }
      }

      _activeBusinessId = resolvedId;

      final prodRes = await _api.dio.get<List<dynamic>>(
        ApiPaths.businessProducts(resolvedId),
      );
      final list = prodRes.data ?? const [];
      _products = list.whereType<Map>().map((m) {
        final mm = Map<String, dynamic>.from(m);
        return Product(
          id: (mm['id'] ?? '').toString(),
          businessTypeId: businessTypeId,
          name: (mm['name'] ?? '').toString(),
          description: '',
          price: (mm['price'] as num?)?.toDouble() ?? 0,
          category: _categoryForCatalogProduct(businessTypeId, mm),
          imageUrl: (mm['images'] is List && (mm['images'] as List).isNotEmpty)
              ? (mm['images'] as List).first.toString()
              : '',
          isAvailable: (mm['isActive'] as bool?) ?? true,
        );
      }).toList();

      _loading = false;
      notifyListeners();
    } on DioException catch (e) {
      _loading = false;
      _error = ApiClient.messageFromDio(e);
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
}

