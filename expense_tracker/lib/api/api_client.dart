import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'net_client.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;

  static ApiException fromResponse(http.Response res) {
    String message = 'Something went wrong (${res.statusCode})';
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is Map && body['detail'] != null) {
        final detail = body['detail'];
        if (detail is String) {
          message = detail;
        } else if (detail is List && detail.isNotEmpty) {
          final first = detail.first as Map<String, dynamic>;
          message = first['msg']?.toString() ?? message;
        }
      }
    } catch (_) {}
    return ApiException(message, statusCode: res.statusCode);
  }
}

/// Network-level error → the request never reached a meaningful HTTP
/// response (DNS failure, dropped connection). Safe to retry.
bool _isNetworkError(Object e) =>
    e is SocketException || e is http.ClientException;

class ApiClient {
  final String baseUrl;
  String? token;

  ApiClient({required this.baseUrl, this.token});

  late final http.Client _http = createPlatformHttpClient();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<http.Response> _sendWithRetry(
      Future<http.Response> Function() send) async {
    const maxAttempts = 3;
    for (var attempt = 1;; attempt++) {
      try {
        return await send();
      } catch (e) {
        if (attempt >= maxAttempts || !_isNetworkError(e)) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final res =
        await _sendWithRetry(() => _http.get(_uri(path, query), headers: _headers));
    return _handle(res);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final res = await _sendWithRetry(() => _http.post(
          _uri(path),
          headers: _headers,
          body: jsonEncode(body ?? {}),
        ));
    return _handle(res);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final res = await _sendWithRetry(() => _http.put(
          _uri(path),
          headers: _headers,
          body: jsonEncode(body ?? {}),
        ));
    return _handle(res);
  }

  Future<void> delete(String path) async {
    final res =
        await _sendWithRetry(() => _http.delete(_uri(path), headers: _headers));
    if (res.statusCode >= 400) throw ApiException.fromResponse(res);
  }

  dynamic _handle(http.Response res) {
    if (res.statusCode >= 400) throw ApiException.fromResponse(res);
    if (res.body.isEmpty) return null;
    return jsonDecode(utf8.decode(res.bodyBytes));
  }
}
