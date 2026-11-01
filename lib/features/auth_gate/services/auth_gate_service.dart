import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../constants/gate_security_config.dart';
import '../utils/gate_crypto_utils.dart';

/// Singleton service managing site access lock, authentication state, Google approval, and session persistence.
class AuthGateService extends ChangeNotifier {
  static final AuthGateService instance = AuthGateService._internal();

  AuthGateService._internal();

  static const String _storageKeyAuthToken = 'site_gate_auth_token';
  static const String _storageKeyApprovedGoogleUid = 'site_gate_approved_google_uid';

  bool _isInitialized = false;
  bool _isUnlocked = false;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  String? _approvedGoogleUid;
  StreamSubscription<User?>? _authSubscription;

  bool get isInitialized => _isInitialized;
  bool get isUnlocked => _isUnlocked;
  bool get isGateEnabled => GateSecurityConfig.isEnabled;
  int get failedAttempts => _failedAttempts;
  String? get approvedGoogleUid => _approvedGoogleUid;

  bool get isLockedOut {
    if (_lockoutUntil == null) return false;
    return DateTime.now().isBefore(_lockoutUntil!);
  }

  int get remainingLockoutSeconds {
    if (_lockoutUntil == null) return 0;
    final diff = _lockoutUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// Initializes the service and verifies any existing valid session token or approved Google user.
  Future<void> initialize() async {
    if (!GateSecurityConfig.isEnabled) {
      _isUnlocked = true;
      _isInitialized = true;
      notifyListeners();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Şifre oturum belirteci geçerli mi?
      final storedToken = prefs.getString(_storageKeyAuthToken);
      if (storedToken != null && storedToken.isNotEmpty) {
        final expectedToken = GateCryptoUtils.generateSessionToken(
          configHash: GateSecurityConfig.hash,
          salt: GateSecurityConfig.salt,
        );

        if (GateCryptoUtils.secureCompare(storedToken, expectedToken)) {
          _isUnlocked = true;
        } else {
          // Token geçersiz veya şifre güncellenmiş
          await prefs.remove(_storageKeyAuthToken);
        }
      }

      // 2. Bu cihazda daha önce onaylanmış Google hesabı var mı?
      final storedGoogleUid = prefs.getString(_storageKeyApprovedGoogleUid);
      if (storedGoogleUid != null && storedGoogleUid.isNotEmpty) {
        _approvedGoogleUid = storedGoogleUid;
        _isUnlocked = true;
      }

      // 3. Firebase Auth oturumunu ve Firestore veritabanındaki onay durumunu doğrula
      if (AuthService().isFirebaseAvailable) {
        User? user = AuthService().currentUser;
        if (user == null) {
          try {
            user = await AuthService()
                .authStateChanges
                .first
                .timeout(const Duration(milliseconds: 1200), onTimeout: () => null);
          } catch (_) {}
        }

        if (user != null) {
          final isApproved = await FirestoreService().isUserApproved(user.uid);
          if (isApproved) {
            _approvedGoogleUid = user.uid;
            _isUnlocked = true;
            await prefs.setString(_storageKeyApprovedGoogleUid, user.uid);
            await FirestoreService().markUserApproved(user);
          }
        }
      }
    } catch (e) {
      debugPrint('AuthGateService initialize Hatası: $e');
    }

    _isInitialized = true;
    notifyListeners();

    _attachAuthListener();
  }

  /// Dinleyici ile arka planda Google oturumu açılırsa veya doğrulanırsa otomatik kapıyı açar.
  void _attachAuthListener() {
    _authSubscription?.cancel();
    _authSubscription = AuthService().authStateChanges.listen((user) async {
      if (user != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final storedGoogleUid = prefs.getString(_storageKeyApprovedGoogleUid);

          if (storedGoogleUid == user.uid) {
            _approvedGoogleUid = user.uid;
            _isUnlocked = true;
            notifyListeners();
          }

          final isApproved = await FirestoreService().isUserApproved(user.uid);
          if (isApproved) {
            _approvedGoogleUid = user.uid;
            _isUnlocked = true;
            await prefs.setString(_storageKeyApprovedGoogleUid, user.uid);
            await FirestoreService().markUserApproved(user);
            notifyListeners();
          }
        } catch (e) {
          debugPrint('AuthGateService auth listener Hatası: $e');
        }
      }
    });
  }

  /// Google hesabı onaylandığında veya giriş yapıldığında kapıyı açar ve yerel olarak kaydeder.
  Future<void> unlockByGoogleUser(String uid) async {
    _approvedGoogleUid = uid;
    _isUnlocked = true;
    _failedAttempts = 0;
    _lockoutUntil = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKeyApprovedGoogleUid, uid);
    } catch (_) {}

    notifyListeners();
  }

  /// Google hesabı oturumu kapatıldığında Google onayını temizler.
  Future<void> clearGoogleApproval() async {
    _approvedGoogleUid = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKeyApprovedGoogleUid);

      final storedToken = prefs.getString(_storageKeyAuthToken);
      bool hasValidPasswordToken = false;
      if (storedToken != null && storedToken.isNotEmpty) {
        final expectedToken = GateCryptoUtils.generateSessionToken(
          configHash: GateSecurityConfig.hash,
          salt: GateSecurityConfig.salt,
        );
        hasValidPasswordToken = GateCryptoUtils.secureCompare(storedToken, expectedToken);
      }

      if (!hasValidPasswordToken && GateSecurityConfig.isEnabled) {
        _isUnlocked = false;
      }
    } catch (_) {}

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

        final currentUser = AuthService().currentUser;
        if (currentUser != null) {
          await FirestoreService().markUserApproved(currentUser);
          await prefs.setString(_storageKeyApprovedGoogleUid, currentUser.uid);
          _approvedGoogleUid = currentUser.uid;
        }
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

  /// Locks the site again by deleting the saved session token and google approval.
  Future<void> lock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKeyAuthToken);
      await prefs.remove(_storageKeyApprovedGoogleUid);
    } catch (_) {}

    _approvedGoogleUid = null;
    _isUnlocked = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
