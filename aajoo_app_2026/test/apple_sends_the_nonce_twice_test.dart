// Sign in with Apple, and the four ways it fails silently.
//
// None of these produce a useful error at runtime. The nonce mistake gives a
// generic "invalid credential" from Firebase that says nothing about nonces;
// the missing webAuthenticationOptions throws on Android before any sheet
// appears; the name is simply absent for ever; and an iOS-only button is not
// an error at all — it is a person on an Android handset who cannot get into
// the account they made on their iPhone.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/service/apple_sign_in.dart';

String _codeOnly(String src) => src
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((l) =>
        !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
    .join('\n');

void main() {
  final service =
      _codeOnly(File('lib/service/apple_sign_in.dart').readAsStringSync());
  final controller = _codeOnly(
      File('lib/ui/screens_common/auth/auth_controller.dart').readAsStringSync());
  final page = _codeOnly(File(
          'lib/ui/screens_common/auth/login_signup/auth_page.dart')
      .readAsStringSync());

  group('the nonce is sent in two different forms', () {
    test('the hash is a real SHA-256, not a stand-in', () {
      // A known vector, so a "hash" that is really a passthrough cannot pass.
      expect(
        sha256OfNonce('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
      expect(sha256OfNonce('abc'), isNot('abc'));
    });

    test('Apple is given the HASH and Firebase the RAW string', () {
      // Getting these the same way round is the classic failure: Firebase
      // hashes the raw nonce itself and compares, so sending it the hash means
      // it compares sha256(sha256(x)) against sha256(x) and refuses.
      expect(service, contains('nonce: sha256OfNonce(rawNonce)'),
          reason: 'Apple is not being given the hashed nonce');
      expect(service, contains('rawNonce: rawNonce'),
          reason: 'Firebase is not being given the raw nonce');
      expect(service.contains('nonce: rawNonce'), isFalse,
          reason: 'the RAW nonce is being sent to Apple — Firebase will reject '
              'every credential with a message that never mentions the nonce');
    });

    test('the nonce is unpredictable', () {
      expect(service, contains('Random.secure()'),
          reason: 'a predictable nonce defeats the replay protection it exists for');
      final a = generateRawNonce();
      final b = generateRawNonce();
      expect(a.length, 32);
      expect(a, isNot(b));
    });
  });

  group('the name Apple sends once', () {
    test('both halves, either half, or neither', () {
      expect(appleFullName('Sam', 'Tao'), 'Sam Tao');
      expect(appleFullName('Sam', null), 'Sam');
      expect(appleFullName(null, 'Tao'), 'Tao');
      expect(appleFullName(null, null), isNull);
      expect(appleFullName('', '  '), isNull);
      // "null null" has shipped as a display name in more than one app.
      expect(appleFullName(null, null), isNot('null null'));
    });

    test('it is carried to the server, because the token never has it', () {
      expect(service, contains('appleFullName(credential.givenName'),
          reason: 'the name Apple gives on first authorization is dropped');
      expect(controller, contains('fullName: result.fullName'),
          reason: 'the controller does not pass the name to the service');
    });
  });

  test('Android is given the web flow it cannot work without', () {
    // On iOS the system sheet handles this. Everywhere else the package
    // redirects through Apple's web flow, which needs the Services ID as its
    // client id and the Firebase handler as its return URL — and throws
    // outright if they are missing.
    expect(service, contains('webAuthenticationOptions'));
    expect(service, contains('clientId: kAppleServicesId'));
    expect(service, contains('redirectUri: Uri.parse(kAppleRedirectUri)'));

    // These two must match what is registered at developer.apple.com exactly.
    expect(kAppleServicesId, 'com.aajoo.aajoohomes.web');
    expect(kAppleRedirectUri,
        'https://aajoo-bdb20.firebaseapp.com/__/auth/handler');
  });

  test('the button is NOT hidden behind a platform check', () {
    // This is the whole cross-platform point. An account made on an iPhone
    // with Apple has an unusable password by design, so an iOS-only button
    // locks that person out of their own account on Android.
    expect(page, contains('SignInWithAppleButton'),
        reason: 'the Apple button is not on the auth page at all');

    final buttonAt = page.indexOf('SignInWithAppleButton');
    final around = page.substring(
        (buttonAt - 800).clamp(0, page.length), buttonAt);
    expect(around.contains('Platform.isIOS'), isFalse,
        reason: 'the Apple button is gated on iOS — an Android user who signed '
            'up on an iPhone would have no way into their account');
  });

  test('backing out of the Apple sheet is not reported as a failure', () {
    expect(service, contains('AuthorizationErrorCode.canceled'));
    expect(service, contains('throw AppleSignInCancelled()'));
    expect(controller, contains('on apple.AppleSignInCancelled'));

    // And that branch must not show an error. The block has to be bounded by
    // the NEXT catch clause, not by a character count: a fixed window ran off
    // the end of this branch into the `notSupported` one below it, which does
    // report an error, and this test failed on code that was correct.
    final at = controller.indexOf('on apple.AppleSignInCancelled');
    final nextOn = controller.indexOf('} on ', at + 1);
    final nextCatch = controller.indexOf('} catch', at + 1);
    final end = [nextOn, nextCatch]
        .where((i) => i > at)
        .fold<int>(controller.length, (a, b) => a < b ? a : b);
    final block = controller.substring(at, end);
    expect(block.contains('_showLoginError'), isFalse,
        reason: 'cancelling the sheet shows an error message');
  });

  test('the Firebase session is not left behind after our own is issued', () {
    // Two live sessions is how a stale Firebase user ends up answering for a
    // person who has since signed out of ours.
    expect(controller, contains('fb.FirebaseAuth.instance.signOut()'));
    final loginAt = controller.indexOf('Future<void> loginWithApple');
    final methodEnd = controller.indexOf('Future<void>', loginAt + 10);
    final body = controller.substring(
        loginAt, methodEnd == -1 ? controller.length : methodEnd);
    expect(body, contains('fb.FirebaseAuth.instance.signOut()'),
        reason: 'the Apple path leaves the Firebase session open');
  });
}
