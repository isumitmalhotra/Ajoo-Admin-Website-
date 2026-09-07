import 'package:flutter/foundation.dart';

/// Diagnostic logging that does not ship.
///
/// The audit (A-5) counted `print()` in 44 files and called it low severity —
/// "leaks info and hurts performance". It was worse than that. Neither `print`
/// nor `debugPrint` is stripped from a Flutter release build; both reach
/// logcat on a tester's phone. And several of those call sites were dumping
/// whole API responses:
///
///   auth_service.dart      print(response.data)   // the login response
///   booking_service.dart   print(token)           // the session token
///
/// A session token in the device log is readable over `adb logcat` and by any
/// crash-reporting SDK with log access — a 30-day credential, in plain text.
/// This project's own UAT rules say never to put a login token in a log; the
/// app was doing it on every sign-in.
///
/// So: one helper, compiled to nothing in release. `kDebugMode` is a
/// const, so the whole call is tree-shaken out rather than merely skipped.
///
/// Anything carrying a credential does not get logged at all, gate or no gate
/// — see [redact]. A debug build runs on real devices too.
void appLog(Object? message, {String? tag}) {
  if (!kDebugMode) return;
  debugPrint(tag == null ? '$message' : '[$tag] $message');
}

/// A payload with its secrets replaced, for when the SHAPE is worth logging.
///
/// Use this rather than dropping a response into [appLog] wholesale: a body
/// that carries no token today may carry one after a backend change, and a
/// redaction that lists the keys is the version that stays safe.
String redact(Object? payload) {
  if (payload is! Map) return '<${payload.runtimeType}>';
  const secrets = {
    'token', 'accesstoken', 'refreshtoken', 'idtoken', 'authorization',
    'password', 'user_password', 'cred_user_password', 'otp', 'uo_otp',
    'razorpay_signature', 'signature', 'key', 'secret', 'apikey',
  };
  final out = <String, Object?>{};
  payload.forEach((k, v) {
    final name = k.toString();
    out[name] = secrets.contains(name.toLowerCase().replaceAll('_', ''))
        ? '<redacted>'
        : (v is Map || v is List ? '<${v.runtimeType}>' : v);
  });
  return out.toString();
}
