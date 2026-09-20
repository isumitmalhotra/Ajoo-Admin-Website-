// pc_beds is summed from the room cards once any names a bed; the step-1
// check read the typed figure. The phone typed 3 beds, described one queen
// bed in one of two bedrooms, and posted a listing the server then published
// as "2 bedrooms · 1 bed · 4 guests" (300-case run, HL-027/028, 2026-09-21).
// The check now runs on the figure that will be stored — the website's rule
// since 2026-08-31, and the server's since the same sitting.
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/listing_schema.dart';
import 'package:rent_home/ui/screens_host/listing/listing_wizard_controller.dart';

ListingWizardController _twoBedroomsFourGuests() {
  final c = ListingWizardController();
  c.f.addAll({
    'host_type': 'owner',
    'property_category': 'apartment',
    'accommodation_type': 'entire_property',
    'property_name': 'QA Wizard Test 21 Sep',
    'description': 'A two-bedroom apartment for the 300-case wizard run with a lift and parking.',
    'max_adults': '3',
    'max_children': '1',
    'max_infants': '1',
    'bedrooms': '2',
    'beds': '3',
    'bathrooms': '2',
  });
  return c;
}

void main() {
  test('one queen bed described across two bedrooms is refused, whatever was typed', () {
    final c = _twoBedroomsFourGuests();
    c.bedroomDetail.addAll([
      const RoomEntry(index: 1, type: 'master_bedroom', bathroom: 'attached', beds: [BedEntry(type: 'queen', count: 1)]),
      const RoomEntry(index: 2),
    ]);
    expect(c.bedsFromRooms, 1);
    final errs = c.validateStep1();
    expect(errs['beds'], '2 bedrooms need at least 2 beds between them');
  });

  test('no room names a bed: the typed figure stands', () {
    final c = _twoBedroomsFourGuests();
    c.bedroomDetail.addAll([const RoomEntry(index: 1), const RoomEntry(index: 2)]);
    expect(c.bedsAreDerived, isFalse);
    expect(c.validateStep1()['beds'], isNull);
  });

  test('two beds described, two bedrooms: fine', () {
    final c = _twoBedroomsFourGuests();
    c.bedroomDetail.addAll([
      const RoomEntry(index: 1, beds: [BedEntry(type: 'queen', count: 1)]),
      const RoomEntry(index: 2, beds: [BedEntry(type: 'single', count: 1)]),
    ]);
    expect(c.validateStep1()['beds'], isNull);
  });
}
