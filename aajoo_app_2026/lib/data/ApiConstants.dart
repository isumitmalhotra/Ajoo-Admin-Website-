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

  /// The backend the live website uses. Not a placeholder: `aajaodev` is the
  /// Render service name, and it serves production.
  static const String _defaultBaseUrl = 'https://aajaodev.onrender.com';

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

  /// True when the app is pointed at a plain-HTTP host. Nothing should ship
  /// that way; surfaced so a build can be checked rather than assumed
  /// (FE-12, TLS validation).
  static bool get isSecure => baseUrl.startsWith('https://');
}
