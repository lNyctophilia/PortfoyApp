// BU DOSYA scripts/update_gate_security.dart TARAFINDAN OTOMATIK URETILIR.
// GITHUB'A PUSH EDILSE BILE ASLA ACIK SIFRE ICERMEZ.
// SADECE TEK YONLU KRIPTOGRAFIK TUZLU HASH VE PARAMETRELERI BARINDIRIR.

class GateSecurityConfig {
  /// Site erisim kilidinin aktif olup olmadigi
  static const bool isEnabled = true;

  /// Kriptografik tuz degeri (salt)
  static const String salt = '6d2d31e4415e837b31f5ecc9c5092af3f0fb7bafa6b43b021071ecb20cd291e1';

  /// 10.000 turlu HMAC-SHA256 ile tuzlanmis sifre ozeti (hash)
  static const String hash = 'c2ecaa747d37e2a331ffb40c5bcd7a250642207106fcd626fa5cf8789d0d8541';

  /// Esnetme dongu sayisi
  static const int iterations = 10000;
}
