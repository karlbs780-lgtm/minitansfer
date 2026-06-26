import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'token_storage.dart';

/// Thin wrapper over `http` that:
///  - prefixes the configured base URL,
///  - attaches the `Bearer` JWT for authenticated calls,
///  - decodes JSON and converts non-2xx responses into [ApiException].
class ApiClient {
  final String baseUrl;
  final TokenStorage tokenStorage;
  final http.Client _http;
  final Duration timeout;

  ApiClient({
    required this.baseUrl,
    required this.tokenStorage,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 15),
  }) : _http = httpClient ?? http.Client();

  Future<dynamic> get(String path, {bool authenticated = true}) {
    return _send(() async {
      final response = await _http
          .get(_uri(path), headers: await _headers(authenticated))
          .timeout(timeout);
      return _handle(response);
    });
  }

  Future<dynamic> post(String path, {Object? body, bool authenticated = true}) {
    return _send(() async {
      final response = await _http
          .post(
            _uri(path),
            headers: await _headers(authenticated),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(timeout);
      return _handle(response);
    });
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, String>> _headers(bool authenticated) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authenticated) {
      final token = await tokenStorage.readToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  dynamic _handle(http.Response response) {
    final hasBody = response.body.isNotEmpty;
    final dynamic decoded = hasBody ? jsonDecode(response.body) : null;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    throw ApiException.fromResponse(response.statusCode, decoded);
  }

  /// Runs a request, translating transport/parse failures into a friendly [ApiException].
  Future<dynamic> _send(Future<dynamic> Function() request) async {
    try {
      return await request();
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException.network();
    } on TimeoutException {
      throw ApiException.network();
    } on http.ClientException {
      throw ApiException.network();
    } on FormatException {
      throw ApiException(
        statusCode: 0,
        code: 'BAD_RESPONSE',
        message: 'Reponse inattendue du serveur.',
      );
    }
  }

  void dispose() => _http.close();
}
