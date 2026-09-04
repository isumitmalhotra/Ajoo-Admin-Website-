import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/email_validation.dart';

void main() {
  group('isValidEmail', () {
    test('accepts a plus-addressed gmail — the reported blocker', () {
      // Bug #14. The login screen rejected this at BOTH login and signup, so
      // the account could never be created in the first place.
      expect(isValidEmail('itsme.aishsriv007+host2@gmail.com'), isTrue);
      expect(isValidEmail('you+tag@gmail.com'), isTrue);
    });

    test('accepts TLDs longer than four characters', () {
      // The old pattern capped the TLD at {2,4}.
      expect(isValidEmail('someone@aajoo.online'), isTrue);
      expect(isValidEmail('curator@some.museum'), isTrue);
      expect(isValidEmail('a@b.travel'), isTrue);
    });

    test('accepts ordinary addresses', () {
      expect(isValidEmail('host@aajoohomes.com'), isTrue);
      expect(isValidEmail('first.last@sub.domain.co.in'), isTrue);
      expect(isValidEmail('  padded@example.com  '), isTrue, reason: 'trimmed');
    });

    test('still refuses things that are not addresses', () {
      expect(isValidEmail(''), isFalse);
      expect(isValidEmail(null), isFalse);
      expect(isValidEmail('no-at-sign.com'), isFalse);
      expect(isValidEmail('two@@at.com'), isFalse);
      expect(isValidEmail('no@tld'), isFalse);
      expect(isValidEmail('trailing@dot.'), isFalse);
      expect(isValidEmail('has space@example.com'), isFalse);
      expect(isValidEmail('@nolocal.com'), isFalse);
    });

    test('agrees with the website, which is the point of sharing it', () {
      // Mirrors src/redesign/lib/formErrors.ts isEmail. An address accepted on
      // the website must be accepted here, or a guest who signed up on the web
      // cannot log into the app.
      for (final ok in [
        'a+b@c.co',
        'UPPER@Example.COM',
        "o'brien@example.com",
        'dash-name@ex-ample.com',
      ]) {
        expect(isValidEmail(ok), isTrue, reason: ok);
      }
    });
  });

  group('looksLikeMobile', () {
    test('ten digits is a mobile', () {
      expect(looksLikeMobile('9611577338'), isTrue);
      expect(looksLikeMobile('96115 77338'), isTrue, reason: 'spacing ignored');
    });

    test('anything with an @ is an email attempt, not a number', () {
      expect(looksLikeMobile('9611577338@gmail.com'), isFalse);
    });

    test('the wrong number of digits is neither', () {
      expect(looksLikeMobile('961157733'), isFalse);
      expect(looksLikeMobile('96115773380'), isFalse);
      expect(looksLikeMobile(''), isFalse);
    });
  });
}
