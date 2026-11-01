import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';

void main() {
  stdout.writeln('====================================================');
  stdout.writeln('   PortfoyApp Gate Security Config Generator');
  stdout.writeln('====================================================');

  // Guvenilir sekilde proje kok dizinini bul
  String projectRoot = Directory.current.path;
  if (!File('$projectRoot/pubspec.yaml').existsSync()) {
    final parentPath = Directory.current.parent.path;
    if (File('$parentPath/pubspec.yaml').existsSync()) {
      projectRoot = parentPath;
    } else {
      try {
        final scriptDir = File(Platform.script.toFilePath()).parent;
        if (File('${scriptDir.parent.path}/pubspec.yaml').existsSync()) {
          projectRoot = scriptDir.parent.path;
        }
      } catch (_) {}
    }
  }

  final secretFilePath = '$projectRoot/gate_secret.json';
  final secretFile = File(secretFilePath);

  bool isEnabled = true;
  String password = '';

  if (!secretFile.existsSync()) {
    stdout.writeln('[*] gate_secret.json bulunamadı. Örnek dosya oluşturuluyor...');
    final defaultSecret = {
      'enabled': true,
      'password': 'portfoy_guvenli_2026',
    };
    secretFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(defaultSecret),
    );
    password = 'portfoy_guvenli_2026';
    stdout.writeln('[+] Yeni gate_secret.json oluşturuldu. Varsayılan şifre: portfoy_guvenli_2026');
  } else {
    try {
      final jsonStr = secretFile.readAsStringSync();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      isEnabled = data['enabled'] as bool? ?? true;
      password = (data['password'] as String? ?? '').trim();
    } catch (e) {
      stderr.writeln('[HATA] gate_secret.json okunamadı: $e');
      exit(1);
    }
  }

  stdout.writeln('[-] Durum : ${isEnabled ? "Aktif" : "Devre Dışı"}');
  if (isEnabled && password.isEmpty) {
    stderr.writeln('[HATA] gate_secret.json içinde "password" boş olamaz!');
    exit(1);
  }

  // 1. Get or generate persistent cryptographic salt (32 bytes = 64 hex chars)
  String saltHex = '';
  try {
    if (secretFile.existsSync()) {
      final jsonStr = secretFile.readAsStringSync();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      saltHex = (data['salt'] as String? ?? '').trim();
    }
  } catch (_) {}

  if (saltHex.length != 64) {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    saltHex = saltBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    try {
      final jsonStr = secretFile.existsSync() ? secretFile.readAsStringSync() : '{}';
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      data['salt'] = saltHex;
      secretFile.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(data)}\n',
      );
      stdout.writeln('[+] Yeni tuz (salt) üretildi ve gate_secret.json içine kaydedildi.');
    } catch (_) {}
  } else {
    stdout.writeln('[*] Mevcut tuz (salt) korundu (Kullanıcı oturumları sıfırlanmayacak).');
  }

  // 2. Compute multi-round HMAC-SHA256 stretched hash (10,000 iterations)
  const iterations = 10000;
  String hashHex = '';
  if (isEnabled && password.isNotEmpty) {
    final saltUtf8 = utf8.encode(saltHex);
    final keyUtf8 = utf8.encode(password);

    var hmac = Hmac(sha256, keyUtf8);
    var current = hmac.convert(saltUtf8).bytes;

    for (int i = 1; i < iterations; i++) {
      current = hmac.convert(current).bytes;
    }

    hashHex = sha256.convert(current).toString();
  }

  // 3. Write target Dart constant file
  final targetPath =
      '$projectRoot/lib/features/auth_gate/constants/gate_security_config.dart';
  final targetDir = Directory('$projectRoot/lib/features/auth_gate/constants');
  if (!targetDir.existsSync()) {
    targetDir.createSync(recursive: true);
  }

  final dartContent = '''
// BU DOSYA scripts/update_gate_security.dart TARAFINDAN OTOMATIK URETILIR.
// GITHUB'A PUSH EDILSE BILE ASLA ACIK SIFRE ICERMEZ.
// SADECE TEK YONLU KRIPTOGRAFIK TUZLU HASH VE PARAMETRELERI BARINDIRIR.

class GateSecurityConfig {
  /// Site erisim kilidinin aktif olup olmadigi
  static const bool isEnabled = $isEnabled;

  /// Kriptografik tuz degeri (salt)
  static const String salt = '$saltHex';

  /// 10.000 turlu HMAC-SHA256 ile tuzlanmis sifre ozeti (hash)
  static const String hash = '$hashHex';

  /// Esnetme dongu sayisi
  static const int iterations = $iterations;
}
''';

  File(targetPath).writeAsStringSync(dartContent);

  stdout.writeln('[+] Güvenlik yapılandırması başarıyla güncellendi:');
  stdout.writeln('    Hedef: lib/features/auth_gate/constants/gate_security_config.dart');
  stdout.writeln('    Salt : $saltHex');
  stdout.writeln('    Hash : $hashHex');
  stdout.writeln('====================================================');
}

