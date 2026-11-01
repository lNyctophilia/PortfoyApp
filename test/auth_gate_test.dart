import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:portfoy_app/features/auth_gate/utils/gate_crypto_utils.dart';
import 'package:portfoy_app/features/auth_gate/services/auth_gate_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GateCryptoUtils Tests', () {
    test('computeHash produces deterministic salted output', () {
      final hash1 = GateCryptoUtils.computeHash(
        password: 'testPassword123',
        salt: 'my_salt_12345',
        iterations: 100,
      );
      final hash2 = GateCryptoUtils.computeHash(
        password: 'testPassword123',
        salt: 'my_salt_12345',
        iterations: 100,
      );
      final hashDiff = GateCryptoUtils.computeHash(
        password: 'wrongPassword',
        salt: 'my_salt_12345',
        iterations: 100,
      );

      expect(hash1, isNotEmpty);
      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(hashDiff)));
    });

    test('secureCompare returns true for identical strings and false otherwise', () {
      expect(GateCryptoUtils.secureCompare('abc', 'abc'), isTrue);
      expect(GateCryptoUtils.secureCompare('abc', 'abd'), isFalse);
      expect(GateCryptoUtils.secureCompare('abc', 'abcd'), isFalse);
    });

    test('generateSessionToken produces consistent token for given config hash and salt', () {
      final token1 = GateCryptoUtils.generateSessionToken(
        configHash: 'hash123',
        salt: 'salt123',
      );
      final token2 = GateCryptoUtils.generateSessionToken(
        configHash: 'hash123',
        salt: 'salt123',
      );
      expect(token1, equals(token2));
    });
  });

  group('AuthGateService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('verifyAndUnlock verifies correct password and stores session token', () async {
      final service = AuthGateService.instance;
      await service.initialize();

      // Wrong password
      final wrongResult = await service.verifyAndUnlock('completely_wrong_pass');
      expect(wrongResult, isFalse);
      expect(service.isUnlocked, isFalse);

      // Correct password (dynamically loaded from gate_secret.json or default)
      String correctPass = 'portfoy_guvenli_2026';
      try {
        final secretFile = File('gate_secret.json');
        if (secretFile.existsSync()) {
          final decoded = jsonDecode(secretFile.readAsStringSync());
          if (decoded['password'] != null) {
            correctPass = decoded['password'];
          }
        }
      } catch (_) {}

      final correctResult = await service.verifyAndUnlock(correctPass);
      expect(correctResult, isTrue);
      expect(service.isUnlocked, isTrue);

      // Verify that session token is persisted
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('site_gate_auth_token');
      expect(storedToken, isNotNull);

      // Simulate a restart of the app
      final newServiceInstance = AuthGateService.instance;
      await newServiceInstance.initialize();
      // Should remain unlocked without asking password again!
      expect(newServiceInstance.isUnlocked, isTrue);

      // Now lock it manually
      await service.lock();
      expect(service.isUnlocked, isFalse);

      final tokenAfterLock = prefs.getString('site_gate_auth_token');
      expect(tokenAfterLock, isNull);
    });
  });
}

