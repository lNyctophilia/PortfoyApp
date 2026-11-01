// BU DOSYA scripts/update_gate_security.dart TARAFINDAN OTOMATIK URETILIR.
// GITHUB'A PUSH EDILSE BILE ASLA ACIK SIFRE ICERMEZ.
// SADECE TEK YONLU KRIPTOGRAFIK TUZLU HASH VE PARAMETRELERI BARINDIRIR.

class GateSecurityConfig {
  /// Site erisim kilidinin aktif olup olmadigi
  static const bool isEnabled = true;

  /// Kriptografik tuz degeri (salt)
  static const String salt = '32a1b52d4198676fc200bef87d1b4e7b29585a047930bd25e26fb75ba3a7d0d2';

  /// 10.000 turlu HMAC-SHA256 ile tuzlanmis sifre ozeti (hash)
  static const String hash = 'd013ca451e38796f32fd5caacc6a57b8235ee433c31d30ea97a1519804c67f5a';

  /// Esnetme dongu sayisi
  static const int iterations = 10000;
}
