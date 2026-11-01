// BU DOSYA scripts/update_gate_security.dart TARAFINDAN OTOMATIK URETILIR.
// GITHUB'A PUSH EDILSE BILE ASLA ACIK SIFRE ICERMEZ.
// SADECE TEK YONLU KRIPTOGRAFIK TUZLU HASH VE PARAMETRELERI BARINDIRIR.

class GateSecurityConfig {
  /// Site erisim kilidinin aktif olup olmadigi
  static const bool isEnabled = true;

  /// Kriptografik tuz degeri (salt)
  static const String salt = '0c2d96643fda9677405e586fadfffddaf1c08817d1cfe3b6e90b1ebe90458268';

  /// 10.000 turlu HMAC-SHA256 ile tuzlanmis sifre ozeti (hash)
  static const String hash = 'dc59c62635454fc8adf878619774ea1020b19764f4e511456f4eadaf62a78b4a';

  /// Esnetme dongu sayisi
  static const int iterations = 10000;
}
