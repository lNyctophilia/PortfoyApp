// BU DOSYA scripts/update_gate_security.dart TARAFINDAN OTOMATIK URETILIR.
// GITHUB'A PUSH EDILSE BILE ASLA ACIK SIFRE ICERMEZ.
// SADECE TEK YONLU KRIPTOGRAFIK TUZLU HASH VE PARAMETRELERI BARINDIRIR.

class GateSecurityConfig {
  /// Site erisim kilidinin aktif olup olmadigi
  static const bool isEnabled = true;

  /// Kriptografik tuz degeri (salt)
  static const String salt = '77fa5297d862fc1c233afdafe7ee5c59cf7dff6cc1855c96e069b24472b70f78';

  /// 10.000 turlu HMAC-SHA256 ile tuzlanmis sifre ozeti (hash)
  static const String hash = 'ab5ad33057ebf4e921bea00fc63477bb6d20483fc04860ea3f890b683aa87884';

  /// Esnetme dongu sayisi
  static const int iterations = 10000;
}
