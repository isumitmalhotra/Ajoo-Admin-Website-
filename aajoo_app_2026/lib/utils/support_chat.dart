import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';

/// The BotPenguin support window, opened as the person we already know.
///
/// The app opened a bare chat URL, so a guest who had been signed in for weeks
/// was asked for their phone number and a fresh OTP the moment they tapped
/// Chat — the bot had no way to tell who they were. The website has not done
/// that since the widget shipped: it hands the logged-in JWT to BotPenguin as a
/// `ctx-token` attribute, the bot forwards it to /bp/session/start, and the
/// backend verifies it and starts the session ALREADY authenticated.
///
/// The hosted chat window takes the same context as query parameters, so this
/// builds the identical set the web sets — same names, same values — and the
/// bot's existing "is this visitor logged in" gate works unchanged for both.
///
/// Signed out, it returns the plain URL and the bot falls back to asking, which
/// is the correct behaviour rather than a failure.
const String botPenguinChatUrl =
    'https://window-2.botpenguin.com/69803a093817049868bf064f/696f4cdf88f4a8046c67188e';

/// [base] is exposed for tests; callers use the default.
Future<String> supportChatUrl({String base = botPenguinChatUrl}) async {
  final params = <String, String>{};

  try {
    final token =
        await const FlutterSecureStorage().read(key: 'user_token') ?? '';
    if (token.trim().isEmpty) return base;

    // The token is what /bp/session/start verifies; everything else below is
    // convenience so the bot can greet properly and skip its capture nodes.
    params['ctx-token'] = token.trim();
    // A plain marker for the bot's If/Else gate — the web sets the same fixed
    // value so the condition can read `isauth equals yes`.
    params['ctx-isauth'] = 'yes';

    final user = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>().userData.value
        : null;
    if (user != null) {
      final phone = user.phoneNumber.trim();
      if (phone.isNotEmpty) {
        // Both names, as the web does: the system contact attribute and the
        // bot's own variable, so the "Request Phone Number" node is pre-filled
        // and skipped.
        params['ctx-phone'] = phone;
        params['ctx-phone_num'] = phone;
      }
      final name = user.fullName.trim();
      if (name.isNotEmpty) params['ctx-name'] = name;
      final email = user.email.trim();
      if (email.isNotEmpty) params['ctx-email'] = email;
    }
  } catch (_) {
    // Identity is an optimisation. If anything about reading it fails the chat
    // must still open — asking for a phone number is a worse experience than
    // being recognised, but it is not a broken one.
    return base;
  }

  if (params.isEmpty) return base;
  final uri = Uri.parse(base);
  return uri.replace(
    queryParameters: {...uri.queryParameters, ...params},
  ).toString();
}
