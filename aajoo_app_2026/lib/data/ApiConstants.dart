import 'package:flutter/foundation.dart' show kReleaseMode;

/// Where the app talks to (W8: P0-01).
///
/// This used to be three constants that were all the same string, with
/// `baseUrl` wired to the one named `_dev` — so there was no prod/dev split at
/// all, only the appearance of one, and a release build shipped whatever the
/// last person had edited into the dev line.
///
/// It is one value with a build-time override now, the same mechanism
/// [PaymentConfig] uses for the Razorpay key:
///
///   flutter build apk --dart-define=API_BASE_URL=https://api.aajoohomes.com
///
/// Without the flag the app uses the host below, which is the backend the live
/// website talks to today — so nothing changes until somebody deliberately
/// points a build somewhere else.
class Apiconstants {
  Apiconstants._();

  /// The development fallback — and ONLY in a development build.
  ///
  /// P0-01/FE-01: the released APK contained `aajaodev.onrender.com`, because
  /// this constant was compiled in whether or not anybody chose it. `aajaodev`
  /// is the Render *service* name and it does serve the live website, so the
  /// app was talking to the right host — but a release artifact that carries a
  /// default endpoint nobody named is one edit away from shipping the wrong
  /// one, which is exactly what the finding is about.
  ///
  /// `kReleaseMode` is a compile-time constant, so in a release build this
  /// whole branch folds to the empty string and the URL is not in the binary at
  /// all. A release build therefore has no endpoint unless one is passed:
  ///
  ///   flutter build apk --dart-define=API_BASE_URL=https://…
  ///
  /// and [isConfigured] is false without it, which main() refuses to start on.
  /// Debug and profile builds keep working with no flags, as before.
  static const String _defaultBaseUrl =
      kReleaseMode ? '' : 'https://aajaodev.onrender.com';

  /// Build-time override. Empty unless `--dart-define=API_BASE_URL=…` is passed.
  static const String _buildTimeBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // `== ''` rather than `.isNotEmpty`: a property access is not allowed in a
  // const expression, and this has to stay const — half the app imports it
  // into const constructors.
  static const String baseUrl =
      _buildTimeBaseUrl == '' ? _defaultBaseUrl : _buildTimeBaseUrl;

  /// Kept because older screens import it. Same value as [baseUrl] — it was
  /// always the same string, and having two names for one host is how the
  /// dev/prod confusion started.
  static const String serverUrl = baseUrl;

  /// Is this build pointed at anything at all?
  ///
  /// False in exactly one case: a RELEASE build put together without
  /// `--dart-define=API_BASE_URL`. main() shows a build-configuration screen
  /// rather than starting, because an app that silently talks to nowhere is
  /// indistinguishable from a broken network and takes a day to diagnose.
  static bool get isConfigured => baseUrl.startsWith('https://');

  /// True when the app is pointed at a plain-HTTP host. Nothing should ship
  /// that way; surfaced so a build can be checked rather than assumed
  /// (FE-12, TLS validation).
  static bool get isSecure => baseUrl.startsWith('https://');
}
