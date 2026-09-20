// The reviewer's note reached the host as a notification and an email and
// nowhere else: the property card said "Rejected" and the wizard the host
// was sent back into said nothing (300-case run, HL-089, 2026-09-21). The
// draft now carries `review` and the list rows `review_notes`; the wizard
// opens with the decision and the card prints the reason.
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/host_properties_reponse.dart';
import 'package:rent_home/service/listing_service.dart';
import 'package:rent_home/models/listing_schema.dart';
import 'package:rent_home/ui/screens_host/listing/listing_wizard_controller.dart';

class _StubService extends ListingService {
  _StubService(this.draft);
  final Map<String, dynamic> draft;

  @override
  Future<ListingSchema> getSchema({bool refresh = false}) async =>
      ListingSchema.fromJson({
        'pricingRules': {'minBasePrice': 100, 'maxBasePrice': 100000},
      });

  @override
  Future<Map<String, dynamic>> getDraft(int propertyId) async => draft;
}

void main() {
  ListingWizardController wizard(Map<String, dynamic> draft) =>
      ListingWizardController(propertyId: 29312, service: _StubService(draft));

  test('a rejected listing opens with the decision and the reviewer\'s words',
      () async {
    final c = wizard({
      'pricing': {'ppr_base_price': 3000},
      'review': {
        'status': 'rejected',
        'notes': 'The cover photo is a plain test image. Replace it.',
        'reviewedAt': '2026-09-20T21:46:48.000Z',
      },
    });
    c.onInit();
    await Future<void>.delayed(Duration.zero);
    expect(c.reviewStatus.value, 'rejected');
    expect(c.reviewNotes.value,
        'The cover photo is a plain test image. Replace it.');
  });

  test('a listing back under review, or live, carries no note', () async {
    final c = wizard({
      'pricing': {'ppr_base_price': 3000},
      'review': null,
    });
    c.onInit();
    await Future<void>.delayed(Duration.zero);
    expect(c.reviewStatus.value, isEmpty);
    expect(c.reviewNotes.value, isEmpty);
  });

  test('the list row\'s review_notes reach the property card', () {
    final p = Property.fromJson({
      'property_id': 29312,
      'property_host_id': 100,
      'property_name': 'QA Wizard Test 21 Sep',
      'property_address': 'Sector 29',
      'property_longitude': '77.0',
      'property_latitude': '28.4',
      'property_desc': '',
      'property_price': '3000.00',
      'property_mini_price': '2500.00',
      'property_city': 'Gurugram',
      'property_zip': '122001',
      'property_state': 'Haryana',
      'property_contry': 'India',
      'property_contact': '',
      'property_email': '',
      'is_active': false,
      'is_verify': 'Rejected',
      'verification_status': 'rejected',
      'review_status': 'rejected',
      'review_notes': '  Replace the cover photo.  ',
    });
    expect(p.isRejected, isTrue);
    expect(p.reviewNotes, 'Replace the cover photo.');
    // ...and an approved row, which the server sends without one, is empty.
    final live = Property.fromJson({
      'property_id': 29302,
      'property_host_id': 100,
      'property_name': 'QA Sunrise Villa',
      'property_address': '',
      'property_longitude': '',
      'property_latitude': '',
      'property_desc': '',
      'property_price': '3000.00',
      'property_mini_price': '',
      'property_city': '',
      'property_zip': null,
      'property_state': '',
      'property_contry': '',
      'property_contact': null,
      'property_email': '',
      'is_active': true,
      'is_verify': true,
      'verification_status': 'verified',
      'review_status': null,
      'review_notes': null,
    });
    expect(live.reviewNotes, isEmpty);
    expect(live.copyWith(propertyName: 'x').reviewNotes, isEmpty);
    expect(p.copyWith(propertyName: 'x').reviewNotes, 'Replace the cover photo.');
  });
}
