import 'dart:async';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

/// Tum platformlarda (Web, PWA, Desktop, Mobile) guvenli ve CORS uyumlu HTTP istemcisi.
class AppHttpClient {
  static final http.Client _client = http.Client();

  /// GET istegi gonderir (Web'de otomatik proxy uzerinden yonlendirilir)
  static Future<http.Response?> get(
    String targetUrl, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    try {
      final uri = ApiConstants.buildProxiedUri(targetUrl);
      final defaultHeaders = <String, String>{
        'Accept': 'application/json, text/plain, */*',
        'X-Requested-With': 'XMLHttpRequest',
      };
      if (headers != null) {
        defaultHeaders.addAll(headers);
      }

      final response = await _client.get(uri, headers: defaultHeaders).timeout(timeout);
      return response;
    } catch (_) {
      return null;
    }
  }

  /// POST istegi gonderir (Web'de otomatik proxy uzerinden yonlendirilir)
  static Future<http.Response?> post(
    String targetUrl, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    try {
      final uri = ApiConstants.buildProxiedUri(targetUrl);
      final defaultHeaders = <String, String>{
        'Accept': 'application/json, text/plain, */*',
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      };
      if (headers != null) {
        defaultHeaders.addAll(headers);
      }

      final response = await _client
          .post(uri, headers: defaultHeaders, body: body)
          .timeout(timeout);
      return response;
    } catch (_) {
      return null;
    }
  }
}

