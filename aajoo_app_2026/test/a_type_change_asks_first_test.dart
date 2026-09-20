// Changing the category cleared every type-specific answer the moment the
// new chip was tapped, without a word (300-case run, HL-034, 2026-09-21).
// The screen now asks when there is something to lose; the controller says
// how much that is, and still does the clearing once the host agrees.
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/ui/screens_host/listing/listing_wizard_controller.dart';

void main() {
  test('the count of answers a type change would clear', () {
    final c = ListingWizardController();
    c.attrs.addAll({
      'camp_type': 'Riverside Camp',
      'tent_count': '4',
      'shared_washroom': true,
      'electricity': false,          // a switch left off is not an answer
      'adventure_activities': <String>[], // nor an empty list
      'bonfire_included': null,
      'notes': '   ',
    });
    expect(c.typeAnswersGiven, 3);
  });

  test('nothing given, nothing to ask about', () {
    final c = ListingWizardController();
    expect(c.typeAnswersGiven, 0);
    c.attrs['x'] = '';
    expect(c.typeAnswersGiven, 0);
  });

  test('the change itself still clears the old type\'s answers', () {
    final c = ListingWizardController();
    c.f['property_category'] = 'camping';
    c.attrs['camp_type'] = 'Riverside Camp';
    c.experiences.add('Trekking');
    c.setF('property_category', 'villa');
    expect(c.f['property_category'], 'villa');
    expect(c.attrs, isEmpty);
    expect(c.experiences, isEmpty);
  });
}
