// One configured FlutterSecureStorage for the whole app, and reads that
// cannot take the app down with them.
//
// WHY THIS EXISTS
//
// Secure storage on Android is backed by the system Keystore, and the Keystore
// is not reliable on every handset. On budget and older devices — the Samsung
// M series among the best-known offenders — and after a backup-restore or an
// OS upgrade, the key the app wrote with can be gone or unreadable, and the
// plugin throws a PlatformException on a plain read().
//
// That mattered enormously here: the splash screen read a token before
// deciding where to send you, its error path had been commented out, and the
// exception therefore left the app sitting on the splash for ever. A device
// that could not read one string never got to the login screen.
//
// So: `resetOnError` lets the plugin clear a corrupt entry and carry on rather
// than throw, and every helper below swallows what is left. A failed read
// means "we don't know who you are" — which is a state the app already knows
// how to handle (it shows the login screen) — never a crash and never a hang.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Deliberately NOT `encryptedSharedPreferences: true`: switching backends
/// would invalidate every token already on every device and sign everyone out
/// at once. `resetOnError` heals the broken cases without touching the rest.
const AndroidOptions _androidOptions = AndroidOptions(resetOnError: true);

const FlutterSecureStorage secureStore =
    FlutterSecureStorage(aOptions: _androidOptions);

/// No read may hang the caller. A device with a wedged Keystore can block, and
/// startup is exactly where that is fatal, so every read gives up quickly and
/// answers "nothing" rather than never answering at all.
const Duration _readTimeout = Duration(seconds: 5);

/// Read a key. Returns null on any failure — missing, corrupt, or too slow.
Future<String?> secureRead(String key) async {
  try {
    return await secureStore.read(key: key).timeout(_readTimeout);
  } catch (e) {
    debugPrint('secureRead("$key") failed, treating as absent: $e');
    return null;
  }
}

/// Write a key. Returns whether it stuck, and never throws at the call site.
Future<bool> secureWrite(String key, String? value) async {
  try {
    await secureStore
        .write(key: key, value: value)
        .timeout(_readTimeout);
    return true;
  } catch (e) {
    debugPrint('secureWrite("$key") failed: $e');
    return false;
  }
}

/// Delete a key, ignoring failure — used on logout, where "it was already
/// unreadable" and "we removed it" amount to the same thing.
Future<void> secureDelete(String key) async {
  try {
    await secureStore.delete(key: key).timeout(_readTimeout);
  } catch (e) {
    debugPrint('secureDelete("$key") failed: $e');
  }
}

/// Wipe everything. Used when the store is judged unusable.
Future<void> secureWipe() async {
  try {
    await secureStore.deleteAll().timeout(_readTimeout);
  } catch (e) {
    debugPrint('secureWipe failed: $e');
  }
}
