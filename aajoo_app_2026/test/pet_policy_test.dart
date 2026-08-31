import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/pet_policy.dart';
import 'package:rent_home/utils/booking_pricing.dart';

/// Pets, on the phone.
///
/// The host has set a pet policy since the listing wizard shipped and none of
/// it reached a guest until 2026-08-31. These cover the two things that decide
/// whether a guest is charged correctly: parsing the policy off the wire, and
/// putting the fee through the same discount-and-tax path the server uses.
void main() {
  group('PetPolicy.fromJson', () {
    test('reads the block the API sends', () {
      final p = PetPolicy.fromJson({
        'petsAllowed': true,
        'petFeePerNight': 200,
        'petSize': 'Small / Medium',
        'maxPets': 2,
      });
      expect(p.petsAllowed, isTrue);
      expect(p.feePerNight, 200);
      expect(p.size, 'Small / Medium');
      expect(p.maxPets, 2);
    });

    test('a DECIMAL arriving as a string still parses', () {
      // phr_pet_fee is a DECIMAL and mysql2 hands it over as "200.00".
      // int.parse returns null on that — the same fault that once drew a
      // five-star review as five empty stars.
      final p = PetPolicy.fromJson({'petsAllowed': 1, 'petFeePerNight': '200.00'});
      expect(p.petsAllowed, isTrue);
      expect(p.feePerNight, 200);
    });

    test('a listing with no policy takes no pets', () {
      expect(PetPolicy.fromJson(null).petsAllowed, isFalse);
      expect(PetPolicy.fromJson('nonsense').petsAllowed, isFalse);
      expect(PetPolicy.none.petsAllowed, isFalse);
      // Absent is not permissive: a host who was never asked has not said yes.
      expect(PetPolicy.fromJson({}).petsAllowed, isFalse);
    });

    test('an empty pet size is null, not an empty string on screen', () {
      expect(PetPolicy.fromJson({'petsAllowed': true, 'petSize': '  '}).size, isNull);
    });
  });

  group('the fee is per pet, per night', () {
    const p = PetPolicy(petsAllowed: true, feePerNight: 200, maxPets: 2);

    test('2 pets x 3 nights x 200 = 1200', () => expect(p.feeFor(2, 3), 1200));
    test('1 pet x 2 nights = 400', () => expect(p.feeFor(1, 2), 400));
    test('no pets declared costs nothing', () => expect(p.feeFor(0, 3), 0));
    test('a host who says no charges nothing', () {
      expect(const PetPolicy(petsAllowed: false, feePerNight: 200).feeFor(2, 3), 0);
    });
    test('no fee set charges nothing', () {
      expect(const PetPolicy(petsAllowed: true).feeFor(2, 3), 0);
    });
  });

  group('the fee reaches the total', () {
    test('pets are taxed with the room, like the party charge', () {
      // 2 nights at 5,000 = 10,000 room; 2 pets x 200 x 2 = 800.
      // 10,800 + 5% GST = 11,340 — the figure the live quote returns.
      final s = priceStay(
        roomSubtotal: 10000,
        perNightTariff: 5000,
        petFee: 800,
        pets: 2,
      );
      expect(s.chargeable, 10800);
      expect(s.taxes, 540);
      expect(s.total, 11340);
      expect(s.petFee, 800);
      expect(s.pets, 2);
    });

    test('no pets leaves the total exactly as it was', () {
      final without = priceStay(roomSubtotal: 10000, perNightTariff: 5000);
      final withZero =
          priceStay(roomSubtotal: 10000, perNightTariff: 5000, petFee: 0, pets: 0);
      expect(withZero.total, without.total);
    });

    test('a discount applies to room + pets together, as the server does', () {
      final s = priceStay(
        roomSubtotal: 10000,
        perNightTariff: 5000,
        petFee: 800,
        pets: 2,
        discount: 1080,
      );
      // 10,800 - 1,080 = 9,720, then 5% on that.
      expect(s.taxes, 486);
      expect(s.total, 10206);
    });
  });
}
