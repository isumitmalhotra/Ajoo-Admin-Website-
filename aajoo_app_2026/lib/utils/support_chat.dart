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

/// What /bp/handoff hands back: the token, and who it is for.
class ChatHandoff {
  const ChatHandoff({
    required this.token,
    this.name = '',
    this.phone = '',
    this.email = '',
    this.supportRole = '',
  });

  final String token;
  final String name;
  final String phone;
  final String email;

  /// Which support journey this account belongs in: `guest`, `host` or `both`.
  ///
  /// Empty means the server did not say, and the bot should go on asking.
  /// Anything the server sends that is not one of the three is treated the
  /// same way — a value nobody agreed on must not route anybody.
  final String supportRole;
}

/// The only values the bot routes on. See [ChatHandoff.supportRole].
const Set<String> _supportRoles = {'guest', 'host', 'both'};

/// Swap the login session for a short-lived, single-purpose handoff token —
/// and take the NAME, PHONE and EMAIL that come back with it.
///
/// ── Why the profile comes from here and not from the app's own state ───────
///
/// BotPenguin, 2026-09-13, looking at their Inbox: chats opened from this app
/// show "NA" under Visitor Profile — "the bot can recognise the account, but
/// the app is not passing the name, email and phone into the profile fields".
///
/// It was passing them — from `AuthController.userData`, the app's own copy of
/// the profile. That copy is EMPTY until the app has re-fetched it after a
/// launch, so a guest who opens Chat before then arrives as a token with no
/// name on it: recognised, and anonymous. The first bug report of this kind
/// (an identity that is right on the second try) reads as flaky rather than
/// broken, which is why it survived.
///
/// The website never had this problem. It reads the name and phone off THIS
/// response and has since 2026-09-05; this is the same fix on the second
/// surface, with the email added server-side so neither client has to go
/// looking for it. The app's own state is kept only as a fallback for a field
/// the server left blank.
///
/// Returns null on any failure — a missing endpoint, a timeout, an expired
/// session. The caller then opens the plain chat and the bot asks who it is
/// talking to, which is a worse greeting and a correct one.
Future<ChatHandoff?> _handoff(String sessionToken) async {
  try {
    final dio = Dio(BaseOptions(
      baseUrl: Apiconstants.baseUrl,
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
      headers: {'Authorization': 'Bearer $sessionToken'},
    ));
    final res = await dio.post('/bp/handoff');
    final data = res.data is Map ? res.data['data'] : null;
    if (data is! Map) return null;
    final t = data['token']?.toString().trim() ?? '';
    if (t.isEmpty) return null;
    String field(String k) => (data[k] ?? '').toString().trim();
    final role = field('support_role').toLowerCase();
    return ChatHandoff(
      token: t,
      name: field('name'),
      phone: field('phone'),
      email: field('email'),
      supportRole: _supportRoles.contains(role) ? role : '',
    );
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

    final handoff = await _handoff(token.trim());
    // No handoff, no identity. Falling back to the login session would put the
    // very credential this exists to protect into a vendor's URL; the bot
    // asking for a phone number is the correct outcome instead.
    if (handoff == null) return base;

    // What /bp/session/start verifies. Everything else below is convenience so
    // the bot can greet properly and skip its capture nodes.
    params['ctx-token'] = handoff.token;
    // A plain marker for the bot's If/Else gate — the web sets the same fixed
    // value so the condition can read `isauth equals yes`.
    params['ctx-isauth'] = 'yes';

    // The server's answer first; the app's own copy of the profile only for a
    // field the server left blank. See _handoff for why this order matters.
    final user = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>().userData.value
        : null;
    final phone = handoff.phone.isNotEmpty
        ? handoff.phone
        : (user?.phoneNumber ?? '').trim();
    final name = handoff.name.isNotEmpty
        ? handoff.name
        : (user?.fullName ?? '').trim();
    final email = handoff.email.isNotEmpty
        ? handoff.email
        : (user?.email ?? '').trim();

    if (phone.isNotEmpty) {
      // Both names, as the web does: the system contact attribute and the
      // bot's own variable, so the "Request Phone Number" node is pre-filled
      // and skipped.
      params['ctx-phone'] = phone;
      params['ctx-phone_num'] = phone;
    }
    if (name.isNotEmpty) params['ctx-name'] = name;
    if (email.isNotEmpty) params['ctx-email'] = email;

    // Which journey to open in — guest, host or both.
    //
    // BotPenguin, 2026-09-16: the bot could see a visitor was signed in but
    // not what their account IS, so it asked everybody to pick a role first.
    // Sent only when the server actually answered with one of the three: an
    // absent parameter means "ask", which is the behaviour being replaced and
    // the right way to not know. The app reads this fresh every time the chat
    // is opened, so a sign-out, a sign-in or a switch of account is already
    // carried without anything to invalidate.
    //
    // Routing only — /switch-mode still refuses a guest asking for a host
    // token, whatever this says.
    if (handoff.supportRole.isNotEmpty) {
      params['ctx-support_role'] = handoff.supportRole;
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
