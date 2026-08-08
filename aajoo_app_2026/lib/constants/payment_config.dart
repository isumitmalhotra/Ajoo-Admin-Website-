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

  /// Call this once at app startup if you fetch the key from the backend.
  /// Pass `null` to clear the override and fall back to build-time / bundled.
  static void overrideRazorpayKey(String? key) {
    _runtimeOverride = (key != null && key.isNotEmpty) ? key : null;
  }
}
