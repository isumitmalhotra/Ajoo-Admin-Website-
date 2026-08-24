import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/profile_completion.dart';

void main() {
  // Weights: name1 email1 phone2 photo1 dob1 address1 city1 kyc3 = 11 total.
  test('an empty profile scores zero and is Basic', () {
    final s = profileScore({});
    expect(s.percent, 0);
    expect(s.strength, 'Basic');
    expect(s.missing.length, 8);
  });

  test('a fully filled, verified profile is 100% Complete', () {
    final s = profileScore({
      'user_fullName': 'Test Guest',
      'cred_user_email': 'a@b.com',
      'user_pnumber': '9990001111',
      'attachment': 'https://img',
      'user_dob': '1996-06-06',
      'user_address': '2 Renter Rd',
      'user_city': 'Najafgarh',
      'verification_status': 'verified',
    });
    expect(s.percent, 100);
    expect(s.strength, 'Complete');
    expect(s.missing, isEmpty);
    expect(s.isComplete, isTrue);
  });

  test('KYC is the heaviest single gap', () {
    final base = {
      'user_fullName': 'A', 'cred_user_email': 'a@b.com',
      'user_pnumber': '1', 'attachment': 'i', 'user_dob': 'd',
      'user_address': 'x', 'user_city': 'c',
    };
    // Everything but KYC = 8/11 -> 73%, which is still only "Good".
    final s = profileScore(base);
    expect(s.percent, 73);
    expect(s.strength, 'Good');
    expect(s.missing.single.key, 'kyc');
  });

  test('verification reads either the flag or a current decision', () {
    expect(profileScore({'user_isVerified': 1}).fields
        .firstWhere((f) => f.key == 'kyc').done, isTrue);
    expect(profileScore({'verification_status': 'verified'}).fields
        .firstWhere((f) => f.key == 'kyc').done, isTrue);
    // An abandoned attempt leaves "pending" — that is NOT verified.
    expect(profileScore({'verification_status': 'pending'}).fields
        .firstWhere((f) => f.key == 'kyc').done, isFalse);
  });

  test('whitespace is not a filled field', () {
    expect(profileScore({'user_fullName': '   '}).percent, 0);
  });
}
