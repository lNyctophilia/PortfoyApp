import 'package:flutter_test/flutter_test.dart';
import 'package:portfoy_app/features/app_update/models/update_info.dart';
import 'package:portfoy_app/features/app_update/services/app_update_service.dart';

void main() {
  group('AppUpdateService & UpdateInfo Tests', () {
    test('UpdateInfo correctly reports isSuccess state', () {
      const successInfo = UpdateInfo(
        hasUpdate: false,
        currentVersion: 'Versiyon (01.11.2026-07.19)',
        serverVersion: 'Versiyon (01.11.2026-07.19)',
      );
      expect(successInfo.isSuccess, isTrue);

      const errorInfo = UpdateInfo(
        hasUpdate: false,
        currentVersion: 'Versiyon (01.11.2026-07.19)',
        serverVersion: 'Versiyon (01.11.2026-07.19)',
        errorMessage: 'Connection timeout',
      );
      expect(errorInfo.isSuccess, isFalse);
    });

    test('checkForUpdates fallback returns an UpdateInfo object', () async {
      final service = AppUpdateService.instance;
      final info = await service.checkForUpdates();

      expect(info.currentVersion, isNotEmpty);
      expect(info.serverVersion, isNotEmpty);
    });
  });
}

