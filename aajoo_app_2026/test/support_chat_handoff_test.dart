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

  test('the mint cannot hang the chat button open', () {
    // A vendor page that never opens because our own API is slow is a worse
    // outcome than an anonymous one.
    expect(src, contains('connectTimeout'));
    expect(src, contains('receiveTimeout'));
  });
}
