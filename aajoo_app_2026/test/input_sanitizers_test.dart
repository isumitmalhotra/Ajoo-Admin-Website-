import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/input_sanitizers.dart';

/// What a field will and will not accept as it is typed.
///
/// A validator answers "is this acceptable?" at submit; these answer "can this
/// character ever appear?" at typing time. The distinction matters because
/// `keyboardType` only decides which keys are SHOWN — a paste, a hardware
/// keyboard or a swipe keyboard all ignore it, which is how the traveller form
/// came to accept names with digits and phone numbers with letters.
String run(List<TextInputFormatter> fs, String input) {
  var v = const TextEditingValue(text: '');
  for (final f in fs) {
    v = f.formatEditUpdate(
      const TextEditingValue(text: ''),
      TextEditingValue(text: input, selection: TextSelection.collapsed(offset: input.length)),
    );
    input = v.text;
  }
  return v.text;
}

void main() {
  _propertyNameTests();
  group('names accept every script, not just Latin', () {
    test('a Devanagari name survives', () {
      // This returned "" before 2026-09-01: the filter was [A-Za-z] only, so
      // the field stayed empty while the guest typed.
      expect(run(AppInputFormatters.name, 'सुमित'), 'सुमित');
    });

    test('a Latin name still works', () {
      expect(run(AppInputFormatters.name, "O'Brien-Smith"), "O'Brien-Smith");
    });

    test('digits are still refused in a name', () {
      expect(run(AppInputFormatters.name, 'Sumit123'), 'Sumit');
    });

    test('emoji are refused in a name', () {
      expect(run(AppInputFormatters.name, 'Sumit😀'), 'Sumit');
    });
  });

  group('mobile numbers survive how people actually paste them', () {
    test('a pasted +91 number keeps the right ten digits', () {
      // digitsOnly + a 10-char cap would give "9198765432" — ten digits, passes
      // every validator, and the wrong number.
      expect(run(AppInputFormatters.mobile, '+91 98765 43210'), '9876543210');
    });

    test('a bare number starting 91 is not eaten', () {
      expect(run(AppInputFormatters.mobile, '9198765432'), '9198765432');
    });

    test('letters never reach a phone field', () {
      expect(run(AppInputFormatters.mobile, '98abc76543'), '9876543');
    });
  });

  group('money fields', () {
    test('a single decimal point is kept', () {
      expect(run(AppInputFormatters.amount, '1234.50'), '1234.50');
    });

    test('letters are dropped from a counter-offer price', () {
      expect(run(AppInputFormatters.amount, '12e5'), '125');
    });

    test('a minus sign cannot start a price', () {
      expect(run(AppInputFormatters.amount, '-500'), '500');
    });
  });

  group('codes', () {
    test('IFSC is upper-cased and stripped of punctuation', () {
      expect(run(AppInputFormatters.upperAlnum(11), 'hdfc-0001@23'), 'HDFC000123');
    });

    test('email drops whitespace but keeps the address', () {
      expect(run(AppInputFormatters.email, ' a@b.com '), 'a@b.com');
    });
  });
}

/// The listing name, held to what the server will actually accept.
///
/// The wizard prints the rule directly above the field — "Letters, numbers,
/// spaces and only & or -" — and then took "Test@#Villa\&Co" anyway, so the
/// host discovered on submit that the sentence above the box was true.
void _propertyNameTests() {
  group('propertyName', () {
    test('the junk that was accepted on the device is now refused', () {
      expect(run(AppInputFormatters.propertyName, r'Test@#Villa123-Pine\&Co'),
          'TestVilla123-Pine&Co');
    });

    test('a normal name passes untouched', () {
      expect(run(AppInputFormatters.propertyName, 'The Pine Valley Cottage'),
          'The Pine Valley Cottage');
    });

    test('the two punctuation marks the rule allows survive', () {
      expect(run(AppInputFormatters.propertyName, 'Bed & Breakfast - Manali'),
          'Bed & Breakfast - Manali');
    });

    test('80 characters is the ceiling', () {
      expect(run(AppInputFormatters.propertyName, 'A' * 100).length, 80);
    });

    test('emoji do not reach a listing name', () {
      expect(run(AppInputFormatters.propertyName, 'Villa 😀 Rose'), 'Villa  Rose');
    });
  });
}
