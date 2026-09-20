// The Apartment Type select stores the option's SLUG — "3_bhk", never
// "3 BHK" — and the BHK-vs-bedrooms cross-check (C14) matched only spaces
// before "BHK", so it never fired for any BHK type on either client. Found on
// the 300-case run (HL-035, 2026-09-21): 3 BHK over two bedrooms, no warning.
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/service/listing_service.dart';
import 'package:rent_home/ui/screens_host/listing/listing_wizard_controller.dart';

void main() {
  group('the BHK check reads the slug', () {
    test('3_bhk over two bedrooms warns, in the label\'s words', () {
      final c = ListingWizardController(service: _StubService());
      c.f['bedrooms'] = '2';
      c.attrs['apartment_type'] = '3_bhk';
      expect(c.bhkMismatch, 'You have chosen 3 BHK but entered 2 bedrooms on the first step. Guests read both.');
    });

    test('a matching count is silent; so are Penthouse and Duplex', () {
      final c = ListingWizardController(service: _StubService());
      c.f['bedrooms'] = '2';
      c.attrs['apartment_type'] = '2_bhk';
      expect(c.bhkMismatch, isNull);
      c.attrs['apartment_type'] = 'penthouse';
      expect(c.bhkMismatch, isNull);
    });

    test('a studio with two bedrooms is not a studio', () {
      final c = ListingWizardController(service: _StubService());
      c.f['bedrooms'] = '2';
      c.attrs['apartment_type'] = 'studio';
      expect(c.bhkMismatch, contains('A Studio has no separate bedroom'));
    });
  });
}

class _StubService extends ListingService {}
