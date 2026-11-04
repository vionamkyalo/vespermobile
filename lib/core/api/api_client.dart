import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

class ApiClient {
  ApiClient({
    required this.tokens,
    http.Client? httpClient,
    String? baseUrl,
    this.onSessionExpired,
  }) : _http = httpClient ?? http.Client(),
       baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final TokenStore tokens;
  final String baseUrl;
  final http.Client _http;

  void Function()? onSessionExpired;

  Completer<bool>? _refreshing;
  bool _refreshHitNetworkError = false;

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
    Map<String, String>? headers,
  }) => _send('GET', path, query: query, auth: auth, headers: headers);

  Future<dynamic> post(
    String path, {
    Object? body,
    bool auth = true,
    Map<String, String>? headers,
  }) => _send('POST', path, body: body, auth: auth, headers: headers);

  Future<dynamic> patch(
    String path, {
    Object? body,
    bool auth = true,
    Map<String, String>? headers,
  }) => _send('PATCH', path, body: body, auth: auth, headers: headers);

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool auth = true,
    Map<String, String>? headers,
    bool retried = false,
  }) async {

    print("🎯 FLUTTER CALLING PATH: '$path' | FULL URI: ${_uri(path, query)}");

     if (path.contains('login')) {
      path = '/api/auth/login';
    } else if (path == '/users/me') {
      path = '/api/users/me';
    } else if (path.contains('officer-assignments')) {
      path = '/api/alert-assignments';
    } else if (path.contains('catchCheck') || path.contains('catch-check')) {
      path = '/api/catch-checks';
    }



    final request = http.Request(method, _uri(path, query));

    request.headers['Accept'] = 'application/json';
    if (baseUrl.contains('ngrok')) {
      request.headers['ngrok-skip-browser-warning'] = 'true';
    }
    if (headers != null) request.headers.addAll(headers);
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (auth) {
      final access = await tokens.readAccess();
      if (access != null) request.headers['Authorization'] = 'Bearer $access';
    }

    final http.Response response;
    try {
      final streamed = await _http.send(request).timeout(ApiConfig.timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException.network();
    } on http.ClientException {
      throw ApiException.network();
    } catch (e, stacktrace) {
      print("CRITICAL FLUTTER NET ERROR: $e");
      print("STACKTRACE: $stacktrace");
      throw ApiException.network();
    }

    if (response.statusCode == 401 && auth && !retried) {
      if (await _refreshTokens()) {
        return _send(
          method,
          path,
          query: query,
          body: body,
          auth: auth,
          headers: headers,
          retried: true,
        );
      }
      if (_refreshHitNetworkError) throw ApiException.network();
    }

    final decoded = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    throw ApiException.fromBody(response.statusCode, decoded);
  }

  dynamic _decode(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return null;
    }
  }

  Future<bool> _refreshTokens() async {
    final running = _refreshing;
    if (running != null) return running.future;

    final completer = Completer<bool>();
    _refreshing = completer;
    _refreshHitNetworkError = false;
    var ok = false;
    var rejected = false;
    try {
      final refresh = await tokens.readRefresh();
      if (refresh == null) {
        rejected = true;
      } else {
        final data = await _send(
          'POST',
          '/auth/refresh',
          body: {'refresh_token': refresh},
          auth: false,
        );
        await saveTokenPair(data as Map<String, dynamic>);
        ok = true;
      }
    } on ApiException catch (e) {
      if (e.isNetwork) {
        _refreshHitNetworkError = true;
      } else {
        rejected = true;
      }
    } finally {
      if (rejected) {
        await tokens.clear();
        onSessionExpired?.call();
      }
      completer.complete(ok);
      _refreshing = null;
    }
    return ok;
  }

  Future<bool> refreshSession() => _refreshTokens();
  Future<Map<String, String>> authHeaders() async {
    final access = await tokens.readAccess();
    return {
      if (baseUrl.contains('ngrok')) 'ngrok-skip-browser-warning': 'true',
      if (access != null) 'Authorization': 'Bearer $access',
    };
  }

  Future<void> saveTokenPair(Map<String, dynamic> pair) async {
    await tokens.save(
      access: pair['access_token'] as String,
      refresh: pair['refresh_token'] as String,
    );
  }
}
