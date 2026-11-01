import 'update_platform_stub.dart'
    if (dart.library.js_interop) 'update_platform_web.dart' as platform;

abstract class UpdatePlatform {
  static Future<void> triggerHardReload(String targetVersion) {
    return platform.triggerHardReload(targetVersion);
  }
}

