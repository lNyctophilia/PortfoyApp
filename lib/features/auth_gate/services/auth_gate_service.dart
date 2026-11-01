import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/gate_security_config.dart';
import '../utils/gate_crypto_utils.dart';

/// Singleton service managing site access lock, authentication state, and session persistence.
class AuthGateService extends ChangeNotifier {
  static final AuthGateService instance = AuthGateService._internal();

  AuthGateService._internal();

  static const String _storageKeyAuthToken = 'site_gate_auth_token';

  bool _isInitialized = false;
  bool _isUnlocked = false;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  bool get isInitialized => _isInitialized;
  bool get isUnlocked => _isUnlocked;
  bool get isGateEnabled => GateSecurityConfig.isEnabled;
  int get failedAttempts => _failedAttempts;

  bool get isLockedOut {
    if (_lockoutUntil == null) return false;
    return DateTime.now().isBefore(_lockoutUntil!);
  }

  int get remainingLockoutSeconds {
    if (_lockoutUntil == null) return 0;
    final diff = _lockoutUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// Initializes the service and verifies any existing valid session token from SharedPreferences.
  Future<void> initialize() async {
    if (!GateSecurityConfig.isEnabled) {
      _isUnlocked = true;
      _isInitialized = true;
      notifyListeners();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString(_storageKeyAuthToken);

      if (storedToken != null && storedToken.isNotEmpty) {
        final expectedToken = GateCryptoUtils.generateSessionToken(
          configHash: GateSecurityConfig.hash,
          salt: GateSecurityConfig.salt,
        );

        if (GateCryptoUtils.secureCompare(storedToken, expectedToken)) {
          _isUnlocked = true;
        } else {
          // Token is outdated or invalid (e.g. password changed)
          await prefs.remove(_storageKeyAuthToken);
          _isUnlocked = false;
        }
      } else {
        _isUnlocked = false;
      }
    } catch (_) {
      _isUnlocked = false;
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Verifies the entered password against the compiled salted hash.
  /// If valid, persists the session token so the user is never asked again on this device.
  Future<bool> verifyAndUnlock(String enteredPassword) async {
    if (!GateSecurityConfig.isEnabled) {
      _isUnlocked = true;
      notifyListeners();
      return true;
    }

    if (isLockedOut) {
      return false;
    }

    // Anti-timing artificial delay (minimum 250ms)
    await Future.delayed(const Duration(milliseconds: 250));

    final enteredHash = GateCryptoUtils.computeHash(
      password: enteredPassword,
      salt: GateSecurityConfig.salt,
      iterations: GateSecurityConfig.iterations,
    );

    final isValid = GateCryptoUtils.secureCompare(
      enteredHash,
      GateSecurityConfig.hash,
    );

    if (isValid) {
      _failedAttempts = 0;
      _lockoutUntil = null;
      _isUnlocked = true;

      try {
        final prefs = await SharedPreferences.getInstance();
        final token = GateCryptoUtils.generateSessionToken(
          configHash: GateSecurityConfig.hash,
          salt: GateSecurityConfig.salt,
        );
        await prefs.setString(_storageKeyAuthToken, token);
      } catch (_) {}

      notifyListeners();
      return true;
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _lockoutUntil = DateTime.now().add(const Duration(seconds: 15));
      } else if (_failedAttempts >= 3) {
        _lockoutUntil = DateTime.now().add(const Duration(seconds: 5));
      }
      notifyListeners();
      return false;
    }
  }

  /// Locks the site again by deleting the saved session token.
  Future<void> lock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKeyAuthToken);
    } catch (_) {}

    _isUnlocked = false;
    notifyListeners();
  }
}

