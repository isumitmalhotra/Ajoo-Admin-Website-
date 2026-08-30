import 'package:flutter/foundation.dart' show kReleaseMode;

/// Centralized payment-gateway config for the app.
///
/// Single source of truth for the Razorpay publishable key. Every checkout
/// flow (`property_page.dart`, `view_ongoing_booking.dart`,
/// `negotitaion_page.dart`) reads from [PaymentConfig.razorpayKey] — do NOT
/// hardcode `rzp_test_*` / `rzp_live_*` anywhere else.
///
/// ## Switching test ↔ live
///
/// Today the key is a compile-time constant (override via `--dart-define`):
///
///   flutter build apk --dart-define=RAZORPAY_KEY=rzp_live_yyyyyyyyyyyy
///
/// If you don't pass `--dart-define`, the build uses the bundled TEST key
/// below so dev / staging continues to work out of the box.
///
/// ## Optional future upgrade
///
/// If we add a `GET /config/payments` endpoint on the backend, the app can
/// fetch the key at runtime — call [PaymentConfig.overrideRazorpayKey] from
/// a startup binding to swap test/live without a rebuild. Until then,
/// `--dart-define` is the swap mechanism.
class PaymentConfig {
  PaymentConfig._();

  /// Bundled fallback (TEST mode). Kept here so the app builds without
  /// `--dart-define`. NEVER replace this with a live key — set the live
  /// key via `--dart-define=RAZORPAY_KEY=rzp_live_...` at build time
  /// instead, so test debugging on dev devices stays safe.
  static const String _fallbackTestKey = 'rzp_test_XUTODhUdMAshi6';

  /// Compile-time override. Build with:
  ///   flutter build apk --dart-define=RAZORPAY_KEY=rzp_live_xxxxxxxxxxxx
  static const String _buildTimeKey = String.fromEnvironment(
    'RAZORPAY_KEY',
    defaultValue: '',
  );

  /// Runtime override, set by an app binding if the backend ever exposes
  /// a /config/payments endpoint. Falls back to the build-time value, then
  /// to the bundled test key.
  static String? _runtimeOverride;

  /// The Razorpay publishable key to pass into the Razorpay checkout sheet.
  /// Resolution order: runtime override → build-time `--dart-define` → bundled TEST key.
  static String get razorpayKey =>
      _runtimeOverride ??
      (_buildTimeKey.isNotEmpty ? _buildTimeKey : _fallbackTestKey);

  /// True when the current key is a live key (`rzp_live_...`). Useful for
  /// suppressing "test mode" banners or guarding analytics events.
  static bool get isLiveMode => razorpayKey.startsWith('rzp_live_');

  /// True when the app is carrying a TEST key.
  ///
  /// A test key does not fail — it succeeds and collects nothing. That is the
  /// same failure the backend shipped with for months (W0-A: checkout opened,
  /// the guest "paid", the booking confirmed, and no money ever moved), and it
  /// is invisible unless something says so out loud.
  static bool get isTestKey => razorpayKey.startsWith('rzp_test_');

  /// The explicit escape hatch for the QA window, matching the backend's
  /// `ALLOW_TEST_PAYMENTS` environment variable exactly:
  ///
  ///   flutter build apk --dart-define=ALLOW_TEST_PAYMENTS=true
  ///
  /// Deliberately its own flag rather than something inferred from the build
  /// mode: "we are testing payments" and "this is a debug build" are different
  /// statements, and conflating them is how a test key reaches real users.
  static const bool allowTestPayments =
      bool.fromEnvironment('ALLOW_TEST_PAYMENTS', defaultValue: false);

  /// Whether checkout should open at all.
  ///
  /// Debug and profile builds always may — that is what they are for. A
  /// RELEASE build carrying a test key may only if somebody said so at build
  /// time. Otherwise the app refuses to open a payment sheet that would take
  /// no money, instead of confirming bookings nobody paid for.
  static bool get usableForPayments {
    if (razorpayKey.isEmpty) return false;
    if (!isTestKey) return true;
    return !kReleaseMode || allowTestPayments;
  }

  /// True when money will actually be collected. The honest field: the backend
  /// reports the same thing at /health/env as `collectsMoney`.
  static bool get collectsMoney => isLiveMode;

  /// What to tell somebody when [usableForPayments] is false.
  static const String unavailableMessage =
      'Payments are not available in this build. Please update the app or '
      'contact support.';

  /// Call this once at app startup if you fetch the key from the backend.
  /// Pass `null` to clear the override and fall back to build-time / bundled.
  static void overrideRazorpayKey(String? key) {
    _runtimeOverride = (key != null && key.isNotEmpty) ? key : null;
  }
}
