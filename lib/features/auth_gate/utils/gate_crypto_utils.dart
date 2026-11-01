import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Cryptographic helper utilities for site gate verification and session tokens.
class GateCryptoUtils {
  /// Computes a multi-round HMAC-SHA256 stretched hash with salt.
  static String computeHash({
    required String password,
    required String salt,
    int iterations = 10000,
  }) {
    final cleanPass = password.trim();
    if (cleanPass.isEmpty) return '';

    final saltBytes = utf8.encode(salt);
    final keyBytes = utf8.encode(cleanPass);

    // Initial HMAC pass
    var hmac = Hmac(sha256, keyBytes);
    var current = hmac.convert(saltBytes).bytes;

    // Iterative key stretching
    for (int i = 1; i < iterations; i++) {
      current = hmac.convert(current).bytes;
    }

    // Final SHA-256 digest
    return sha256.convert(current).toString();
  }

  /// Creates a session authentication token tied to the current configuration hash.
  static String generateSessionToken({
    required String configHash,
    required String salt,
  }) {
    final payload = 'PORTFOY_AUTH_SESSION_KEY_${configHash}_$salt';
    return sha256.convert(utf8.encode(payload)).toString();
  }

  /// Constant-time string comparison to prevent timing side-channel attacks.
  static bool secureCompare(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}

