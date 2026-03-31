import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';
import 'api_exception.dart';

class ApiClient {
  final String baseUrl;

  ApiClient({String? baseUrl}) : baseUrl = (baseUrl ?? AppConfig.apiBaseUrl);

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse(baseUrl + normalized).replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
  }) async {
    return _sendJson('GET', path, query: query, headers: headers);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _sendJson('POST', path, body: body, headers: headers);
  }

  Future<Map<String, dynamic>> _sendJson(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    Map<String, String>? headers,
  }) async {
    final client = HttpClient();
    try {
      final uri = _uri(path, query);
      final req = await client.openUrl(method, uri);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      headers?.forEach(req.headers.set);

      if (body != null) {
        req.add(utf8.encode(jsonEncode(body)));
      }

      final res = await req.close();
      final raw = await res.transform(utf8.decoder).join();
      final status = res.statusCode;

      dynamic decoded;
      if (raw.isNotEmpty) {
        try {
          decoded = jsonDecode(raw);
        } catch (e) {
          throw ApiException('Invalid JSON from server', statusCode: status, cause: e);
        }
      }

      if (status < 200 || status >= 300) {
        final msg = (decoded is Map && decoded['message'] is String)
            ? decoded['message'] as String
            : 'Request failed';
        throw ApiException(msg, statusCode: status);
      }

      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded == null) return <String, dynamic>{};
      throw ApiException('Unexpected response shape', statusCode: status);
    } on SocketException catch (e) {
      throw ApiException('Server unreachable', cause: e);
    } finally {
      client.close(force: true);
    }
  }
}

