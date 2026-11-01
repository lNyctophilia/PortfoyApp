import 'gate_storage_stub.dart'
    if (dart.library.js_interop) 'gate_storage_web.dart' as platform;

/// Cross-platform storage fallback interface ensuring direct persistent storage on Web.
abstract class GateStoragePlatform {
  static String? getString(String key) => platform.getWebStorageString(key);

  static void setString(String key, String value) =>
      platform.setWebStorageString(key, value);

  static void removeString(String key) =>
      platform.removeWebStorageString(key);
}

