import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rent_home/models/listing_schema.dart';
import 'package:rent_home/service/listing_service.dart';
import 'package:rent_home/ui/screens_host/listing/listing_wizard_controller.dart';

/// A listing cannot be published without photographs — said on the step where
/// the host can still do something about it.
///
/// Reported 2026-09-10. The Photos step says, in as many words: "At least 10,
/// 20 recommended. Tag at least one as Exterior, Bedroom, Bathroom, Entrance."
/// It then let the host walk past it, fill in pricing, fill in verification,
/// agree to the declarations, and be refused at the last button — by which
/// point adding photographs means going back to the property.
///
/// The server is the authority (photoGapFor in listingStep5.controller) and
/// this is the same arithmetic, said earlier. Two things it must get right
/// that a count alone does not:
///
///   1. THE TAGS. The app uploaded every photograph untagged, so the four
///      required kinds could only ever be satisfied on the website. Twelve
///      untagged photographs are not a publishable set.
///   2. DOCUMENTS ARE NOT PHOTOGRAPHS. Identity and ownership proofs live in
///      the same list under type "document". Counting them let a sale deed
///      stand in for a bedroom.
void main() {
  /// Only the part of the schema this behaviour reads. Everything else on
  /// /listing/schema defaults, which is why this goes through fromJson rather
  /// than the 28-argument constructor.
  final schema = ListingSchema.fromJson({
    'photoRules': {
      'minimum': 10,
      'recommended': 20,
      'required': ['exterior', 'bedroom', 'bathroom', 'entrance'],
      'categories': [
        {'value': 'exterior', 'label': 'Exterior'},
        {'value': 'bedroom', 'label': 'Bedroom'},
        {'value': 'bathroom', 'label': 'Bathroom'},
        {'value': 'entrance', 'label': 'Entrance'},
        {'value': 'cover_photo', 'label': 'Cover photo'},
      ],
      'byAccommodation': {
        'entire_property': {
          'minimum': 10,
          'required': ['exterior', 'bedroom', 'bathroom', 'entrance'],
        },
        'private_room': {
          'minimum': 5,
          'required': ['bedroom', 'bathroom', 'entrance'],
        },
      },
    },
  });

  List<Map<String, dynamic>> photos(int n,
          [List<String> categories = const []]) =>
      [
        for (var i = 0; i < n; i++)
          {
            'id': i + 1,
            'type': 'photo',
            'category': i < categories.length ? categories[i] : '',
          },
      ];

  ListingWizardController wizard({
    String accommodation = 'entire_property',
    List<Map<String, dynamic>> media = const [],
    ListingService? service,
  }) {
    final c = ListingWizardController(propertyId: 1, service: service);
    c.schema.value = schema;
    c.f['accommodation_type'] = accommodation;
    c.propertyId.value = 1;
    c.media.assignAll(media);
    return c;
  }

  test('nothing uploaded: the ask is the whole rule', () {
    final gap = wizard(service: _StubService()).photoGapReason;
    expect(gap, isNotNull);
    expect(gap, contains('add 10 photos'));
    expect(gap, contains('Exterior'),
        reason: 'the host is not told which tags are needed');
    // Words a host can act on, not a validation code.
    expect(gap, startsWith('Before publishing,'));
  });

  test('THE ONE THE APP COULD NOT SATISFY: twelve untagged photographs', () {
    // Every photo the app uploaded went up with an empty category, and there
    // was no way to change one. Counting alone waves this through, and the
    // server then refuses it.
    final gap = wizard(media: photos(12), service: _StubService()).photoGapReason;
    expect(gap, isNotNull,
        reason: 'twelve untagged photographs pass a rule that asks for four '
            'named ones');
    expect(gap, isNot(contains('more photo')),
        reason: 'the refusal asks for more photos when the count is met: $gap');
    expect(gap, contains('tag one photo as'));
  });

  test('tagged but short: it says how many are left', () {
    final gap = wizard(
      media: photos(4, ['exterior', 'bedroom', 'bathroom', 'entrance']),
      service: _StubService(),
    ).photoGapReason;
    expect(gap, contains('add 6 more photos (4 of 10)'));
    expect(gap, isNot(contains('tag one photo')));
  });

  test('a complete set is not refused', () {
    expect(
      wizard(
        media: photos(10, ['exterior', 'bedroom', 'bathroom', 'entrance']),
        service: _StubService(),
      ).photoGapReason,
      isNull,
    );
  });

  test('a single room is held to the room tier, and asked for no exterior', () {
    final room = wizard(
      accommodation: 'private_room',
      media: photos(5, ['bedroom', 'bathroom', 'entrance']),
      service: _StubService(),
    );
    expect(room.photoGapReason, isNull,
        reason: 'a complete room set was refused: ${room.photoGapReason}');

    // The same five would NOT do for a whole property.
    expect(
      wizard(
        media: photos(5, ['bedroom', 'bathroom', 'entrance']),
        service: _StubService(),
      ).photoGapReason,
      isNotNull,
    );
  });

  test('a verification document is not a photograph', () {
    final c = wizard(service: _StubService(), media: [
      ...photos(8, ['exterior', 'bedroom', 'bathroom', 'entrance']),
      {'id': 90, 'type': 'document', 'category': 'identity'},
      {'id': 91, 'type': 'document', 'category': 'exterior'},
    ]);
    expect(c.photos.length, 8,
        reason: 'documents are being counted as photographs');
    expect(c.photoGapReason, contains('add 2 more photos (8 of 10)'),
        reason: 'two identity documents made up the shortfall in a gallery');
  });

  test('no schema in hand is not a rule to enforce', () {
    // An offline draft has no rules loaded. Refusing on a rule we do not have
    // would be a wizard that cannot be finished.
    final c = ListingWizardController(propertyId: 1, service: _StubService());
    expect(c.photoGapReason, isNull);
  });

  group('Continue', () {
    test('saves the step, then holds — and lets them past the second time',
        () async {
      final service = _StubService();
      final c = wizard(service: service);
      c.step.value = 2;

      final first = await c.saveAndContinue();
      expect(first, isFalse, reason: 'the host was let past the Photos step');
      expect(c.step.value, 2, reason: 'the step advanced anyway');
      // SAVED FIRST. Every amenity ticked and every place added on this step
      // lives only in the controller until Continue posts it; refusing before
      // the save would throw that work away to enforce a rule about something
      // else entirely.
      expect(service.step3Calls, 1,
          reason: 'the amenities and places on this step were never saved, so '
              "holding the host here loses their work");
      expect(c.heldHere.value, contains('Before publishing,'));

      // Told once, not walled in: pricing and house rules are still theirs to
      // fill in while the camera is at the property, and the server refuses at
      // publish either way.
      final second = await c.saveAndContinue();
      expect(second, isTrue);
      expect(c.step.value, 3);
      expect(c.heldHere.value, isEmpty);
    });

    test('a complete set is never held', () async {
      final service = _StubService();
      final c = wizard(
        media: photos(10, ['exterior', 'bedroom', 'bathroom', 'entrance']),
        service: service,
      );
      c.step.value = 2;
      expect(await c.saveAndContinue(), isTrue);
      expect(c.step.value, 3);
    });
  });
}

/// The wizard's service with the network taken out of it.
class _StubService extends ListingService {
  int step3Calls = 0;

  @override
  Future<Map<String, dynamic>> saveStep3(Map<String, dynamic> payload) async {
    step3Calls += 1;
    return {};
  }
}
