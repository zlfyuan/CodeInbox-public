import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/forge_adapter.dart';

class ForgeHttp {
  ForgeHttp({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<dynamic> getJson(
    Uri uri, {
    required String token,
    Map<String, String>? headers,
  }) =>
      sendJson('GET', uri, token: token, headers: headers);

  /// GET 请求,原样返回 body 字符串(不 JSON decode)。用于 `.diff` 这类 text/plain 端点。
  Future<String> getText(
    Uri uri, {
    required String token,
    Map<String, String>? headers,
  }) async {
    final extra = headers ?? const <String, String>{};
    final requestHeaders = <String, String>{
      // Codeup: x-yunxiao-token. Gongfeng: PRIVATE-TOKEN. Do not also send Bearer.
      if (!extra.containsKey('x-yunxiao-token') && !extra.containsKey('PRIVATE-TOKEN'))
        'Authorization': 'Bearer $token',
      'Accept': 'text/plain',
      ...extra,
    };
    try {
      final res = await _client.get(uri, headers: requestHeaders).timeout(const Duration(seconds: 15));
      developer.log('GET ${uri.path} → ${res.statusCode}', name: 'codeinbox.http');
      if (res.statusCode == 401) throw AdapterException.unauthorized();
      if (res.statusCode == 403) {
        final remaining = res.headers['x-ratelimit-remaining'];
        if (remaining == '0') {
          final resetRaw = res.headers['x-ratelimit-reset'];
          DateTime? resetAt;
          if (resetRaw != null) {
            final seconds = int.tryParse(resetRaw);
            if (seconds != null) {
              resetAt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
            }
          }
          throw AdapterException.rateLimited(resetAt: resetAt);
        }
        throw AdapterException.http(403, _snippet(res.body));
      }
      if (res.statusCode == 404) {
        throw AdapterException.unsupported('${uri.path} not available');
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw AdapterException.http(res.statusCode, _snippet(res.body));
      }
      return res.body;
    } on AdapterException {
      rethrow;
    } on TimeoutException {
      throw AdapterException.network('Request timed out');
    } on SocketException {
      throw AdapterException.network('Network unavailable');
    } on http.ClientException {
      throw AdapterException.network('Network unavailable');
    }
  }

  Future<dynamic> postJson(
    Uri uri, {
    required String token,
    Map<String, String>? headers,
    Object? body,
  }) =>
      sendJson('POST', uri, token: token, headers: headers, body: body);

  Future<dynamic> putJson(
    Uri uri, {
    required String token,
    Map<String, String>? headers,
    Object? body,
  }) =>
      sendJson('PUT', uri, token: token, headers: headers, body: body);

  /// DELETE 请求,204/200/202 返 null(GitHub unstar 走 204, 客户端不需要响应体)。
  Future<void> deleteJson(
    Uri uri, {
    required String token,
    Map<String, String>? headers,
    Object? body,
  }) async {
    await sendJson('DELETE', uri, token: token, headers: headers, body: body);
  }

  Future<dynamic> sendJson(
    String method,
    Uri uri, {
    required String token,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final extra = headers ?? const <String, String>{};
    final requestHeaders = <String, String>{
      // Codeup: x-yunxiao-token. Gongfeng: PRIVATE-TOKEN. Do not also send Bearer.
      if (!extra.containsKey('x-yunxiao-token') && !extra.containsKey('PRIVATE-TOKEN'))
        'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      ...extra,
    };
    try {
      late http.Response res;
      final encoded = body == null ? null : jsonEncode(body);
      switch (method) {
        case 'POST':
          res = await _client.post(uri, headers: requestHeaders, body: encoded).timeout(const Duration(seconds: 15));
        case 'PUT':
          res = await _client.put(uri, headers: requestHeaders, body: encoded).timeout(const Duration(seconds: 15));
        case 'DELETE':
          res = await _client.delete(uri, headers: requestHeaders, body: encoded).timeout(const Duration(seconds: 15));
        default:
          res = await _client.get(uri, headers: requestHeaders).timeout(const Duration(seconds: 15));
      }
      developer.log('$method ${uri.path} → ${res.statusCode}', name: 'codeinbox.http');
      if (res.statusCode == 401) throw AdapterException.unauthorized();
      if (res.statusCode == 403) {
        final remaining = res.headers['x-ratelimit-remaining'];
        if (remaining == '0') {
          final resetRaw = res.headers['x-ratelimit-reset'];
          DateTime? resetAt;
          if (resetRaw != null) {
            final seconds = int.tryParse(resetRaw);
            if (seconds != null) {
              resetAt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
            }
          }
          throw AdapterException.rateLimited(resetAt: resetAt);
        }
        throw AdapterException.http(403, _snippet(res.body));
      }
      if (res.statusCode == 404) {
        throw AdapterException.unsupported('${uri.path} not available');
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw AdapterException.http(res.statusCode, _snippet(res.body));
      }
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    } on AdapterException {
      rethrow;
    } on TimeoutException {
      throw AdapterException.network('Request timed out');
    } on SocketException {
      throw AdapterException.network('Network unavailable');
    } on http.ClientException {
      throw AdapterException.network('Network unavailable');
    }
  }

  static String _snippet(String body) {
    final trimmed = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (trimmed.length <= 120) return trimmed;
    return trimmed.substring(0, 120);
  }
}
