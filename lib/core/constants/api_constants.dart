import 'package:flutter/foundation.dart';

/// API ve CORS Proxy yapilandirmasi
class ApiConstants {
  /// Cloudflare Worker CORS Proxy URL.
  /// Cloudflare'de olusturdugunuz Worker baglantisini buraya yazabilirsiniz.
  /// Ornek: 'https://portfoy-proxy.kullaniciadi.workers.dev'
  static String cloudflareWorkerUrl = 'https://portfoyapp.nycgamedevs.workers.dev';

  /// Hedef URL'yi proxy formatina donusturur
  static Uri buildProxiedUri(String targetUrl) {
    final trimmedBase = cloudflareWorkerUrl.trim();
    if (!kIsWeb && trimmedBase.isEmpty) {
      return Uri.parse(targetUrl);
    }
    if (trimmedBase.isEmpty) {
      return Uri.parse(targetUrl);
    }
    final cleanBase = trimmedBase.endsWith('/')
        ? trimmedBase.substring(0, trimmedBase.length - 1)
        : trimmedBase;
    return Uri.parse('$cleanBase/?url=${Uri.encodeComponent(targetUrl)}');
  }
}

