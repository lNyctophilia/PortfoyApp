import 'dart:js_interop';
import 'dart:js_interop_unsafe';

Future<void> triggerHardReload(String targetVersion) async {
  try {
    if (globalContext.has('performHardAppUpdate')) {
      globalContext.callMethod(
        'performHardAppUpdate'.toJS,
        targetVersion.toJS,
      );
      // Fallback: JS içindeki yönlendirme beklenirken 1.5 sn gecikme ver
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      return;
    }
  } catch (_) {}

  try {
    final loc = globalContext['location'] as JSObject?;
    loc?.callMethod('reload'.toJS);
  } catch (_) {}
}

