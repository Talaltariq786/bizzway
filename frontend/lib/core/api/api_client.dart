import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_token_storage.dart';
import '../config/api_config.dart';
import '../utils/dev_log.dart';
import 'api_exception.dart';
import 'api_paths.dart';

class ApiClient {
  ApiClient._(this.dio);

  /// Shared [Dio] so auth headers apply to all callers (catalog, bookings, me).
  static Dio? _sharedDio;

  /// Drop cached [Dio] after [ApiConfig] dev URL changes so [BaseOptions.baseUrl] is rebuilt.
  static void resetShared() {
    _sharedDio = null;
  }

  static Dio _dio() {
    if (_sharedDio != null) return _sharedDio!;
    final d = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 12),
        sendTimeout: const Duration(seconds: 12),
        headers: const {
          'Content-Type': 'application/json',
        },
      ),
    );
    d.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_shouldSkipAuthHeader(options.path)) {
            return handler.next(options);
          }
          final token = await AuthTokenStorage.instance.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
    if (kDebugMode) {
      d.interceptors.add(_ApiDebugLogInterceptor());
    }
    _sharedDio = d;
    return d;
  }

  static bool _shouldSkipAuthHeader(String path) {
    return path.startsWith(ApiPaths.authRegister) ||
        path.startsWith(ApiPaths.authLogin) ||
        path.startsWith(ApiPaths.authRefresh);
  }

  final Dio dio;

  factory ApiClient() {
    return ApiClient._(_dio());
  }

  /// GET; response body must be a JSON object map.
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await dio.get<Object?>(path, queryParameters: query);
      return _asJsonMap(res.data);
    } on DioException catch (e) {
      throw _dioToApiException(e);
    }
  }

  /// GET; response body must be a JSON array (e.g. `GET /api/orders`).
  Future<List<dynamic>> getJsonList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await dio.get<Object?>(path, queryParameters: query);
      final data = res.data;
      if (data is List<dynamic>) return data;
      if (data is List) return List<dynamic>.from(data);
      throw ApiException('Expected JSON array response');
    } on DioException catch (e) {
      throw _dioToApiException(e);
    }
  }

  /// POST with JSON body; response body must be a JSON object map.
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final res = await dio.post<Object?>(path, data: body);
      return _asJsonMap(res.data);
    } on DioException catch (e) {
      throw _dioToApiException(e);
    }
  }

  /// PUT with JSON body; response body must be a JSON object map.
  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final res = await dio.put<Object?>(path, data: body);
      return _asJsonMap(res.data);
    } on DioException catch (e) {
      throw _dioToApiException(e);
    }
  }

  /// PATCH with JSON body; response body must be a JSON object map.
  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final res = await dio.patch<Object?>(path, data: body);
      return _asJsonMap(res.data);
    } on DioException catch (e) {
      throw _dioToApiException(e);
    }
  }

  static Map<String, dynamic> _asJsonMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    throw ApiException('Expected JSON object response');
  }

  /// User-facing text from any [DioException] (uses JSON `message` + mapped codes).
  static String messageFromDio(DioException e) {
    return _dioToApiException(e).message;
  }

  static ApiException _dioToApiException(DioException e) {
    final code = e.response?.statusCode;
    final data = e.response?.data;
    String? msg;
    if (data is Map) {
      msg = data['message']?.toString() ??
          _errorCodeMessage(data['error']?.toString());
    }
    final fromServer = msg != null && msg.isNotEmpty;
    // Don’t attach Dio’s huge toString() for normal 4xx/5xx JSON errors — snackbar
    // “detail” expand was showing MDN links / validateStatus noise.
    return ApiException(
      msg ?? e.message ?? e.toString(),
      statusCode: code,
      cause: fromServer ? null : e,
    );
  }

  static String? _errorCodeMessage(String? code) {
    if (code == null || code.isEmpty) return null;
    switch (code) {
      case 'invalid_credentials':
        return 'Phone/email ya password sahi nahi hai.';
      case 'invalid_refresh':
        return 'Session khatam ho gayi. Dobara login karein.';
      case 'phone_or_email_required':
        return 'Signup ke liye phone ya email zaroori hai.';
      case 'duplicate_phone':
        return 'Yeh phone pehle register hai — Login karein.';
      case 'duplicate_email':
        return 'Yeh email pehle register hai — Login karein.';
      case 'not_found':
        return 'Account nahi mila.';
      case 'internal_error':
        return 'Server masla. Thori dair baad dobara try karein.';
      case 'database_error':
        return 'Database connect nahi ho rahi — MongoDB / backend check karein.';
      case 'validation_error':
        return 'Data validate nahi hua.';
      case 'rider_max_active_orders':
        return 'Rider ke paas pehle se maximum active orders hain — pehle complete karein.';
      default:
        return code.replaceAll('_', ' ');
    }
  }
}

/// Console visibility for API traffic in **debug only** (release: no output).
class _ApiDebugLogInterceptor extends Interceptor {
  /// Request body preview (avoid flooding console on huge uploads).
  static const int _maxRequestChars = 2400;
  /// Success / error JSON — large limit so poora response dikhe (debug only).
  static const int _maxResponseChars = 200000;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    devLog(
      'API → ${options.method} ${options.uri}'
      '${options.data != null ? '\nreq: ${_previewJson(options.data, maxChars: _maxRequestChars)}' : ''}',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    devLog(
      'API ← ${response.statusCode} ${response.requestOptions.uri}'
      '\n${_previewJson(response.data, maxChars: _maxResponseChars)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final res = err.response;
    final detail = res?.data != null
        ? _previewJson(res!.data, maxChars: _maxResponseChars)
        : err.message;
    devLog(
      'API ✗ ${err.requestOptions.method} ${err.requestOptions.uri} '
      '${res?.statusCode ?? err.type.name}\n$detail',
    );
    handler.next(err);
  }

  static String _previewJson(Object? data, {required int maxChars}) {
    if (data == null) return '(empty)';
    try {
      final s = const JsonEncoder.withIndent('  ').convert(data);
      return _truncate(s, maxChars);
    } catch (_) {
      return _truncate(data.toString(), maxChars);
    }
  }

  static String _truncate(String s, int max) {
    if (s.length <= max) return s;
    return '${s.substring(0, max)}… [+${s.length - max} chars truncated]';
  }
}
