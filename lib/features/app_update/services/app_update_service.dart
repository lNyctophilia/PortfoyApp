import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_version.dart';
import '../../../core/network/app_http_client.dart';
import '../models/update_info.dart';
import 'platform/update_platform_interface.dart';

/// Uygulama guncelleme denetimi ve onbellek temizleme yonetimi.
class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  static const String fallbackVersionUrl =
      'https://lnyctophilia.github.io/PortfoyApp/version.json';

  /// Sunucudaki version.json dosyasini sorgular ve mevcut surum ile karsilastirir.
  Future<UpdateInfo> checkForUpdates() async {
    final current = AppVersion.current.trim();
    final candidateUrls = _buildCandidateUrls();

    for (final url in candidateUrls) {
      try {
        final cacheBusterUri = url.replace(
          queryParameters: {
            '_t': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );

        final response = await http.get(
          cacheBusterUri,
          headers: {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
          final info = _parseVersionJson(response.body, current);
          if (info != null) {
            return info;
          }
        }
      } catch (_) {
        // Siradaki URL adayina devam et
      }
    }

    // Direkt erisim basarisiz olduysa CORS Proxy uzerinden dene
    try {
      final proxiedResponse = await AppHttpClient.get(
        '$fallbackVersionUrl?_t=${DateTime.now().millisecondsSinceEpoch}',
        timeout: const Duration(seconds: 6),
      );
      if (proxiedResponse != null &&
          proxiedResponse.statusCode == 200 &&
          proxiedResponse.body.trim().isNotEmpty) {
        final info = _parseVersionJson(proxiedResponse.body, current);
        if (info != null) {
          return info;
        }
      }
    } catch (_) {}

    return UpdateInfo(
      hasUpdate: false,
      currentVersion: current,
      serverVersion: current,
      errorMessage: 'Sunucuya bağlanılamadı veya sürüm bilgisi alınamadı.',
    );
  }

  /// Yeni surume gecis ve tarayici/webview onbellegini temizleyerek sert yenileme baslatir.
  Future<void> applyUpdate(String targetVersion) async {
    await UpdatePlatform.triggerHardReload(targetVersion);
  }

  List<Uri> _buildCandidateUrls() {
    final list = <Uri>[];

    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        final segments = Uri.base.pathSegments.where((s) => s.isNotEmpty).toList();
        final basePath = segments.isNotEmpty ? '/${segments.first}/' : '/';
        list.add(Uri.parse('$origin${basePath}version.json'));
      } catch (_) {}
    }

    list.add(Uri.parse(fallbackVersionUrl));
    return list;
  }

  UpdateInfo? _parseVersionJson(String responseBody, String current) {
    try {
      final dynamic decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) return null;

      final serverVersion = (decoded['version'] ?? decoded['build_time'] ?? '')
          .toString()
          .trim();
      final buildTime = decoded['build_time']?.toString().trim();
      final timestamp = decoded['timestamp'] is int
          ? decoded['timestamp'] as int
          : int.tryParse(decoded['timestamp']?.toString() ?? '');

      if (serverVersion.isEmpty) return null;

      final hasUpdate = _isDifferentVersion(current, serverVersion);

      return UpdateInfo(
        hasUpdate: hasUpdate,
        currentVersion: current,
        serverVersion: serverVersion,
        buildTime: buildTime,
        timestamp: timestamp,
      );
    } catch (_) {
      return null;
    }
  }

  bool _isDifferentVersion(String current, String server) {
    if (current == server) return false;
    final normCurrent = _normalizeVersion(current);
    final normServer = _normalizeVersion(server);
    return normCurrent != normServer;
  }

  String _normalizeVersion(String raw) {
    return raw
        .replaceAll('Versiyon', '')
        .replaceAll('Version', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .trim();
  }
}

