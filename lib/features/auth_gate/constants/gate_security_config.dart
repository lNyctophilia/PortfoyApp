// BU DOSYA scripts/update_gate_security.dart TARAFINDAN OTOMATIK URETILIR.
// GITHUB'A PUSH EDILSE BILE ASLA ACIK SIFRE ICERMEZ.
// SADECE TEK YONLU KRIPTOGRAFIK TUZLU HASH VE PARAMETRELERI BARINDIRIR.

class GateSecurityConfig {
  /// Site erisim kilidinin aktif olup olmadigi
  static const bool isEnabled = true;

  /// Kriptografik tuz degeri (salt)
  static const String salt = '4f84517a77a248cb2d1c84c637249c140dbafec004713f135dfe20f9ac2fbdb3';

  /// 10.000 turlu HMAC-SHA256 ile tuzlanmis sifre ozeti (hash)
  static const String hash = 'fba1ffc355666d1d966986ba51664dd66e7a8309004375301d069211f05921ee';

  /// Esnetme dongu sayisi
  static const int iterations = 10000;
}
