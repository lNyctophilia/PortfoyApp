import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

JSObject? get _localStorage {
  try {
    return globalContext['localStorage'] as JSObject?;
  } catch (_) {
    return null;
  }
}

String? getWebStorageString(String key) {
  try {
    final storage = _localStorage;
    if (storage == null) return null;

    // 1. Doğrudan anahtarı dene
    final raw = storage.callMethod<JSString?>('getItem'.toJS, key.toJS)?.toDart;
    if (raw != null && raw.isNotEmpty) {
      return _unquote(raw);
    }

    // 2. Flutter SharedPreferences 'flutter.' önekli anahtarını dene
    final flutterKey = 'flutter.$key';
    final prefixed =
        storage.callMethod<JSString?>('getItem'.toJS, flutterKey.toJS)?.toDart;
    if (prefixed != null && prefixed.isNotEmpty) {
      return _unquote(prefixed);
    }
  } catch (_) {}
  return null;
}

void setWebStorageString(String key, String value) {
  try {
    final storage = _localStorage;
    if (storage == null) return;
    storage.callMethod('setItem'.toJS, key.toJS, value.toJS);
    storage.callMethod(
        'setItem'.toJS, 'flutter.$key'.toJS, jsonEncode(value).toJS);
  } catch (_) {}
}

void removeWebStorageString(String key) {
  try {
    final storage = _localStorage;
    if (storage == null) return;
    storage.callMethod('removeItem'.toJS, key.toJS);
    storage.callMethod('removeItem'.toJS, 'flutter.$key'.toJS);
  } catch (_) {}
}

String _unquote(String val) {
  final trimmed = val.trim();
  if (trimmed.startsWith('"') && trimmed.endsWith('"') && trimmed.length >= 2) {
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is String) return decoded;
    } catch (_) {}
    return trimmed.substring(1, trimmed.length - 1);
  }
  return trimmed;
}
