// The support chat must never hand BotPenguin the login session (2026-09-05).
//
// `supportChatUrl` opens a vendor-hosted page and passes identity in the query
// string. It used to pass `user_token` — the 30-day credential that opens the
// whole API — which then lives in that vendor's request logs and analytics for
// as long as they keep them. The website was fixed first; this is the app.
//
// These assertions read the source rather than calling the function, because
// the function reaches for secure storage and the network, and the property
// worth protecting is a property of the code: the raw session is not what gets
// put in the URL. A behavioural test would need both of those mocked and would
// still not catch someone adding a fallback branch.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The file with comments and doc comments removed.
///
/// Without this, every assertion below passes on the prose explaining the fix
/// instead of on the code implementing it — the comments above name
/// `user_token` and `ctx-token` repeatedly.
String codeOnly(String src) => src
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//'))
    .join('\n');

void main() {
  final src = codeOnly(
    File('lib/utils/support_chat.dart').readAsStringSync(),
  );

  test('the session token is not what goes in the URL', () {
    expect(
      RegExp(r"params\['ctx-token'\]\s*=\s*token").hasMatch(src),
      isFalse,
      reason: 'the raw user_token is being handed to BotPenguin again',
    );
    expect(
      RegExp(r"params\['ctx-token'\]\s*=\s*handoff").hasMatch(src),
      isTrue,
      reason: 'ctx-token is no longer the handoff token',
    );
  });

  test('the handoff comes from the endpoint that mints one', () {
    expect(src, contains("dio.post('/bp/handoff')"));
    // The session token authenticates that one call and goes no further.
    expect(src, contains(r"'Authorization': 'Bearer $sessionToken'"));
  });

  test('a failed mint drops identity instead of falling back', () {
    // The tempting "handoff ?? token" is the whole bug back again, and it would
    // only show up in the vendor's logs. Signed-in-but-unrecognised is the
    // correct failure: the bot asks for a phone number.
    expect(src, contains('if (handoff == null) return base;'));
    expect(RegExp(r'handoff\s*\?\?').hasMatch(src), isFalse);
  });

  // ── who the chat is opened AS ─────────────────────────────────────────────
  //
  // BotPenguin, 2026-09-13, looking at their Inbox: chats from this app showed
  // "NA" under Visitor Profile — recognised, and anonymous. The app was passing
  // name, email and phone from ITS OWN copy of the profile, which is empty until
  // the app has re-fetched it after a launch. The website reads them off the
  // handoff response instead and never had the problem.

  test('the profile comes back with the token, and that is what is sent', () {
    expect(src, contains("field('name')"), reason: 'the name is no longer read off the handoff');
    expect(src, contains("field('phone')"), reason: 'the phone is no longer read off the handoff');
    expect(src, contains("field('email')"), reason: 'the email is no longer read off the handoff');
    expect(
      RegExp(r"handoff\.phone\.isNotEmpty\s*\?\s*handoff\.phone").hasMatch(src),
      isTrue,
      reason: "the server's phone is not preferred — a fresh launch opens the "
          'chat before the app has re-fetched its own copy, and the Inbox '
          'shows NA',
    );
    expect(RegExp(r"handoff\.name\.isNotEmpty\s*\?\s*handoff\.name").hasMatch(src), isTrue);
    expect(RegExp(r"handoff\.email\.isNotEmpty\s*\?\s*handoff\.email").hasMatch(src), isTrue);
  });

  test("the app's own state is only a fallback, never the first answer", () {
    // The old shape: read AuthController first, and nothing else. A launch
    // that opens Chat before userData is hydrated sends a token with no name.
    expect(
      RegExp(r"final phone = user\.phoneNumber\.trim\(\);").hasMatch(src),
      isFalse,
      reason: 'the phone is being read from AuthController first again',
    );
    expect(src, contains("(user?.phoneNumber ?? '').trim()"),
        reason: "the fallback to the app's own copy is gone - a server that "
            'returns a blank field would then send nothing at all');
  });

  test('both phone names still go, so the capture node is skipped', () {
    expect(src, contains("params['ctx-phone'] = phone;"));
    expect(src, contains("params['ctx-phone_num'] = phone;"));
    expect(src, contains("params['ctx-name'] = name;"));
    expect(src, contains("params['ctx-email'] = email;"));
  });

  test('the mint cannot hang the chat button open', () {
    // A vendor page that never opens because our own API is slow is a worse
    // outcome than an anonymous one.
    expect(src, contains('connectTimeout'));
    expect(src, contains('receiveTimeout'));
  });

  // ── The support role (BotPenguin, 2026-09-16) ─────────────────────────────
  //
  // "The website passes the token, name, email and phone, but not whether that
  // account is Guest only, Host only or both. Because BotPenguin does not
  // receive this, it has to ask every logged-in user to choose a role."

  test('the role the server decided is what goes in the URL', () {
    expect(src, contains("params['ctx-support_role'] = handoff.supportRole;"),
        reason: 'the bot has nothing to route on without this');
    expect(src, contains("field('support_role')"),
        reason: 'the role must be read off the handoff response');
  });

  test('the role is never invented on the client', () {
    // The whole point is that the SERVER decides from the account record. A
    // client that derived it from, say, the app's own isHost flag would route
    // on whichever mode the user last switched into, not on what they are.
    expect(
      RegExp(r"""supportRole\s*=\s*['"](guest|host|both)['"]""").hasMatch(src),
      isFalse,
      reason: 'nothing may assign a role literal locally — the empty default '
          'on the constructor is the only assignment allowed');
    for (final guess in ["'host'", "'guest'", "'both'"]) {
      expect(
        RegExp('ctx-support_role.*$guess').hasMatch(src), isFalse,
        reason: 'a literal $guess in the URL would be a client-side guess');
    }
  });

  test('only the three agreed values are ever sent', () {
    // A typo or a new value from the server must not reach the bot, which
    // would route on a variable nobody has a branch for.
    expect(src, contains("_supportRoles.contains(role) ? role : ''"));
    expect(src, contains("{'guest', 'host', 'both'}"));
  });

  test('no role sent means the bot asks, which is the safe way to not know', () {
    // Absent, not defaulted. The server omits it when the account lookup
    // fails, and guessing there would start somebody in the wrong journey.
    expect(src, contains('if (handoff.supportRole.isNotEmpty)'),
        reason: 'an empty role must send no parameter at all');
    expect(src, contains("this.supportRole = ''"),
        reason: 'the field defaults to empty, not to a role');
  });
}
