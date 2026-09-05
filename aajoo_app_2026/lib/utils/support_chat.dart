import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';

/// The BotPenguin support window, opened as the person we already know.
///
/// The app opened a bare chat URL, so a guest who had been signed in for weeks
/// was asked for their phone number and a fresh OTP the moment they tapped
/// Chat — the bot had no way to tell who they were. The website has not done
/// that since the widget shipped: the chat is opened carrying a token the bot
/// forwards to /bp/session/start, and the backend verifies it and starts the
/// session ALREADY authenticated.
///
/// The token is a HANDOFF token, not the login session.
///
/// This used to send `user_token` itself — a 30-day credential that opens the
/// whole API — to a third party, in a URL, where it lands in their logs and
/// their analytics. The website stopped doing that on 2026-09-05; this is the
/// same fix on the second surface. /bp/handoff mints a 15-minute token good for
/// this one purpose, signed with a key the session verifiers reject, so what
/// BotPenguin receives cannot be replayed against anything else.
///
/// The hosted chat window takes the same context as query parameters, so this
/// builds the identical set the web sets — same names, same values — and the
/// bot's existing "is this visitor logged in" gate works unchanged for both.
///
/// Signed out, it returns the plain URL and the bot falls back to asking, which
/// is the correct behaviour rather than a failure.
const String botPenguinChatUrl =
    'https://window-2.botpenguin.com/69803a093817049868bf064f/696f4cdf88f4a8046c67188e';

/// Swap the login session for a short-lived, single-purpose handoff token.
///
/// Returns null on any failure — a missing endpoint, a timeout, an expired
/// session. The caller then opens the plain chat and the bot asks who it is
/// talking to, which is a worse greeting and a correct one.
Future<String?> _handoffToken(String sessionToken) async {
  try {
    final dio = Dio(BaseOptions(
      baseUrl: Apiconstants.baseUrl,
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
      headers: {'Authorization': 'Bearer $sessionToken'},
    ));
    final res = await dio.post('/bp/handoff');
    final data = res.data is Map ? res.data['data'] : null;
    final t = data is Map ? data['token']?.toString() : null;
    return (t != null && t.trim().isNotEmpty) ? t.trim() : null;
  } catch (_) {
    return null;
  }
}

/// [base] is exposed for tests; callers use the default.
Future<String> supportChatUrl({String base = botPenguinChatUrl}) async {
  final params = <String, String>{};

  try {
    final token =
        await const FlutterSecureStorage().read(key: 'user_token') ?? '';
    if (token.trim().isEmpty) return base;

    final handoff = await _handoffToken(token.trim());
    // No handoff, no identity. Falling back to the login session would put the
    // very credential this exists to protect into a vendor's URL; the bot
    // asking for a phone number is the correct outcome instead.
    if (handoff == null) return base;

    // What /bp/session/start verifies. Everything else below is convenience so
    // the bot can greet properly and skip its capture nodes.
    params['ctx-token'] = handoff;
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
