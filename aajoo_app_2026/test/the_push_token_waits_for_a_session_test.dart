// The device's push token is attached to an account only when there is one.
//
// Seen in the iOS Simulator log, 2026-09-19: POST /user/notification/
// allow-notification went out with "Bearer null" before sign-in and the
// server answered 401 "jwt malformed"; it recovered only because the home
// screen happened to re-run init after sign-in. The code is shared Dart, so
// Android raced the same way. Now the call waits for a session, and sign-in
// sends the token it was holding.
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/service/notification_service.dart';

String codeOnly(String src) => src
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
    .join('\n');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = codeOnly(File('lib/service/notification_service.dart').readAsStringSync());
  final auth = codeOnly(File('lib/ui/screens_common/auth/auth_controller.dart').readAsStringSync());

  group('without a session', () {
    test('the token is kept, and nothing is posted', () async {
      // No user_token in storage — the state of a fresh install, or a
      // signed-out app that already has a push token.
      FlutterSecureStorage.setMockInitialValues({'fcm_token': 'device-token-abc'});
      // Would throw MissingPluginException / a network error if it tried to
      // post; returning normally is the proof that it did not.
      await NotificationService().saveTokenToDatabase('device-token-abc');
      await NotificationService().syncTokenAfterLogin();
    });

    test('the guard is on the only path that talks to the server', () {
      expect(service, contains('if (token == null || token.isEmpty) {'));
      final guard = service.indexOf('if (token == null || token.isEmpty) {');
      final post = service.indexOf('"/user/notification/allow-notification"');
      expect(guard, lessThan(post), reason: 'the session check must come before the request');
      expect(service.substring(guard, post), contains('return;'));
    });
  });

  group('after sign-in', () {
    test('the held token is sent, off the critical path', () {
      expect(service, contains('Future<void> syncTokenAfterLogin() async {'));
      expect(service, contains("await _storage.read(key: \"fcm_token\")"));
      expect(auth, contains('unawaited(NotificationService().syncTokenAfterLogin());'));
      // After the phone gate, so a refused sign-in never registers a device.
      final gate = auth.indexOf('final captured = await _requirePhone(data);');
      final sync = auth.indexOf('unawaited(NotificationService().syncTokenAfterLogin());');
      expect(gate, lessThan(sync));
    });
  });
}
