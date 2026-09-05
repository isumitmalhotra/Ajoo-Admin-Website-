import 'package:flutter/foundation.dart';

/// Record a service failure that the caller is about to swallow.
///
/// Twenty-six service methods caught every error and returned an empty list,
/// null, false or 0 with no trace of why. The screen then drew its empty state,
/// which is indistinguishable from "there is nothing here" — that is exactly
/// how the host notifications screen sat blank for days (APP #19) while the
/// website showed seventeen items for the same account.
///
/// This does not change what those methods return. It makes the failure
/// visible in the log, and hands the message to [ServiceErrors] so a screen
/// that cares can show "couldn't load — tap to retry" instead of nothing.
void logServiceError(String where, Object error, [StackTrace? stack]) {
  ServiceErrors.record(where, error);
  if (kDebugMode) {
    debugPrint('[service] $where failed: $error');
    if (stack != null) debugPrint('$stack');
  }
}

/// The most recent failure per service call, for screens that want to tell
/// the difference between "empty" and "broken".
///
/// Keyed by the same `where` string the log line uses, so a screen asks for
/// exactly the call it made. Cleared by the next successful call.
class ServiceErrors {
  ServiceErrors._();
  static final Map<String, String> _last = {};

  static void record(String where, Object error) {
    _last[where] = _friendly(error);
  }

  static void clear(String where) => _last.remove(where);

  static String? lastFor(String where) => _last[where];

  static String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('Connection')) {
      return "Couldn't reach Aajoo. Check your connection and try again.";
    }
    if (s.contains('Timeout')) {
      return 'The server took too long to answer. Try again.';
    }
    return 'Something went wrong loading this. Pull down to retry.';
  }
}
