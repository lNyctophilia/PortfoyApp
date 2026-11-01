// BU DOSYA scripts/update_gate_security.dart TARAFINDAN OTOMATIK URETILIR.
// GITHUB'A PUSH EDILSE BILE ASLA ACIK SIFRE ICERMEZ.
// SADECE TEK YONLU KRIPTOGRAFIK TUZLU HASH VE PARAMETRELERI BARINDIRIR.

class GateSecurityConfig {
  /// Site erisim kilidinin aktif olup olmadigi
  static const bool isEnabled = true;

  /// Kriptografik tuz degeri (salt)
  static const String salt = 'd080a30a1b7af3b3b08fcbd5723663de76d0f40746bddf0ac633e3d7b1e45eeb';

  /// 10.000 turlu HMAC-SHA256 ile tuzlanmis sifre ozeti (hash)
  static const String hash = '416210973dd0f3120bc9fcac39b8923aebc314449d9f542f727b35726054b1d0';

  /// Esnetme dongu sayisi
  static const int iterations = 10000;
}
