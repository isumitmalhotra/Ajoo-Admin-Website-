import 'dart:convert';

import 'package:razorpay_flutter/razorpay_flutter.dart';

/// What Razorpay actually said.
///
/// The Dart counterpart of the web's redesign/lib/rzpError.ts. Razorpay hands
/// back a description written for the payer — "Your card was declined",
/// "Amount exceeds maximum amount allowed", "insufficient funds" — and the app
/// showed the plugin's `message` verbatim in a toast. On Android that message
/// is the raw JSON envelope, so a guest whose card was refused saw
///
///   Payment Failed: {"error":{"code":"BAD_REQUEST_ERROR","description":
///   "Your card was declined","reason":"payment_failed", ...}}
///
/// flash past for two seconds. The web has read the description out of that
/// envelope since the redesign; this is the same rule for the app.
///
/// A per-transaction cap on the Razorpay account and a declined card are
/// otherwise indistinguishable in a bug report, which is the other reason the
/// real sentence matters.
String rzpReason(PaymentFailureResponse response) {
  final fromBody = _describe(response.error);
  final fromMessage = fromBody == null ? _describeRaw(response.message) : null;
  final description = (fromBody ?? fromMessage ?? '').trim();
  if (description.isEmpty) return 'Payment failed. Please try again.';
  // Razorpay's descriptions are already sentences; some just lack a full stop.
  return RegExp(r'[.!?]$').hasMatch(description)
      ? description
      : '$description.';
}

/// Pull the description out of the plugin's structured `responseBody`.
String? _describe(Map<dynamic, dynamic>? body) {
  if (body == null) return null;
  final err = body['error'];
  if (err is Map) {
    final d = err['description'];
    if (d is String && d.trim().isNotEmpty) return d.trim();
  }
  final d = body['description'];
  if (d is String && d.trim().isNotEmpty) return d.trim();
  return null;
}

/// The same, for the case where the envelope arrives as a JSON string.
///
/// Falls back to the string itself when it is not JSON — a plain sentence from
/// the SDK is worth showing; a brace is not.
String? _describeRaw(String? message) {
  final raw = (message ?? '').trim();
  if (raw.isEmpty) return null;
  if (raw.startsWith('{')) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return _describe(decoded);
    } catch (_) {
      // Not JSON after all; better to say nothing than to print the brace.
    }
    return null;
  }
  return raw;
}
