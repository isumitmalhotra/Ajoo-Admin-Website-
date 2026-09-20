// Step 3 carries 88 amenity chips in seven groups and a host looking for
// "wifi" read every one of them (300-case run, HL-043, 2026-09-21). The
// controller indexes every chip with its group; typing narrows to the ones
// whose name — or group — contains the words. The same sitting found the
// pool chip never opened Pool Type on this platform (HL-044): the website
// set has_pool from the chip, the app set only has_wifi.
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/listing_schema.dart';
import 'package:rent_home/ui/screens_host/listing/listing_wizard_controller.dart';

ListingSchema schema() => ListingSchema.fromJson({
      'essentialAmenities': [
        {'key': 'internet', 'label': 'Internet', 'options': [
          {'value': 'wifi', 'label': 'WiFi'}, {'value': 'high_speed_wifi', 'label': 'High Speed WiFi'}]},
        {'key': 'power', 'label': 'Power', 'options': [
          {'value': 'generator', 'label': 'Generator'}, {'value': 'inverter', 'label': 'Inverter'}]},
      ],
      'safetyGroups': [
        {'key': 'security', 'label': 'Security', 'options': [{'value': 'cctv', 'label': 'CCTV'}]},
      ],
      'outdoorAmenities': {'key': 'outdoor', 'label': 'Outdoor', 'options': [{'value': 'garden', 'label': 'Garden'}]},
      'premiumAmenities': {'key': 'premium', 'label': 'Premium', 'options': [
        {'value': 'swimming_pool', 'label': 'Swimming Pool'}, {'value': 'gym', 'label': 'Gym'}]},
      'accessibility': {'key': 'accessibility', 'label': 'Accessibility', 'options': [{'value': 'ramp', 'label': 'Ramp'}]},
      'familyAmenities': {'key': 'family', 'label': 'Family', 'options': [{'value': 'crib', 'label': 'Crib'}]},
      'pricingRules': {'minBasePrice': 100, 'maxBasePrice': 100000},
    });

void main() {
  test('every chip is indexed once, with its group', () {
    final c = ListingWizardController();
    c.schema.value = schema();
    expect(c.amenityIndex.length, 10);
    expect(c.amenityIndex.where((h) => h.group == 'premium').length, 2);
  });

  test('"wifi" finds the two WiFi chips and nothing else; the match is case-blind', () {
    final c = ListingWizardController();
    c.schema.value = schema();
    c.amenityQuery.value = 'WiFi';
    expect(c.amenityMatches.map((h) => h.option.value), ['wifi', 'high_speed_wifi']);
    c.amenityQuery.value = '  gen ';
    expect(c.amenityMatches.map((h) => h.option.value), ['generator']);
    c.amenityQuery.value = 'security';
    expect(c.amenityMatches.map((h) => h.option.value), ['cctv'], reason: 'a group name finds its chips');
    c.amenityQuery.value = 'hot tub';
    expect(c.amenityMatches, isEmpty);
    c.amenityQuery.value = '';
    expect(c.amenityMatches, isEmpty, reason: 'an empty box shows the groups, not a list');
  });

  test('a chip ticked from the search list is ticked in its group, with its consequences', () {
    final c = ListingWizardController();
    c.schema.value = schema();
    c.toggleAmenity('premium', 'swimming_pool');
    expect(c.amenities['premium'], ['swimming_pool']);
    expect(c.details['has_pool'], isTrue, reason: 'Pool Type is asked (HL-044)');
    c.toggleAmenity('premium', 'swimming_pool');
    expect(c.details['has_pool'], isFalse);
    c.toggleAmenity('internet', 'high_speed_wifi');
    expect(c.details['has_wifi'], isTrue);
  });
}
