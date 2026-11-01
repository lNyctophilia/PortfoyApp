// BU DOSYA scripts/update_gate_security.dart TARAFINDAN OTOMATIK URETILIR.
// GITHUB'A PUSH EDILSE BILE ASLA ACIK SIFRE ICERMEZ.
// SADECE TEK YONLU KRIPTOGRAFIK TUZLU HASH VE PARAMETRELERI BARINDIRIR.

class GateSecurityConfig {
  /// Site erisim kilidinin aktif olup olmadigi
  static const bool isEnabled = true;

  /// Kriptografik tuz degeri (salt)
  static const String salt = '2b8ec25bd5d6d4587687d2a6a766198d469def93e02256c84c42a3c6df31433f';

  /// 10.000 turlu HMAC-SHA256 ile tuzlanmis sifre ozeti (hash)
  static const String hash = '96e942fef7f4f269ea42c12e9466c051a2d96af913d1fcd7dbdf199906f39e53';

  /// Esnetme dongu sayisi
  static const int iterations = 10000;
}
