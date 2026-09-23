import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/service/auth_service.dart';

/// "Something went wrong" is not a validation message.
///
/// Reported 2026-09-22: "while trying to sign up with a email which is already
/// registered, something went wrong appears. It must show proper validation
/// message. Earlier it was fine."
///
/// The chain, end to end. /user/is-exist answered HTTP 400 for "yes, that
/// address is taken". `userAlreadyExist` threw on any non-2xx status BEFORE it
/// parsed the body, so the one answer the call exists to obtain arrived as a
/// transport failure; `checkEmailAlreadyExists` caught that and replaced it with
/// a hardcoded 'Something went wrong.' — with the real error mapper sitting
/// commented out on the same line. Every link in that chain had to be wrong for
/// the message to reach the screen, and every link was.
///
/// The server answers 200 for both outcomes now. This pins the client half: the
/// body is the answer, and it is read whatever the status was — so the fix holds
/// against a server that has not been deployed yet, and against one that goes
/// back to 400.
void main() {
  group('the body is the answer', () {
    test('the payload says it is taken', () {
      final body = jsonDecode('{"success":true,"message":"User Already Exist",'
          '"data":{"exists":true,"field":"user_email"}}');
      expect(emailIsTakenFrom(body), isTrue);
    });

    test('the payload says it is free', () {
      final body = jsonDecode('{"success":true,"message":"no record found",'
          '"data":{"exists":false,"field":"user_email"}}');
      expect(emailIsTakenFrom(body), isFalse);
    });

    test('the OLD 400 body is still understood', () {
      // What a server that has not been deployed yet sends. The status was the
      // only thing that used to be read, and it was read as a failure.
      final body = jsonDecode('{"success":false,"message":"User Already Exist","data":[]}');
      expect(emailIsTakenFrom(body), isTrue,
          reason: 'a build in a tester\'s hands has to keep working against '
              'either server');
    });

    test('the old free answer is still understood', () {
      final body = jsonDecode('{"success":true,"message":"no record found","data":[]}');
      expect(emailIsTakenFrom(body), isFalse);
    });

    test('`exists` wins over the message when both are present', () {
      final body = jsonDecode('{"message":"no record found","data":{"exists":true}}');
      expect(emailIsTakenFrom(body), isTrue);
    });

    test('a body that answers neither way is not guessed at', () {
      expect(emailIsTakenFrom(jsonDecode('{"data":[]}')), isNull);
      expect(emailIsTakenFrom(jsonDecode('[]')), isNull);
      expect(emailIsTakenFrom(null), isNull,
          reason: 'null must be reported as unavailable, never as "free" — that '
              'would send a duplicate signup to the server as if it were new');
    });
  });

  group('unavailable is its own answer', () {
    test('it is an Exception a caller can single out', () {
      final e = EmailCheckUnavailable();
      expect(e, isA<Exception>());
      expect(e.toString(), isNot(contains('Something went wrong')),
          reason: 'the generic string is what the tester was shown');
    });

    test('it reads like something written for a person', () {
      expect(EmailCheckUnavailable().toString(), contains('email'));
      expect(EmailCheckUnavailable().toString(), isNot(contains('Exception')));
    });
  });
}
